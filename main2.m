% brainlife.io App for Brainstorm MEEG data analysis

disp('0) My script has started');

%% Key paths
% Directory to store brainstorm database
BrainstormDbDir = [pwd, '/brainstorm_db/']; % Full path
ReportsDir = pwd;

%% Parameters
% % Path to the data
% sFilesMEG = '/Users/guiomar/Downloads/meg.fif';

% Load Brainlife configuration file: config.json
config_data = jsondecode(fileread('config.json'));
sFilesMEG = fullfile(config_data.fif);

ProtocolName = 'Protocol02'; % Needs to be a valid folder name (no spaces, no weird characters, etc)
SubjectName = 'Subject01';

% NOTCH FILTER
% Frequencies to filter with the noth (e.g. power line 60Hz and harmonics)
freqs_notch = 60:60:60;

% LOW AND HIGH PASS FILTER
highpass = 0.3;
lowpass = 0; % 0: no filter

% PSD
% Window length and overlap for PSD Welch method
win_length = 4; % seconds
win_overlap = 0; % percentage


%% START BRAINSTORM
disp('== Start Brainstorm defaults');

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
disp('== Create protocol');

% Create new protocol
UseDefaultAnat = 1; 
UseDefaultChannel = 0;
gui_brainstorm('CreateProtocol', ProtocolName, UseDefaultAnat, UseDefaultChannel);

disp('- New protocol created');

%% ==== 1) Import MEG files =======================================
disp('== 1) Import MEG file');

sFiles0 = [];
% Start a new report
bst_report('Start');

% Process: Create link to raw file    
sFiles = bst_process('CallProcess', 'process_import_data_raw', ...
    sFiles0, [], ...
    'subjectname', SubjectName, ...
    'datafile', {sFilesMEG, 'FIF'}, ...
    'channelreplace', 1, ...
    'channelalign', 1);


%% ==== 2) PSD on sensors (before filtering) ======================

disp('== 2) PSD on sensors');

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


%% ==== 3)  Notch filter =====================

disp('== 3) Notch');

% Process: Notch filter: 
sFilesNotch = bst_process('CallProcess', 'process_notch', ...
    sFiles, [], ...
    'freqlist', freqs_notch, ...
    'sensortypes', 'MEG, EEG', ...
    'read_all', 0); 

%% ==== 4)  High pass filter =====================

disp('== 4) Highpass');

% Process: High-pass:
sFiles = bst_process('CallProcess', 'process_bandpass', ...
    sFiles, [], ...
    'highpass', highpass, ...
    'lowpass', lowpass, ...
    'mirror', 1, ...
    'sensortypes', 'MEG, EEG', ...
    'read_all', 0);

%% Save Report and delete protocol

% Save report
disp('== Save report');
ReportFile = bst_report('Save', []);
bst_report('Export', ReportFile, ReportsDir);

% Delete existing protocol
gui_brainstorm('DeleteProtocol', ProtocolName);
disp('== Delete protocol');


%% DONE
disp('** Done!');
