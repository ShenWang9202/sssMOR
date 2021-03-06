function [folderSub,folder,logo,web,year] = dataForDoc()
% This function provides additional data that is necessary to generate the
% documentation


%% Directories that should not be included in the documentation

proj_dir = fileparts(fileparts(mfilename('fullpath')));

% directories that are completely ignored, including all subfolders
folderSub = {...
    [proj_dir filesep 'doc'] ,...
    [proj_dir filesep 'test'] ,...
    [proj_dir filesep 'app'],...
    [proj_dir filesep 'src' filesep 'LyapunovEq'],...
    };

% direcotires that are ignored, but the subfolders are considered
folder = {};


%% Logo

logo = sprintf('%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s',...
    '%   <td style="background-color:#ffffff; border:0; width:25%; vertical-align:middle; text-align:center">',...
    '%             <img src="img/logo_sssMOR_long.png" alt="sssMOR_Logo" height="40px">',...
    '%      </td>', ...
    '%   <td style="background-color:#ffffff; border:0; width:25%; vertical-align:middle; text-align:center">',...
    '%      <img src="img/MORLAB_Logo.jpg" alt="MORLAB_Logo" height="40px"></td>', ...
    '%   <td style="background-color:#ffffff; border:0; width:25%; vertical-align:middle; text-align:center">',...
    '%      <img src="img/Logo_Textzusatz_rechts_engl_Chair.png" alt="RT_Logo" height="40px"></td>', ...
    '%   <td style="background-color:#ffffff; border:0; width:25%; vertical-align:middle; text-align:center">',...
    '%      <img src="img/TUM-logo.png" alt="TUM_Logo" height="40px"></td>');

%% Web

web = sprintf('%s',...
	'%        <a href="https://www.rt.mw.tum.de/?sssMOR">Website</a>');

%% Year of the first release

year = 2015;