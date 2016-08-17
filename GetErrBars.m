function [xerrx, xerry, yerrx, yerry] = GetErrBars(x, y, xerr, yerr, varargin)
    [logx,logy,hhx,hhy]=getproperties(varargin);
    
    % analyse and prepare inputs (this section is a little ugly, you are invited to improve it!)
    if ~ismatrix(x) || ~ismatrix(y)
        error('wrong x and y input');
    end

    try [x,y]=expandarrays(x,y); 
    catch
        error('x and y are not consistent in size.');
    end

    % check if xerror is relative or absolute
    if ~iscell(xerr)
        if ~isempty(xerr)
            xl = x - xerr;  xh = x + xerr;
        else
            xl = [];        xh = [];
        end
    elseif length(xerr)~=2
        error('xerr must have two entries (low and upper bounds) if it is a cell array')
    else
        try [xl,xh]=expandarrays(xerr{1},xerr{2}); catch 
            error('xl and xh are not consistent in size.'), end
    end

    try [y,xl,ty,txl]=expandarrays(y,xl); catch 
        error('xerr and y are not consistent in size.'), end
    if ty, y=y'; xl=xl'; txl=~txl; end % make sure x and y still match
    if txl, xh=xh'; end % make sure xl and xh still match
    
    % check if yerror is relative or absolute
    if ~iscell(yerr)
        if ~isempty(yerr)
            yl = y - yerr;  yh = y + yerr;
        else
            yl = [];        yh = [];
        end
    elseif length(yerr)~=2
        error('yerr must have two entries (low and upper bounds) if it is a cell array,')
    else
        try [yl,yh]=expandarrays(yerr{1},yerr{2}); catch 
        	error('yl and yh are not consistent in size.'), end
    end

    try [x,yl,tx,tyl]=expandarrays(x,yl); catch 
        error('yl and x are not consistent in size.'), end
    if tx, x=x'; yl=yl'; tyl=~tyl; end % make sure x and y still match
    if tyl, yh=yh'; end % make sure yl and yh still match

    % do the plotting
    % plot specified data
    [xerry,xerrx]=barline(y,xl,xh,logy,hhx);
    [yerrx,yerry]=barline(x,yl,yh,logx,hhy);
    end
% helper functions
function [perp,para] = barline(v,l,h,uselog,handleheight)
    % v: value "perpendicular"
    % l: lower bound "parallel"
    % h: upper bound "parallel"
    
    [npt,n]=size(l);
    
    % calculate height of errorbar delimiters
    
    % set basic operations for linear spacing
    dist=@minus;
    invdist=@plus;
    scale=@times;
    
    if uselog
        % overwrite basic operations for logarithmic spacing
        dist=@rdivide;
        invdist=@times;
        scale=@power;
    end
    
    if handleheight>0 % means handleheight was passed as a relative value
	    % set width of ends of bars to handleheight times mean distance of the bars.
	    % If number of points is under 15, space as if 15 points were there.
	    if dist(max(v(:)),min(v(:)))==0
	      dv = scale(abs(v),1/40) + (abs(v)==0);
	    else
	      dv = scale(dist(max(v(:)),min(v(:))),1/max(15,npt-1)*handleheight/2);
	    end
	else % handleheight<=0 means handleheight was passed as an absolute value
        dv=handleheight/2;
        if uselog, dv=10^dv; end
    end

    vh = invdist(v,dv);
    vl = dist(v,dv);

    % build up nan-separated vector for bars
    para = zeros(npt*9,n);
    para(1:9:end,:) = h;
    para(2:9:end,:) = l;
    para(3:9:end,:) = NaN;
    para(4:9:end,:) = h;
    para(5:9:end,:) = h;
    para(6:9:end,:) = NaN;
    para(7:9:end,:) = l;
    para(8:9:end,:) = l;
    para(9:9:end,:) = NaN;

    perp = zeros(npt*9,n);
    perp(1:9:end,:) = v;
    perp(2:9:end,:) = v;
    perp(3:9:end,:) = NaN;
    perp(4:9:end,:) = vh;
    perp(5:9:end,:) = vl;
    perp(6:9:end,:) = NaN;
    perp(7:9:end,:) = vh;
    perp(8:9:end,:) = vl;
    perp(9:9:end,:) = NaN;

end

function [A,B,tA,tB] = expandarrays(A,B)
    % A, B: Matrices to be expanded by repmat to have same size after being processed
    % tA, tB: Has A\B been transposed?
    sizA=size(A); tA=false;
    sizB=size(B); tB=false;
    
    % do not process empty arrays
    if isempty(A) || isempty(B), return, end
    
    % row vector -> column vector
    if sizA(1)==1, A=A(:); tA=~tA; sizA=sizA([2 1]); end
    if sizB(1)==1, B=B(:); tB=~tB; sizB=sizB([2 1]); end
    
    % transpose to fit column, if necessary
    if sizA(2)==1 && sizB(2)~=1 && sizB(2)==sizA(1) && sizB(1)~=sizA(1), B=B'; tB=true; sizB=sizB([2 1]); end
    if sizB(2)==1 && sizA(2)~=1 && sizA(2)==sizB(1) && sizA(1)~=sizB(1), A=A'; tA=true; sizA=sizA([2 1]); end
    
    % Expand Sigletons
    if sizA == 1
        A=repmat(A,sizB);
    elseif sizB == 1
        B=repmat(B,sizA);
    elseif sizA ~= sizB % otherwise return error
        error('Arrays A and B must have equal size for all dimensions that are not singleton!')
    end
end

function [lx,ly,hx,hy] = getproperties(A)
    if isempty(A), return, end

    lx=0; ly=0; hx=2/3; hy=2/3; % presets
    
    n=length(A);
    A=[A '!"§$%&()=?']; % append some stupid string for the case that the last property comes without a value
    idx=1;
    while idx <= n
        prop=A{idx};
        val=A{idx+1};
        if all(prop(end-1:end)=='yx') || all(prop(end-1:end)=='xy'), prop=prop(1:end-2); end
        switch prop
         case 'logx'
            if isnumeric(val), lx=val;
            else lx=1; idx=idx-1;
            end
         case 'logy'
            if isnumeric(val), ly=val;
            else ly=1; idx=idx-1;
            end
         case 'log'
            if isnumeric(val), ly=val; lx=val;
            else ly=1; lx=1; idx=idx-1;
            end
         case 'hhx'
            if isnumeric(val), hx=abs(val);
            else error('Property hhx must be followed by a numerical value.');
            end
         case 'hhy'
            if isnumeric(val), hy=abs(val);
            else error('Property hhy must be followed by a numerical value.');
            end
         case 'hh'
            if isnumeric(val), hy=abs(val); hx=abs(val);
            else error('Property hh must be followed by a numerical value.');
            end
         case 'abshhx'
            if isnumeric(val), hx=-abs(val);
            else error('Property abshhx must be followed by a numerical value.');
            end
         case 'abshhy'
            if isnumeric(val), hy=-abs(val);
            else error('Property abshhy must be followed by a numerical value.');
            end
         case 'abshh'
            if isnumeric(val), hy=-abs(val); hx=-abs(val);
            else error('Property abshh must be followed by a numerical value.');
            end
         otherwise
            if ischar(prop), error(['Unknown property: ' prop])
            else error('Parsed a property that is not a string.')
            end
        end
        idx=idx+2;
    end
end