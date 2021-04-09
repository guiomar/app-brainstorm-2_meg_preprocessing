% brainlife.io App for Brainstorm MEEG data analysis
%
% 1) Import MEG + Convert to continuous (CTF) + Refine registration
% 2) PSD on sensosrs (pre)
% 3) Notch filter (60Hz and harmonics) + High bandpass (0.3 Hz)
%
% Author: Guiomar Niso
%
% Copyright (c) 2020 brainlife.io 
%
% Indiana University

disp(['0) My script has started']);

%% Key paths
% Directory to store results
ReportsDir = 'out_dir/';
DataDir    = 'out_data/';
% Directory to store brainstorm database
BrainstormDbDir = [pwd, '/brainstorm_db/']; % Full path

%% Parameters
% Load Brainlife configuration file: config.json
config = jsondecode(fileread('config.json'));

% Path to the data
sFilesMEG = fullfile(config.fif);

ProtocolName = 'Protocol01'; % Needs to be a valid folder name (no spaces, no weird characters, etc)
SubjectName = 'Subject01';

% NOTCH FILTER
% Frequencies to filter with the noth (e.g. power line 60Hz and harmonics)
freqs_notch = [60:60:60];

% LOW AND HIGH PASS FILTER
highpass = 0.3;
lowpass = 0; % 0: no filter

% PSD
% Window length and overlap for PSD Welch method
win_length = 10; % sec 2
win_overlap = 0; % percentage 50


%% START BRAINSTORM
disp(['0) Brainstorm started on server mode']);

% Delete brainstorm.mat
% delete([bst_get('BrainstormUserDir'),'/brainstorm.mat']);

% Set Brainstorm database directory
bst_set('BrainstormDbDir',BrainstormDbDir) 
% Reset colormaps
bst_colormaps('RestoreDefaults', 'meg');

%%%%%%%%
% See Tutorial 1
disp(['- BrainstormDbDir:', bst_get('BrainstormDbDir')]);
disp(['- BrainstormUserDir:', bst_get('BrainstormUserDir')]); % HOME/.brainstom (operating system)
disp(['- HOME env:', getenv('HOME')]);
disp(['- HOME java:', char(java.lang.System.getProperty('user.home'))]);
%%%%%%%%


%% CREATE PROTOCOL 
disp(['0) Create protocol']);

% Find existing protocol
iProtocol = bst_get('Protocol', ProtocolName);
%disp(['iProtocol: ',num2str(iProtocol)]);

if ~isempty(iProtocol)
    % Delete existing protocol
    disp(['- Delete protocol']);
    gui_brainstorm('DeleteProtocol', ProtocolName);
end

% Create new protocol
disp(['- Create new protocol']);
UseDefaultAnat = 1; 
UseDefaultChannel = 0;
gui_brainstorm('CreateProtocol', ProtocolName, UseDefaultAnat, UseDefaultChannel);


%% ==== 1) Import MEG files =======================================
disp(['1) Import MEG file']);

sFiles0 = [];
% Start a new report
bst_report('Start');


% ** CTF **
%
% % % Process: Create link to raw file    
% % sFiles = bst_process('CallProcess', 'process_import_data_raw', ...
% %     sFiles0, [], ...
% %     'subjectname', SubjectName, ...
% %     'datafile', {sFilesMEG, 'CTF'}, ...
% %     'channelreplace', 1, ...
% %     'channelalign', 1);
% % 
% % %%%% CONFIG
% % % Process: Convert to continuous (CTF): Continuous
% % bst_process('CallProcess', 'process_ctf_convert', ...
% %     sFiles, [], ...
% %     'rectype', 2);  % Continuous
% % 

% ** FIF **

% Process: Create link to raw file    
sFiles = bst_process('CallProcess', 'process_import_data_raw', ...
    sFiles0, [], ...
    'subjectname', SubjectName, ...
    'datafile', {sFilesMEG, 'FIF'}, ...
    'channelreplace', 1, ...
    'channelalign', 1);

% % %%%% IS THIS DONE AUTOMATICALLY NOW??
% % % Process: Refine registration
% % bst_process('CallProcess', 'process_headpoints_refine', ...
% %     sFiles, []);

disp(['1) Create snapshot MEG data']);

disp(['sFiles: ', sFiles.FileName])
% ** Process: Snapshot: Sensors/MRI registration
bst_process('CallProcess', 'process_snapshot', ...
    sFiles, [], ...
    'target', 1, ...  % Sensors/MRI registration
    'modality', 1, ...% MEG (All)
    'orient', 1, ...  % left
    'time', 0, ...
    'contact_time', [0, 0.1], ...
    'contact_nimage', 12, ...
    'threshold', 30, ...
    'comment', '');


