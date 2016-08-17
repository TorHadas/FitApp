function funs = GetFunctions
    funs.audioObj = @audioObj;
    funs.SetError = @SetError;
    funs.SetStatus = @SetStatus;
    funs.SetDone = @SetDone;
    funs.PlotFit = @PlotFit;
    funs.PlotRes = @PlotRes;
    funs.MarkFit = @MarkFit;
    funs.MarkRes = @MarkRes;
    funs.titleFit = @titleFit;
    funs.titleRes = @titleRes;
    funs.xtitle = @xtitle;
    funs.ytitleRes = @ytitleRes;
    funs.ytitleFit = @ytitleFit;
    funs.PlotFuncFcn = @PlotFuncFcn;
    funs.PlotDataFcn = @PlotDataFcn;
    funs.CalculateFitFcn = @CalculateFitFcn;
    funs.PlotFitFcn = @PlotFitFcn;
    funs.PlotResidualsFcn = @PlotResidualsFcn;
    funs.OpenDataFile = @OpenDataFile;
    funs.SetLimRes = @SetLimRes;
    funs.SetLimFit = @SetLimFit;
    funs.PlotLegends = @PlotLegends;
    funs.PasteData = @PasteData;
end

function PasteData(app)
    [dlg, status, data] = PasteDataDialog();
    %[dlg, data] = PasteDataDialog();  
    if status.ok == false
        app.Func.SetError(app, status.error);
        return;
    end
    if (status.approved)
        app.Data.x  = data.SelectedData(:, 1);
        app.Data.dx = data.SelectedData(:, 2);
        app.Data.y  = data.SelectedData(:, 3);
        app.Data.dy = data.SelectedData(:, 4);
        if strcmp(app.PlotAllButton.Enable, 'off')
            app.PlotAllButton.Enable = 'on';
            app.PlotDataButton.Enable = 'on';
            app.CalculateFitButton.Enable = 'on';
        end
        app.Func.SetDone(app);
    end
end

function audioObj = file2audio(filename)
    [y,Fs] = audioread(filename);
    audioObj = audioplayer(y,Fs);
end

function SetError(app, msg)
    obj = file2audio('Sounds\Error.wav');
    play(obj);
    app.StatusLabel.Text = 'Error';
    app.StatusTextLabel.Text = msg;
    app.StatusLabel.FontColor = [1,0,0];
    app.StatusTextLabel.FontColor = [0,0,0];
    for i = 1 : 3
        app.StatusLabel.FontColor = app.Colors.Background;
        app.StatusPanel.BackgroundColor = [1,0,0];
        pause(0.15);
        app.StatusLabel.FontColor = [1,0,0];
        app.StatusPanel.BackgroundColor = app.Colors.Background;
        pause(0.15);
    end
end

function SetStatus(app, msg)
    app.StatusPanel.BackgroundColor = app.Colors.Background;
    app.StatusLabel.Text = 'Status';
    app.StatusTextLabel.Text = msg;
    app.StatusLabel.FontColor = [0,0,0];
    app.StatusTextLabel.FontColor = [0,0,0];
end

function SetDone(app)
    obj = file2audio( 'Sounds\Done.wav');
    play(obj);
    
    app.StatusPanel.BackgroundColor = app.Colors.Background;
    app.StatusLabel.Text = 'Done';
    app.StatusTextLabel.Text = app.Status.Warning;
    app.Status.Warning = '';
    app.StatusLabel.FontColor = [0,0.5,0];
    app.StatusTextLabel.FontColor = [202/255,196/255,0];
    pause(0.7);
end

function PlotFit(app, varargin)
    hold(app.FitAxes, 'on');
    plot(app.FitAxes, varargin{:}, 'MarkerSize', 2);
    hold(app.FitAxes, 'off');
    hold(app.Save.FitAxes, 'on');
    plot(app.Save.FitAxes, varargin{:}, 'MarkerSize', 5);
    hold(app.Save.FitAxes, 'off');
