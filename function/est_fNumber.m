function fnumber = est_fNumber(width,lambda,directivity_threshold)
    % 经验值     directivity_threshold = 0.71(-3dB); 
    f = @(th,width,lambda) abs(cos(th)*sinc(width/lambda*sin(th)) - directivity_threshold);
    alpha = fminbnd(@(th) f(th,width,lambda),0,pi/2);
    fnumber = 1/2/tan(alpha);
end