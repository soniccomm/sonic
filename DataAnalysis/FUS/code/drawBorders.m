
function drawBorders(atlas,orientation,plane)

if    strcmp(orientation,'coronal')
   L=atlas.Lines.Cor{plane}; 
elseif  strcmp(orientation,'sagittal')
   L=atlas.Lines.Sag{plane}; 
elseif strcmp(orientation,'transversal')
   L=atlas.Lines.Tra{plane}; 
else
   error('cut must be: coronal sagittal or transversal')
end

hold on;
nb=length(L);
for ib=1:nb
    x=L{ib};
    plot(x(:,2),x(:,1),'k:');        % change the color of the line
end
hold off
end