end

function PlotRes(app, varargin)
    hold(app.ResAxes, 'on');
    plot(app.ResAxes, varargin{:}, 'MarkerSize', 2);
    hold(app.ResAxes, 'off');
    hold(app.Save.ResAxes, 'on');
    plot(app.Save.ResAxes, varargin{:}, 'MarkerSize', 5);
    hold(app.Save.ResAxes, 'off');
end

function MarkFit(app, varargin)
    hold(app.FitAxes, 'on');
    hold(app.Save.FitAxes, 'on');
    plot(app.FitAxes, varargin{:}, 'MarkerSize', 8);
    plot(app.Save.FitAxes, varargin{:}, 'MarkerSize', 15);
    hold(app.FitAxes, 'off');
    hold(app.Save.FitAxes, 'off');
end

function MarkRes(app, varargin)
    hold(app.ResAxes, 'on');
    hold(app.Save.ResAxes, 'on');
    plot(app.ResAxes, varargin{:}, 'MarkerSize', 8);
    plot(app.Save.ResAxes, varargin{:}, 'MarkerSize', 15);
    hold(app.ResAxes, 'off');
    hold(app.Save.ResAxes, 'off');
end


    
function titleFit(app, varargin)
    title(app.Save.FitAxes, varargin{:});
    title(app.FitAxes, varargin{:});
end

function titleRes(app, varargin)
    title(app.Save.ResAxes, varargin{:});
    title(app.ResAxes, varargin{:});
end

function xtitle(app, varargin)
    xlabel(app.Save.FitAxes, varargin{:});
    xlabel(app.FitAxes, varargin{:});
    xlabel(app.Save.ResAxes, varargin{:});
    xlabel(app.ResAxes, varargin{:});
end

function ytitleRes(app, varargin)
    ylabel(app.Save.ResAxes, varargin{:});
    ylabel(app.ResAxes, varargin{:});
end

function ytitleFit(app, varargin)
    ylabel(app.Save.FitAxes, varargin{:});
    ylabel(app.FitAxes, varargin{:});
end

function done = PlotFuncFcn(app)
    done = false;
    if ~isfield(app.Data, 'x')
        SetError(app, 'Can''t plot initial function - NO DATA');
        return;
    end

    [ok, a0] = SetFunction(app);
    if ~ok
        return;
    end
    
    x = app.Data.x;        
    x_min = min(x);
    x_max = max(x);

    if app.RangeCheckBox.Value
        x_min = str2double(app.RangeMinText.Value); 
        x_max = str2double(app.RangeMaxText.Value); 
    end

    inRange = x >= x_min & x <= x_max ; 
    x_fit = x(inRange); %x_fit is the range the fit is performed upon        
    x_plot = linspace(min(x_fit) , max(x_fit) , 30); 
    try y_plot = feval(app.Data.Function, x_plot,a0);
    catch 
        app.Func.SetError(app, 'Invalid Function');
        return;
    end
        
    PlotFit(app, x_plot,y_plot,'-', 'Color', app.Colors.Fit); % Plots  the fitted curve
    SetLimFit(app, app.Data.y)
    done = true;
end

function done = PlotDataFcn(app)
    done = false;
    SetStatus(app, 'Plotting Data...');
    x = app.Data.x; y = app.Data.y; dx = app.Data.dx; dy = app.Data.dy;
    if app.RangeCheckBox.Value
        inRange = (x < app.RangeMaxText.Value & x > app.RangeMinText.Value);
        x = x(inRange);
        dx = dx(inRange);
        y = y(inRange);
        dy = dy(inRange);
    end

    [xerrx, xerry, yerrx, yerry] = GetErrBars(x, y, dx, dy, 'hhxy', 0.0001);
    PlotFit(app, xerrx, xerry, '-', 'Color', app.Colors.Error);
    PlotFit(app, yerrx, yerry, '-', 'Color', app.Colors.Error);
    PlotFit(app, x, y, '.', 'Color', app.Colors.Dot); 

    if app.MarkCheckBox.Value
        N = str2num(app.MarkText.Value);
        if app.RangeCheckBox.Value
            N = N(inRange(N));
        end
        MarkFit(app, app.Data.x(N), app.Data.y(N), 'o', 'Color', app.Colors.Mark);
    end
    SetLimFit(app, y);
    done = true;
