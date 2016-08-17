function [ok, Fit] = GetFitData(app, nonLinear, function_input, x, dx, y, dy, x_min, x_max, a0)
    ok = true;    
    if x_min == x_max
        x_min = min(x); x_max = max(x);
    end
    %APPLAYING RANGE
    ind = find( x >= x_min & x <= x_max ); 
    x_fit = x(ind); %x_fit is the range the fit is performed upon
    dx_fit = dx(ind); % x_fit errors
    y_fit = y(ind);  % the y values in the required range
    dy_fit = dy(ind); % y fit errors
    
    x_min = min(x_fit) - 0.1*abs(min(x_fit));
    x_max = max(x_fit) + 0.1*abs(max(x_fit));
    x_fit_plot = linspace(x_min , x_max , 500);    
    if ~nonLinear
        [a0,tmp,tmp,tmp,tmp] = fitlin(x_fit,y_fit,dy_fit);
    end
    
    try [a, aerr, cov, chisq, y_fit_plot, err] = fitnonlin(x_fit,x_fit_plot,y_fit,dx_fit,dy_fit,function_input,a0);
    catch 
        app.Func.SetError(app, 'Invalid Function');
        Fit = 0;
        ok = false;
        return;
    end
    app.Status.Warning = err;
    
    RChiSquare = chisq/(length(x_fit)-length(a)) ;     %Reduced Chi-Square of your fit.
    p_value = 1 - chi2cdf(chisq,length(x_fit)-length(a));
    
    Fit.x_fit = x_fit;
    Fit.y_fit = y_fit;
    Fit.a = a;
    Fit.aerr = aerr;
    Fit.chisq = chisq;
    Fit.RChiSquare = RChiSquare;
    Fit.x_fit_plot = x_fit_plot;
    Fit.p_value = p_value;
    Fit.y_fit_plot = y_fit_plot;

end

function [a,aerr,cov,chisq,yfit] = fitlin(x,y,sig)
    %Version 2 (creatd by Adiel Meyer 15.10.2012)
    %
    % FITLIN Fit a linear function to data.
    %    [a,aerr,chisq,yfit] = fitnonlin(x,y,sig) 
    %
    %    Inputs:  x -- the x data to fit
    %             y -- the y data to fit
    %             sig -- the uncertainties on the data points
    %
    %    Outputs: a -- the best fit parameters
    %             aerr -- the errors on these parameters
    %             chisq -- the value of chi-squared
    %             yfit -- the value of the fitted function
    %                     at the points in x
    %
    % The least-squares fit to a straight line can be done in closed form
    % See Bevington and Robinson Ch. 6 (p. 114).

    term1=sum(1./sig.^2);
    term2=sum(x.^2./sig.^2);
    term3=sum(y./sig.^2);
    term4=sum(x.*y./sig.^2);
    term5=sum(x./sig.^2);
    
    delta=term1*term2-term5^2;
    a(1)=(term2*term3-term5*term4)/delta;
    a(2)=(term1*term4-term5*term3)/delta;
    
    aerr(1)=sqrt(term2/delta);
    aerr(2)=sqrt(term1/delta);
    
    cov = - term5/(term1 * term2 - term5 * term5);
    yfit = a(1) + a(2)*x;
    chisq = sum(((y-a(1)-a(2)*x)./sig).^2);
end

function [a, aerr, cov, chisq, yfit, err] = fitnonlin(x, x_res, y, sigx, sigy, fitfun, a0)
    % Version 2 (creatd by Adiel Meyer 15.10.2012)
    %
    % FITNONLIN Fit a nonlinear function to data.
    %    [a,aerr,chisq,yfit] = fitnonlin(x,y,sig,fitfun,a0) 
    %
    %    Inputs:  x -- the x data to fit
    %             xres -- a higher resolution version of x for plotting, where
    %             yfit is plotted.
    %             y -- the y data to fit
    %             sigx -- the uncertainties on the data points
    %             sigy -- the uncertainties on the data points
    %             fitfun -- the name of the function to fit to
    %             a0 -- the initial guess at the parameters 
    %
    %    Outputs: a -- the best fit parameters
    %             aerr -- the errors on these parameters
    %             chisq -- the final value of chi-squared
    %             yfit -- the value of the fitted function
    %                     at the points in x_res
    %  
    %    Note: "fitfun" should be in a .m file similar to the
    %    following example.
    %
    %          The following lines are saved in a file called
    %          "sinfit.m", and the routine is invoked with
    %          the fitfun parameter equal to 'sinfit' (including
    %          the quotes)
    %
    %          function f = sinfit(x,a)
    %          f = a(1)*sin(a(2)*x+a(3));
    %

    % first set up the parameters needed by the algorithm
    err = '';
    stepdown = 0.1;
    stepsize = abs(a0)*0.01+eps ; % the amount each parameter will be varied by in each iteration
    chicut = 0.00001;  % maximum differential allowed between successive chi sqr values
    % These parameters can be varied if you have reason to believe your fit is
    % converging to quickly or that you are in a local minima of the chi
    % square.
    a = a0;
    iter=0;
    %chi2 = calcchi2(x,y,sig,fitfun,a);
    chi2 = calcchi2(x,y,sigx,sigy,fitfun,a);
    chi1 = chi2+chicut*2;
    % keep looking while the value of chi^2 is changing
    while (abs(chi2-chi1))>chicut

        [anew,stepsum,stopflag,iter] = gradstep(x,y,sigx,sigy,fitfun,a,stepsize,stepdown,iter);
        a = anew;
        stepdown = stepsum;
        chi1 = chi2;
        chi2 = calcchi2(x,y,sigx,sigy,fitfun,a);
        if stopflag==1
            err = 'WARNING: max iterations reached - try different initial parameters';
            break;
        end
    end
    % calculate the returned values
    [aerr,cov] = sigparab(x,y,sigx,sigy,fitfun,a,stepsize);
    chisq = calcchi2(x,y,sigx,sigy,fitfun,a);
    yfit = feval(fitfun,x_res,a);
