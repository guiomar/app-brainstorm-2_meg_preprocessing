% brainlife.io App for Brainstorm MEEG data analysis
%
% Author: Guiomar Niso
%
% Copyright (c) 2020 brainlife.io 
%
% Indiana University

%% Load config.json
% Load inputs from config.json
config = jsondecode(fileread('config.json'));

%% Some paths

% Directory with the segmented anatomy (e.g. freesufer output)
AnatDir = [fullfile(config.output)];

% Directory to store results
ReportsDir = 'out_dir/';
DataDir    = 'out_data/';

% Directory to store brainstorm database
% BrainstormDbDir = '/media/data/guiomar/brainstorm_db';
% BrainstormDbDir = 'brainstorm_db/';

%% Parameters
ProtocolName = 'Protocol02'; % The protocol name has to be a valid folder name (no spaces, no weird characters...)
SubjectName = 'Subject01';

%% START BRAINSTORM
disp(['1) Start Brainstorm on server mode']);

% Start Brainstorm
% if ~brainstorm('status')
%     brainstorm server local
% end

% Set Brainstorm database directory
% bst_set('BrainstormDbDir',BrainstormDbDir)
% BrainstormDbDir = gui_brainstorm('SetDatabaseFolder'); % interactive
BrainstormDbDir = bst_get('BrainstormDbDir');

%% CREATE PROTOCOL 
disp(['2) Create protocol']);

% sProtocol.Comment = ProtocolName;
% sProtocol.SUBJECTS = [home 'anat'];
% sProtocol.STUDIES = [home 'data'];
% db_edit_protocol('load',sProtocol);

% Find existing protocol
iProtocol = bst_get('Protocol', ProtocolName);
disp(['iProtocol: ',num2str(iProtocol)]);

if ~isempty(iProtocol)
    % Delete existing protocol
    disp(['Delete protocol']);
    gui_brainstorm('DeleteProtocol', ProtocolName);
    % Select the current procotol
    % gui_brainstorm('SetCurrentProtocol', iProtocol);
end

% Create new protocol
disp(['Create new protocol']);
gui_brainstorm('CreateProtocol', ProtocolName, 0, 0);


% Start a new report
bst_report('Start');
% Reset colormaps
bst_colormaps('RestoreDefaults', 'meg');


%% IMPORT ANATOMY
disp(['3) Import anatomy']);
disp(['Dir: ', AnatDir]);

% Process: Import FreeSurfer folder
bst_process('CallProcess', 'process_import_anatomy', [], [], ...
    'subjectname', SubjectName, ...
    'mrifile',     {AnatDir, 'FreeSurfer'}, ...
    'nvertices',   15000, ...
    'nas', [0, 0, 0], ...
    'lpa', [0, 0, 0], ...
    'rpa', [0, 0, 0], ...
    'ac',  [0, 0, 0], ...
    'pc',  [0, 0, 0], ...
    'ih',  [0, 0, 0]);
% This automatically calls the SPM registration procedure because the AC/PC/IH points are not defined

% //// FUTURE: load fiducial points from file if available: nas, lpa, rpa

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