end

function done = CalculateFitFcn(app)
    done = false;
    nonLinear = app.FuncCheckBox.Value;

    [ok, a0] = SetFunction(app);
    if ~ok
        return;
    end

    x  = app.Data.x;
    dx = app.Data.dx; 
    y  = app.Data.y; 
    dy = app.Data.dy; 
    
    if app.RangeCheckBox.Value
        inRange = (x < app.RangeMaxText.Value & x > app.RangeMinText.Value);
        x = x(inRange);
        dx = dx(inRange);
        y = y(inRange);
        dy = dy(inRange);
    end
    
    x_min = min(x);
    x_max = max(x);
    if app.RangeCheckBox.Value
        x_min = app.RangeMinText.Value;
        x_max = app.RangeMaxText.Value;
    end

    SetStatus(app, 'Minimizing chi^2...');
    [ok, Fit] = GetFitData(app, nonLinear, app.Data.Function, x, dx, y, dy, x_min, x_max, a0);
    if(~ok)
        done = false;
        return;
    end
    a = Fit.a;
    aerr = Fit.aerr;
    RChiSquare = Fit.RChiSquare;
    p_value = Fit.p_value;
    
    
    OutputToCopy = {}; OutputRel = {}; OutputRelToCopy = {};
    OutputToCopy{1} = ['chi^2_reduced = ' , num2str(RChiSquare , 5)];
    OutputToCopy{2} = ['p-value = ' , num2str(p_value, 5)];
	
    %newline = '</sup></td></tr><tr><td><center><b>';
    %equals = '</b></center</td><td>= ';
    %Output = {}; 
    %Output{1} = ['<html><table><tr><td><center><b>', 'chi^2_reduced', equals, num2str(RChiSquare , 5)];
    %Output{2} = [newline, 'p-value', equals, num2str(p_value, 5)];
    forRep = 2;
    if nonLinear
        forRep = length(a0);
    end
    for n = 1:forRep
        nstr = num2str(n);
        anstr = num2str(a(n) , 7);
        aerrnstr = num2str(aerr(n) , 5);
        reln = abs(100*aerr(n)/a(n));
        if reln < 0.1
            relnstr = ' < 0.1';
        elseif reln > 999
            relnstr = ' > 1000';
        else
            relnstr = [' = ' num2str( abs(100*aerr(n)/a(n)) , 3)];
        end
        
        OutputToCopy{n+2} = ['a'  nstr ' = ' anstr ' ± ' aerrnstr];
        OutputRel{n} = [char(948) nstr relnstr '%'];
        OutputRelToCopy{n} = [char(916) 'a' nstr '/a' nstr relnstr '%']; 
        %Output{n+2} = [newline 'a<sub>'  nstr '</sub>' equals anstr ' </sup>± ' aerrnstr];
    end
    %Output{end} = [Output{end}, '</td></tr></table></html>'];
    %Output = strrep(Output, 'e', '·10<sup>');
    
    OutputToCopy = strrep(OutputToCopy, 'e+', '*10^');
    OutputToCopy = strrep(OutputToCopy, 'e-', '*10^-');
    
    
    app.chiLabel.Text = num2str(RChiSquare);
    if RChiSquare<1.5 && RChiSquare > 0.75
        app.chiLabel.FontColor = [0,0.5,0];
    else
        app.chiLabel.FontColor = [0.5,0,0];
    end    
    app.pvalueLabel.Text = num2str(p_value);
    if p_value<0.95 && p_value > 0.05
        app.pvalueLabel.FontColor = [0,0.5,0];
    else
        app.pvalueLabel.FontColor = [0.5,0,0];
    end
    
    app.Data.Output = [OutputToCopy OutputRelToCopy];
    app.OutputText.Value = OutputToCopy(3:end);
    app.OutputRelText.Value = OutputRel;
    app.Data.Fit = Fit;
    done = true;
