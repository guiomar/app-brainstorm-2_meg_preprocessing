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

clc; close all; clear;

disp(['0) My script has started']);

%% Load config.json

% Load inputs from config.json
config = jsondecode(fileread('config.json'));

%% Some paths

<<<<<<< Updated upstream
% Directory with the segmented anatomy (e.g. freesufer output)
%AnatDir1 = [fullfile(config.output)];
%disp(AnatDir1)
%AnatDir = [fullfile(config.freesurfer)];
%disp(AnatDir)

=======
>>>>>>> Stashed changes
% Directory to store results
ReportsDir = 'out_dir/';
DataDir    = 'out_data/';

% Directory to store brainstorm database
BrainstormDbDir = [pwd, '/brainstorm_db/']; % Full path

%% Parameters
ProtocolName = 'Protocol01'; % The protocol name has to be a valid folder name (no spaces, no weird characters...)
SubjectName = 'Subject01';

%% START BRAINSTORM
disp(['1) Brainstorm should be started on server mode']);

% Set Brainstorm database directory
bst_set('BrainstormDbDir',BrainstormDbDir) 

% See Tutorial 1
disp(['BrainstormDbDir:', bst_get('BrainstormDbDir')]);
disp(['BrainstormUserDir:', bst_get('BrainstormUserDir')]); % HOME/.brainstom (operating system)
disp(['HOME env:', getenv('HOME')]);
disp(['HOME java:', char(java.lang.System.getProperty('user.home'))]);
            

%% CREATE PROTOCOL 
disp(['2) Create protocol']);

% Find existing protocol
iProtocol = bst_get('Protocol', ProtocolName);
disp(['iProtocol: ',num2str(iProtocol)]);

if ~isempty(iProtocol)
    % Delete existing protocol
    disp(['- Delete protocol']);
    gui_brainstorm('DeleteProtocol', ProtocolName);
    % Select the current procotol
    % gui_brainstorm('SetCurrentProtocol', iProtocol);
end

% Create new protocol
disp(['- Create new protocol']);
UseDefaultAnat = 1; 
UseDefaultChannel = 0;
gui_brainstorm('CreateProtocol', ProtocolName, UseDefaultAnat, UseDefaultChannel);
% Reset colormaps
bst_colormaps('RestoreDefaults', 'meg');

disp(['Protocol created!']);

%% Parameters

% Frequencies to filter with the noth (power line 60Hz and harmonics)
freqs_notch = [60:60:600];

% Filters
highpass = 0.3;
lowpass = 0; % 0: no filter

% Window length and overlap for PSD Welch method
win_length = 10; % sec 2
win_overlap = 0; % percentage 50

<<<<<<< Updated upstream
sFilesMEG = fullfile(config.fif);
% =========================================================================
=======
>>>>>>> Stashed changes

%% ==== 1) Import MEG files =======================================
disp(['1) Import MEG file']);

sFiles0 = [];
% Start a new report
bst_report('Start');


% ** CTF **
%
% Path to the data
% sFilesMEG = fullfile(config.ctf);
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

% Path to the data
sFilesMEG = fullfile(config.fif);

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

% % % % disp(['1) PSD on sensors']);
% % % % 
% % % % % Process: Power spectrum density (Welch)
% % % % sFilesPSDpre = bst_process('CallProcess', 'process_psd', ...
% % % %     sFiles, [], ...
% % % %     'timewindow', [], ...
% % % %     'win_length', win_length, ...
% % % %     'win_overlap', win_overlap, ...
% % % %     'sensortypes', 'MEG, EEG', ...
% % % %     'edit', struct(...
% % % %          'Comment', 'Power', ...
% % % %          'TimeBands', [], ...
% % % %          'Freqs', [], ...
% % % %          'ClusterFuncTime', 'none', ...
% % % %          'Measure', 'power', ...
% % % %          'Output', 'all', ...
% % % %          'SaveKernel', 0));
% % % % 
% % % % disp(['1) Create snapshot PSD on sensors']);
% % % % 
% % % % % ** Process: Snapshot: Frequency spectrum
% % % % bst_process('CallProcess', 'process_snapshot', ...
% % % %     sFilesPSDpre, [], ...
% % % %     'target', 10, ...  % Frequency spectrum
% % % %     'modality', 1, ...  % MEG (All)
% % % %     'orient', 1, ...  % left
% % % %     'time', 0, ...
% % % %     'contact_time', [0, 0.1], ...
% % % %     'contact_nimage', 12, ...
% % % %     'threshold', 30, ...
% % % %     'comment', '');
% % % % 
% % % % 
% % % % %% ==== 3)  Notch filter + High pass (0.3 Hz) =====================
% % % % 
% % % % % % Process: Notch filter: 
% % % % % sFilesNotch = bst_process('CallProcess', 'process_notch', ...
% % % % %     sFiles, [], ...
% % % % %     'freqlist', freqs_notch, ...
% % % % %     'sensortypes', 'MEG, EEG', ...
% % % % %     'read_all', 0); 
% % % % % 
% % % % % % Process: High-pass:
% % % % % sFiles = bst_process('CallProcess', 'process_bandpass', ...
% % % % %     sFilesNotch, [], ...
% % % % %     'highpass', highpass, ...
% % % % %     'lowpass', lowpass, ...
% % % % %     'mirror', 1, ...
% % % % %     'sensortypes', 'MEG, EEG', ...
% % % % %     'read_all', 0);
% % % % % 
% % % % % % Delete intermediate files (Notch) 
% % % % % for iRun=1:numel(sFilesNotch)
% % % % %     % Process: Delete data files
% % % % %     bst_process('CallProcess', 'process_delete', ...
% % % % %         sFilesNotch(iRun).FileName, [], ...
% % % % %         'target', 2);  % Delete conditions
% % % % % end
% % % % 
% % % % 
% % % % disp(['1) PSD post']);
% % % % 
% % % % % Process: Power spectrum density (Welch)
% % % % sFilesPSDpost = bst_process('CallProcess', 'process_psd', ...
% % % %     sFiles, [], ...
% % % %     'timewindow', [], ...
% % % %     'win_length', win_length, ...
% % % %     'win_overlap', win_overlap, ...
% % % %     'sensortypes', 'MEG, EEG', ...
% % % %     'edit', struct(...
% % % %          'Comment', 'Power', ...
% % % %          'TimeBands', [], ...
% % % %          'Freqs', [], ...
% % % %          'ClusterFuncTime', 'none', ...
% % % %          'Measure', 'power', ...
% % % %          'Output', 'all', ...
% % % %          'SaveKernel', 0));
% % % % 
% % % % disp(['1) Create snapshot PSD post']);
% % % % 
% % % % % ** Process: Snapshot: Frequency spectrum
% % % % bst_process('CallProcess', 'process_snapshot', ...
% % % %     sFilesPSDpost, [], ...
% % % %     'target', 10, ...  % Frequency spectrum
% % % %     'modality', 1, ...  % MEG (All)
% % % %     'orient', 1, ...  % left
% % % %     'time', 0, ...
% % % %     'contact_time', [0, 0.1], ...
% % % %     'contact_nimage', 12, ...
% % % %     'threshold', 30, ...
% % % %     'comment', '');


%% SAVE RESULTS

% Save report
disp(['4) Save report']);
ReportFile = bst_report('Save', []);
if isempty(ReportFile)
    disp('Empty report file');
end
bst_report('Export', ReportFile, ReportsDir);

% Save data
disp(['5) Save data']);
disp(['db dir: ',BrainstormDbDir]);

movefile([BrainstormDbDir,'/',ProtocolName], DataDir);

%% DONE
disp(['** Done!']);