end

%----------------------------------------------------------------------- 
% the following function calculates the (negative) chi^2 gradient at
% the current point in parameter space, and moves in that direction
% until a minimum is found
% returns the new value of the parameters and the total length travelled
function [anew,stepsum,stopflag,iter] = gradstep(x,y,sigx,sigy,fitfun,a,stepsize, stepdown,iter)
    stopflag=0;
    chi2 = calcchi2(x,y,sigx,sigy,fitfun,a);
    grad = calcgrad(x,y,sigx,sigy,fitfun,a,stepsize);
    chi3 = chi2*1.1;
    chi1 = chi3;
    
    if y == feval(fitfun, x, a)
        stepsum = 0;
        anew = a;
        return;
    end
    
    % cut down the step size until a single step yields a decrease 
    % in chi^2
    stepdown = stepdown*2;
    j = 0;
    maxiter=100000;
    while chi3>chi2
      stepdown = stepdown/2;
      anew = a+stepdown*grad;
      chi3 = calcchi2(x,y,sigx,sigy,fitfun,anew);
      j=j+1;
      iter=iter+1;

      if (iter > maxiter) 
          stopflag=1;
          break;
      end;
    end

    stepsum = 0;

    % keep going until a minimum is passed

    while chi3<chi2
    %   fprintf(['\n ',num2str(anew),' \n'])
      stepsum = stepsum+stepdown;
      chi1 = chi2;
      chi2 = chi3;
      anew = anew+stepdown*grad;
      chi3 = calcchi2(x,y,sigx,sigy,fitfun,anew);
      iter=iter+1;

      if (iter > maxiter) 
          stopflag=1;
          break; 
      end;
      %fprintf(2, 'iteration 2 No. %d\n', t)
      %fprintf(2,'can not find fit parameters, try differrent intial parameters\n')
    end

    % approximate the minimum as a parabola
    step1 = stepdown*((chi3-chi2)/(chi1-2*chi2+chi3)+.5);
    anew = anew - step1*grad;
end

%------------------------------------------------------------
% this function just calculates the value of chi^2
function chi2 = calcchi2(x,y,sigx,sigy,fitfun,a)
    %chi2 = sum( ((y-feval(fitfun,x,a)) ./sig).^2);
    xup = x + sigx;
    xdwn = x - sigx;
    chi2 = sum( ((y-feval(fitfun,x,a)).^2)./(sigy.^2 + ((feval(fitfun,xup,a) - feval(fitfun,xdwn,a))./2).^2) );
end

%--------------------------------------------------------------
% this function calculates the (negative) gradient at a point in 
% parameter space
function grad = calcgrad(x,y,sigx,sigy,fitfun,a, stepsize)
    f = 0.01;
    [~, nparm] = size(a);

    grad = a;
    chisq2 = calcchi2(x,y,sigx,sigy,fitfun,a);  
    for i=1:nparm

      a2 = a;
      da = f*stepsize(i);
      a2(i) = a2(i)+da;
      chisq1 = calcchi2(x,y,sigx,sigy,fitfun,a2);
      grad(i) = chisq2-chisq1;

    end

    t = sum(grad.^2);   
    grad = stepsize.*grad/sqrt(t);
end

%------------------------------------------------------------
% this function calculates the errors on the final fitted 
% parameters by approximating the minimum as parabolic
% in each parameter.
function [err1,cov]=sigparab(x,y,sigx,sigy,fitfun,a,stepsize)
    [~, nparm] = size(a);
    for j=1:nparm
        da(j) = stepsize(j);
        a1=a;
        a1(j)=a1(j)+da(j);
        a2= a;
        a3= a1;
        for k=1:nparm
            da(k) = stepsize(k);
            a2(k)=a2(k)+da(k);
            a3(k)=a3(k)+da(k); 
            dCHI2da(j,k)=0.5*(calcchi2(x,y,sigx,sigy,fitfun,a)-calcchi2(x,y,sigx,sigy,fitfun,a1)-calcchi2(x,y,sigx,sigy,fitfun,a2)+calcchi2(x,y,sigx,sigy,fitfun,a3))/da(j)/da(k);
        end
     end
    errc=inv(dCHI2da);
    cov=errc;
    for j=1:nparm
         err1(j) = sqrt(abs(errc(j,j)));
    end
end

  