end

function done = PlotFitFcn(app)
    done = false;
    SetStatus(app, 'Plotting Fit...');
    PlotFit(app, app.Data.Fit.x_fit_plot, app.Data.Fit.y_fit_plot , 'Color', app.Colors.Fit);
    y  = app.Data.y; 
    if app.RangeCheckBox.Value
        inRange = (app.Data.x < app.RangeMaxText.Value & app.Data.x > app.RangeMinText.Value);
        y = y(inRange);
    end
    SetLimFit(app, y);
    done = true;
end

function done = PlotResidualsFcn(app)
    done = false;
    SetStatus(app, 'Plotting Residuals...');
    x = app.Data.x; y = app.Data.y; dx = app.Data.dx; dy = app.Data.dy;
    if app.RangeCheckBox.Value
        inRange = (x < app.RangeMaxText.Value & x > app.RangeMinText.Value);
        x = x(inRange);
        dx = dx(inRange);
        y = y(inRange);
        dy = dy(inRange);
    end
    y_res = y - feval(app.Data.Function, x, app.Data.Fit.a);
    [xerrx, xerry, yerrx, yerry] = GetErrBars(x, y_res, dx, dy, 'hhxy',0.0001);
    PlotRes(app, xerrx, xerry, '-', 'Color', app.Colors.Error);
    PlotRes(app, yerrx, yerry, '-', 'Color', app.Colors.Error);
    PlotRes(app, x, y_res, '.', 'Color', app.Colors.Dot);

    if app.MarkCheckBox.Value
        N = str2num(app.MarkText.Value);
        MarkRes(app, app.Data.x(N), y_res(N), 'o', 'Color', app.Colors.Mark);
    end
    
    PlotRes(app, app.Data.Fit.x_fit_plot, zeros(size(app.Data.Fit.y_fit_plot)), 'Color', app.Colors.Fit);        % Plots a line of zeros
    SetLimRes(app, y_res)
    done = true;
end

function done = OpenDataFile(app)
    done = false;
    [filename, pathname] = uigetfile( ...
    {'*.txt;','Text Files (*.txt)';
       '*.*',  'All Files (*.*)'}, ...
       'Pick a file',...
       app.Data.File);
    if isequal(filename,0)
       return;
    end
    filename_full = fullfile(pathname,filename);  
    app.Data.File = fullfile;
    set(app.OpenFileText,'String', filename_full);
    data_given = load(filename_full);
    if size(data_given,2)==4
        app.Datax = data_given(:,1); %set the range
        app.Datadx = data_given(:,2); % x errors
        app.Datay = data_given(:,3);  % Assigns the second column of mydata to a vector called 'y'
        app.Datady = data_given(:,4); % y errors
    elseif size(data_given,2)==2
        app.Datax = data_given(:,1);  % Assigns the first column of mydata to a vector called 'x'
        app.Datadx = zeros(length(data_given), 1); % x errors
        app.Datay = data_given(:,2);  % Assigns the second column of mydata to a vector called 'y'
        app.Datady = zeros(length(data_given), 1); % y errors
    else
        SetError(app, 'Data file error');
    end

    if app.PlotAllButton.Enable == 'off'
        app.PlotAllButton.Enable = 'on';
        app.PlotDataButton.Enable = 'on';
        app.CalculateFitButton.Enable = 'on';
        app.PlotFitButton.Enable = 'on';
        app.PlotResidualsButton.Enable = 'on';
    end
    done = true;
end

