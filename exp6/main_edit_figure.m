function fig = main_edit_figure(filename)
% Open a saved FIG with figure-selection mode enabled.
% Run main_edit_figure to select a file, or main_edit_figure(fullFileName).
if nargin<1 || isempty(filename)
    base=fileparts(mfilename('fullpath'));
    start=fullfile(base,'results');
    if ~isfolder(start),start=base;end
    [name,folder]=uigetfile({'*.fig','MATLAB figure (*.fig)'}, ...
        'Select a figure to edit',fullfile(start,'*.fig'));
    if isequal(name,0),fig=gobjects(0);return;end
    filename=fullfile(folder,name);
end
assert(isfile(filename),'FIG file not found: %s.',filename);
fig=openfig(filename,'new','visible');
set(fig,'MenuBar','figure','ToolBar','figure','WindowStyle','normal');
plotedit(fig,'on');
drawnow;
% Select a curve/text label, then edit its properties in MATLAB.
% Save edits explicitly with savefig(fig,filename).
end
