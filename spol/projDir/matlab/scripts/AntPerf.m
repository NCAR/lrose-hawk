function varargout = AntPerf(varargin)
%ANTPERF M-file for AntPerf.fig
%      ANTPERF, by itself, creates a new ANTPERF or raises the existing
%      singleton*.
%
%      H = ANTPERF returns the handle to a new ANTPERF or the handle to
%      the existing singleton*.
%
%      ANTPERF('Property','Value',...) creates a new ANTPERF using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to AntPerf_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      ANTPERF('CALLBACK') and ANTPERF('CALLBACK',hObject,...) call the
%      local function named CALLBACK in ANTPERF.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AntPerf

% Last Modified by GUIDE v2.5 12-Jul-2011 10:12:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AntPerf_OpeningFcn, ...
                   'gui_OutputFcn',  @AntPerf_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before AntPerf is made visible.
function AntPerf_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

handles.init_dir =  '/data/operator/data.dmgt/cfradial/covar/sband';
% handles.init_dir =  './cfradial/moments/sband';

handles.dispo = 'no';
set(handles.DirecSelect, 'String', handles.init_dir );

% Choose default command line output for AntPerf
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes AntPerf wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = AntPerf_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function DirecSelect_Callback(hObject, eventdata, handles)
% hObject    handle to DirecSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DirecSelect as text
%        str2double(get(hObject,'String')) returns contents of DirecSelect as a double

handles.direc = cellstr(get(handles.DirecSelect, 'String'));
guidata(hObject, handles);  % always, always update guidata when changing handle values!!


% --- Executes during object creation, after setting all properties.
function DirecSelect_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DirecSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ResetPlots.
function ResetPlots_Callback(hObject, eventdata, handles)
% hObject    handle to ResetPlots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.DirecSelect, 'String', handles.init_dir );

% there should be a better way to do this:
handles.dispo = 'no';
set(handles.ImageSaveNo, 'Value', 1);
set(handles.ImageSaveYes, 'Value', 0);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in StartPlots.
function StartPlots_Callback(hObject, eventdata, handles)
% hObject    handle to StartPlots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.direc = cellstr(get(handles.DirecSelect, 'String'));
stat = start_antenna_plots(char(handles.direc), char(handles.dispo));
guidata(hObject, handles);  % always, always update guidata when changing handle values!!

% --- Executes when selected object is changed in ImageSave.
function ImageSave_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in ImageSave 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
% who

switch get(eventdata.NewValue, 'Tag')
    case 'ImageSaveNo'
        handles.dispo = 'no'
    case 'ImageSaveYes'
        handles.dispo = 'save';
        handles.dispo
    otherwise
        fprintf('Blew it!\nNo match for ImageSave\n');
end;

guidata(hObject, handles);  % always, always update guidata when changing handle values!!