function PlotLegends(app)
    return;
    legend(app.FitAxes, 'off')
    legend(app.FitAxes, 'toggle')
    legend(app.ResAxes, 'off')
    legend(app.ResAxes, 'toggle')
    legend(app.Save.FitAxes, 'off')
    legend(app.Save.FitAxes, 'toggle')
    legend(app.Save.ResAxes, 'off')
    legend(app.Save.ResAxes, 'toggle')

    legName = app.LegendsText.Value;
    legNames = strsplit(legName, ';');

    legend(app.FitAxes, legNames);
    legend(app.ResAxes, legNames);
    legend(app.Save.FitAxes, legNames);
    legend(app.Save.ResAxes, legNames);

    legend_h = legend(app.FitAxes);
    set(legend_h, 'Interpreter', GetInterpreterString(hObject, handles, 'legendsInterpreterPopup'));
    legend_h = legend(app.Save.FitAxes);
    set(legend_h, 'Interpreter', GetInterpreterString(hObject, handles, 'legendsInterpreterPopup'));
    legend_h = legend(app.ResAxes);
    set(legend_h, 'Interpreter', GetInterpreterString(hObject, handles, 'legendsInterpreterPopup'));
    legend_h = legend(app.Save.ResAxes);
    set(legend_h, 'Interpreter', GetInterpreterString(hObject, handles, 'legendsInterpreterPopup'));
end

function SetLimRes(app, y)
    xlim(app.ResAxes, 'auto');
    xlim(app.Save.ResAxes, 'auto');
    ylim(app.ResAxes, 'auto');
    try
        yl = ylim(app.ResAxes);
        miny = min(y) - 0.03*abs(min(y));
        maxy = max(y) + 0.03*abs(max(y));
        yl(1) = (yl(1) + miny) / 2;
        yl(2) = (yl(2) + maxy) / 2;
        yl(1) = min(yl(1),  miny);
        yl(2) = max(yl(2),  maxy);
        ylim(app.ResAxes, yl);
        ylim(app.Save.ResAxes, yl);
    catch
        ylim(app.ResAxes, 'auto');
        ylim(app.Save.ResAxes, 'auto');
    end
end

function SetLimFit(app, y)
    xlim(app.FitAxes, 'auto');
    xlim(app.Save.FitAxes, 'auto');
    ylim(app.FitAxes, 'auto');
    yl = ylim(app.FitAxes);
    miny = min(y) - 0.03*abs(min(y));
    maxy = max(y) + 0.03*abs(max(y));
    yl(1) = (yl(1) + miny) / 2;
    yl(2) = (yl(2) + maxy) / 2;
    yl(1) = min(yl(1),  miny);
    yl(2) = max(yl(2),  maxy);
    ylim(app.FitAxes, yl);
    ylim(app.Save.FitAxes, yl);
end

function [ok, a0] = SetFunction(app)
    ok = true;
    a0 = str2num(app.FuncArgsText.Value);
    nonLinear = app.FuncCheckBox.Value;
    function_text = strjoin(app.FuncText.Value);
    args = getArgsIn(function_text);

    if nonLinear
        try eval(['app.Data.Function', ' = @(x, a) ', function_text, ';']);
        catch 
            SetError(app, 'Invalid Function');             
            ok = false;
            return;
        end
        if length(a0) < args
            SetError(app, ['Not enough arguments. NEED: ', num2str(args), ' GOT: ', num2str(length(a0))])
            ok = false;
            return;
        elseif length(a0) > args
            a0 = a0(1:args);
        end  
    else
        eval('app.Data.Function = @(x, a) a(1) + x.*a(2);');
    end
end

function n = getArgsIn(text)
    matches = regexp(text, 'a(+[1234567890\s]+\)', 'match');
    n = 0;
    for i=1:length(matches)
        num = char(matches(i))
        num = num(3:end-1)
        num = str2num(num);
        if num > n
            n = num
        end
    end
end