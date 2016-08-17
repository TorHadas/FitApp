function varargout = PasteDataDialog(varargin)
    % PASTEDATADIALOG MATLAB code for PasteDataDialog.fig
    %      PASTEDATADIALOG by itself, creates a new PASTEDATADIALOG or raises the
    %      existing singleton*.
    %
    %      H = PASTEDATADIALOG returns the handle to a new PASTEDATADIALOG or the handle to
    %      the existing singleton*.
    %
    %      PASTEDATADIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in PASTEDATADIALOG.M with the given input arguments.
    %
    %      PASTEDATADIALOG('Property','Value',...) creates a new PASTEDATADIALOG or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before PasteDataDialog_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to PasteDataDialog_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help PasteDataDialog

    % Last Modified by GUIDE v2.5 20-Apr-2016 15:59:31

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @PasteDataDialog_OpeningFcn, ...
                       'gui_OutputFcn',  @PasteDataDialog_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
end
% End initialization code - DO NOT EDIT

% --- Executes just before PasteDataDialog is made visible.
function PasteDataDialog_OpeningFcn(hObject, eventdata, handles, varargin)
    % Choose default command line output for PasteDataDialog
    handles.output = true;
    handles.Data.PastedData = [];
    handles.Data.PastedHeaders = {};
    handles.Data.SelectedData = [];
    handles.Ok = true;
    handles.error = 'Please insert viable data from excel or google sheets';
    guidata(hObject, handles);
    dataText = clipboard('paste');
    try
        [data, status] = str2num(dataText);
        columnNames = {};
        if (~status)
            % Maybe the first line is headers?
            dataLines = textscan(dataText, '%s', 'Delimiter', '\n');
            dataLines = dataLines{1};

            if (numel(dataLines) > 1)
                headerLine = dataLines{1};

                if (~isempty(headerLine))
                    columnNames = textscan(headerLine, '%s', 'Delimiter', ' \t');
                    columnNames = strrep(columnNames{1}, char(26), 'd'); % Replace the delta symbol
                end

                for i = 2:numel(dataLines)
                    dataLineNumbers = str2num(dataLines{i});
                    data(end+1, :) = dataLineNumbers;
                end

                status = 1;
            end
        end

        if (status)
            set(handles.dataTable, 'Data', data);

            columnNumbers = [1:size(data, 2)]';
            columnNumberStrings = cellstr(num2str(columnNumbers));

            if (numel(columnNames) < numel(columnNumberStrings))
                columnNames(numel(columnNames)+1:numel(columnNumberStrings)) = columnNumberStrings(numel(columnNames)+1:numel(columnNumberStrings));
            else
                set(handles.dataTable, 'ColumnName', columnNames);
            end

            set(handles.xColPopup, 'String', columnNames);
            set(handles.yColPopup, 'String', columnNames);
            set(handles.dxColPopup, 'String', columnNames);
            set(handles.dyColPopup, 'String', columnNames);

            set(handles.xColPopup, 'Value', min(1, numel(columnNames)));
            set(handles.dxColPopup, 'Value', min(2, numel(columnNames)));
            set(handles.yColPopup, 'Value', min(3, numel(columnNames)));
            set(handles.dyColPopup, 'Value', min(4, numel(columnNames)));
        end

        if (isempty(data))
            handles.Ok = false;
            handles.error = 'Nothing was copied, or copied text';
            guidata(hObject, handles);
            return;
        end
        guidata(hObject, handles);
    catch
        handles.Ok = false;
        guidata(hObject, handles);
        return;
    end


    % Determine the position of the dialog - centered on the callback figure
    % if available, else, centered on the screen
    FigPos=get(0,'DefaultFigurePosition');
    OldUnits = get(hObject, 'Units');
    set(hObject, 'Units', 'pixels');
    OldPos = get(hObject,'Position');
    FigWidth = OldPos(3);
    FigHeight = OldPos(4);
    if isempty(gcbf)
        ScreenUnits=get(0,'Units');
        set(0,'Units','pixels');
        ScreenSize=get(0,'ScreenSize');
        set(0,'Units',ScreenUnits);

        FigPos(1)=1/2*(ScreenSize(3)-FigWidth);
        FigPos(2)=2/3*(ScreenSize(4)-FigHeight);
    else
        GCBFOldUnits = get(gcbf,'Units');
        set(gcbf,'Units','pixels');
        GCBFPos = get(gcbf,'Position');
        set(gcbf,'Units',GCBFOldUnits);
        FigPos(1:2) = [(GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2, ...
                       (GCBFPos(2) + GCBFPos(4) / 2) - FigHeight / 2];
    end
    FigPos(3:4)=[FigWidth FigHeight];
    set(hObject, 'Position', FigPos);
    set(hObject, 'Units', OldUnits);
    set(handles.figure1,'WindowStyle','modal')

    % UIWAIT makes PasteDataDialog wait for user response (see UIRESUME)
    uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = PasteDataDialog_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure 
    varargout{1} = hObject;
    output.ok = handles.Ok;
    output.approved = handles.output;
    output.error = handles.error;
    varargout{2} = output;
    varargout{3} = handles.Data;
    % The figure can be deleted now
    delete(handles.figure1);
end

% --- Executes on button press in okButton.
function okButton_Callback(hObject, eventdata, handles)
    handles.output = true;
    handles.Data.PastedData = get(handles.dataTable, 'Data');

    columnNames = get(handles.dataTable, 'ColumnName');
    if (iscell(columnNames))
        handles.Data.PastedHeaders = columnNames;
    else
        handles.Data.PastedHeaders = {};
    end
    x = get(handles.xColPopup, 'Value');
    dx = get(handles.dxColPopup, 'Value');
    y = get(handles.yColPopup, 'Value');
    dy = get(handles.dyColPopup, 'Value');

    handles.Data.SelectedData = handles.Data.PastedData(:, [x dx y dy]);
    
    guidata(hObject, handles);
    uiresume(handles.figure1);
end

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
    handles.output = false;

    guidata(hObject, handles);
    uiresume(handles.figure1);
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
    if isequal(get(hObject, 'waitstatus'), 'waiting')
        uiresume(hObject);
    else
        delete(hObject);
    end
end

% --- Executes on key press over figure1 with no controls selected.
function figure1_KeyPressFcn(hObject, eventdata, handles)
    % Check for "enter" or "escape"
    if isequal(get(hObject,'CurrentKey'),'escape')
        % User said no by hitting escape
        handles.output = false;

        % Update handles structure
        guidata(hObject, handles);

        uiresume(handles.figure1);
    end    

    if isequal(get(hObject,'CurrentKey'),'return')
        uiresume(handles.figure1);
    end
end

function yColPopup_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
function xColPopup_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
function dyColPopup_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
function dxColPopup_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
