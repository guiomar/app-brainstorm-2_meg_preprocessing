% brainlife.io App for Brainstorm MEEG data analysis
%
% Author: Guiomar Niso
%
% Copyright (c) 2020 brainlife.io 
%
% Indiana University

%% Add submodules
% Submodules: libraries necessary to run the code
% Added to this App GitHub repository and automatically downloaded with the App 
% Need to add them MatLab path:
clc; clear; 

pathBst = '/Users/guiomar/Documents/SOFTWARE/brainstorm3';
%pathBst = '/media/data/guiomar/app-brainstorm-1_import_anatomy/brainstorm3';

 if ~isdeployed
     addpath(genpath(pathBst));
 end

%% Load config.json
% Load inputs from config.json
% Inputs are stored in config.input1, config.input2, etc
% config = loadjson('config.json','ParseStringArray',1); % requires submodule to read JSON files in MatLab
%fid = fopen('config.json')
%config_json = char(fread(fid)')
%fclose(fid)
config = jsondecode(fileread('config.json'));

%% Some paths

BrainstormDbDir = '/Users/guiomar/Projects/brainstorm_db';
% BrainstormDbDir = '/media/data/guiomar/brainstorm_db';
% BrainstormDbDir = 'brainstorm_db';

AnatDir = fullfile(config.output);
% AnatDir = '/media/data/guiomar/data/anat/';
ReportsDir = 'out_dir/';
DataDir = 'out_data/';

%% Parameters
ProtocolName = 'Protocol01'; % The protocol name has to be a valid folder name (no spaces, no weird characters...)
SubjectName = 'Subject01';

%% START BRAINSTORM
% Start Brainstorm
if ~brainstorm('status')
    brainstorm server
end
% Set Brainstorm database directory
bst_set('BrainstormDbDir',BrainstormDbDir)
% Set Brainstorm database directory interactively
% BrainstormDbDir = gui_brainstorm('SetDatabaseFolder');
% Get Brainstorm database directory
% BrainstormDbDir = bst_get('BrainstormDbDir');

%% CREATE PROTOCOL 
disp(['1) Create protocol']);

% sProtocol.Comment = ProtocolName;
% sProtocol.SUBJECTS = [home 'anat'];
% sProtocol.STUDIES = [home 'data'];
% db_edit_protocol('load',sProtocol);

% Find existing protocol
iProtocol = bst_get('Protocol', ProtocolName);

% SELECT CURRENT PROTOCOL
% if isempty(iProtocol)
%     error(['Unknown protocol: ' ProtocolName]);
% end
% % Select the current procotol
% gui_brainstorm('SetCurrentProtocol', iProtocol);

% CREATE NEW PROTOCOL
if ~isempty(iProtocol)
    % Delete existing protocol
    gui_brainstorm('DeleteProtocol', ProtocolName);
end
% Create new protocol
gui_brainstorm('CreateProtocol', ProtocolName, 0, 0);


%% Start report
% Start a new report
bst_report('Start');
% Reset colormaps
bst_colormaps('RestoreDefaults', 'meg');

%%
% 1) Import MEG + Convert to continuous (CTF) + Refine registration
% 2) PSD on sensosrs (pre)
% 3) Notch filter (60Hz and harmonics) + High bandpass (0.3 Hz)
%
% Guiomar Niso, 26 May 2016 (v1)
% Guiomar Niso, 6 May 2015 (v0)

% -------------------------------------------------------------------------

% Frequencies to filter with the noth (power line 60Hz and harmonics)
% freqs_notch = [60, 120, 180, 240, 300, 360, 420, 480, 540, 600];
freqs_notch = [60];

% Filters
highpass = 0.3;
lowpass = 0; % 0: no filter

% Window length and overlap for PSD Welch method
win_length = 10; % sec 2
win_overlap = 0; % percentage 50

sFilesMEG = fullfile(config.ctf);
% =========================================================================

%% ==== 1) Import MEG files =======================================
disp(['1) Import MEG file']);

sFiles0 = [];

% Process: Create link to raw file    
sFiles = bst_process('CallProcess', 'process_import_data_raw', ...
    sFiles0, [], ...
    'subjectname', SubjectName, ...
    'datafile', {sFilesMEG, 'CTF'}, ...
    'channelreplace', 1, ...
    'channelalign', 1);

%%%% CONFIG
% Process: Convert to continuous (CTF): Continuous
bst_process('CallProcess', 'process_ctf_convert', ...
    sFiles, [], ...
    'rectype', 2);  % Continuous

% % %%%% IS THIS DONE AUTOMATICALLY NOW??
% % % Process: Refine registration
% % bst_process('CallProcess', 'process_headpoints_refine', ...
% %     sFiles, []);
disp(['1) Create snapshot MEG data']);

% ** Process: Snapshot: Sensors/MRI registration
hFig = bst_process('CallProcess', 'process_snapshot', ...
    sFiles, [], ...
    'target', 1, ...  % Sensors/MRI registration
    'modality', 1, ...% MEG (All)
    'orient', 1, ...  % left
    'time', 0, ...
    'contact_time', [0, 0.1], ...
    'contact_nimage', 12, ...
    'threshold', 30, ...
    'comment', '');
saveas(hFig, 'test.jpg')

%% ==== 2) PSD on sensors (before filtering) ======================

disp(['1) PSD on sensors']);

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

disp(['1) Create snapshot PSD on sensors']);

% ** Process: Snapshot: Frequency spectrum
bst_process('CallProcess', 'process_snapshot', ...
    sFilesPSDpre, [], ...
    'target', 10, ...  % Frequency spectrum
    'modality', 1, ...  % MEG (All)
    'orient', 1, ...  % left
    'time', 0, ...
    'contact_time', [0, 0.1], ...
    'contact_nimage', 12, ...
    'threshold', 30, ...
    'comment', '');


%% ==== 3)  Notch filter + High pass (0.3 Hz) =====================

% % Process: Notch filter: 
% sFilesNotch = bst_process('CallProcess', 'process_notch', ...
%     sFiles, [], ...
%     'freqlist', freqs_notch, ...
%     'sensortypes', 'MEG, EEG', ...
%     'read_all', 0); 
% 
% % Process: High-pass:
% sFiles = bst_process('CallProcess', 'process_bandpass', ...
%     sFilesNotch, [], ...
%     'highpass', highpass, ...
%     'lowpass', lowpass, ...
%     'mirror', 1, ...
%     'sensortypes', 'MEG, EEG', ...
%     'read_all', 0);
% 
% % Delete intermediate files (Notch) 
% for iRun=1:numel(sFilesNotch)
%     % Process: Delete data files
%     bst_process('CallProcess', 'process_delete', ...
%         sFilesNotch(iRun).FileName, [], ...
%         'target', 2);  % Delete conditions
% end


disp(['1) PSD post']);

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

disp(['1) Create snapshot PSD post']);

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

%% SAVE REPORT
% Save and display report
disp(['1) Create report']);

ReportFile = bst_report('Save', []);
if ~isempty(ReportsDir) && ~isempty(ReportFile)
    bst_report('Export', ReportFile, ReportsDir);
else
    bst_report('Open', ReportFile);
end

%% SAVE DATA
copyfile([BrainstormDbDir,'/',ProtocolName], DataDir);

%% DONE
disp(['> Done!']);