%% ==== 2) PSD on sensors (before filtering) ======================

disp(['2) PSD on sensors']);

disp(['sFiles: ', sFiles.FileName])
a=importdata([BrainstormDbDir,sFiles.FileName]);
disp(a.F.filename)

% Process: Power spectrum density (Welch)
sFilesPSDpre = bst_process('CallProcess', 'process_psd', ...
    sFiles, [], ...
    'timewindow', [], ...
    'win_length', win_length, ...
    'win_overlap', win_overlap, ...
    'sensortypes', 'MEG, EEG', ...
    'edit', struct(...
         'Comment', 'Power', ...
         'TimeBands', [], ...
         'Freqs', [], ...
         'ClusterFuncTime', 'none', ...
         'Measure', 'power', ...
         'Output', 'all', ...
         'SaveKernel', 0));

disp(['2) Create snapshot PSD on sensors']);

% % ** Process: Snapshot: Frequency spectrum
% bst_process('CallProcess', 'process_snapshot', ...
%     sFilesPSDpre, [], ...
%     'target', 10, ...  % Frequency spectrum
%     'modality', 1, ...  % MEG (All)
%     'orient', 1, ...  % left
%     'time', 0, ...
%     'contact_time', [0, 0.1], ...
%     'contact_nimage', 12, ...
%     'threshold', 30, ...
%     'comment', '');


%% ==== 3)  Notch filter + High pass (0.3 Hz) =====================

disp(['3) Filtering']);

disp(['sFiles: ', sFiles.FileName])
b=importdata([BrainstormDbDir,sFiles.FileName]);
disp(b.F.filename)
% Process: Notch filter: 
sFilesNotch = bst_process('CallProcess', 'process_notch', ...
    sFiles, [], ...
    'freqlist', freqs_notch, ...
    'sensortypes', 'MEG, EEG', ...
    'read_all', 0); 

% Process: High-pass:
sFiles = bst_process('CallProcess', 'process_bandpass', ...
    sFilesNotch, [], ...
    'highpass', highpass, ...
    'lowpass', lowpass, ...
    'mirror', 1, ...
    'sensortypes', 'MEG, EEG', ...
    'read_all', 0);

% Delete intermediate files (Notch) 
for iRun=1:numel(sFilesNotch)
    % Process: Delete data files
    bst_process('CallProcess', 'process_delete', ...
        sFilesNotch(iRun).FileName, [], ...
        'target', 2);  % Delete conditions
end


%% ==== 4) PSD on sensors (before filtering) ======================
disp(['4) PSD post']);

% Process: Power spectrum density (Welch)
sFilesPSDpost = bst_process('CallProcess', 'process_psd', ...
    sFiles, [], ...
    'timewindow', [], ...
    'win_length', win_length, ...
    'win_overlap', win_overlap, ...
    'sensortypes', 'MEG, EEG', ...
    'edit', struct(...
         'Comment', 'Power', ...
         'TimeBands', [], ...
         'Freqs', [], ...
         'ClusterFuncTime', 'none', ...
         'Measure', 'power', ...
         'Output', 'all', ...
         'SaveKernel', 0));

disp(['4) Create snapshot PSD post']);

% ** Process: Snapshot: Frequency spectrum
bst_process('CallProcess', 'process_snapshot', ...
    sFilesPSDpost, [], ...
    'target', 10, ...  % Frequency spectrum
    'modality', 1, ...  % MEG (All)
    'orient', 1, ...  % left
    'time', 0, ...
    'contact_time', [0, 0.1], ...
    'contact_nimage', 12, ...
    'threshold', 30, ...
    'comment', '');


%% SAVE RESULTS

% Save report
disp(['5) Save report']);
ReportFile = bst_report('Save', []);
if isempty(ReportFile)
    disp('Empty report file');
end
bst_report('Export', ReportFile, ReportsDir);

% Save data
disp(['6) Save data']);


%% Delete current protocol
% Move brainstorm_db data
copyfile([BrainstormDbDir,'/',ProtocolName], DataDir);
% Delete bst protocol (in .brainstorm/brainstorm.mat file)
% Delete existing protocol
disp(['- Delete protocol']);
gui_brainstorm('DeleteProtocol', ProtocolName);


%% DONE
disp(['** Done!']);
