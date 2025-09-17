function showFrames(sensorData,range)
    sensorData = permute(sensorData,[3 2 1]);
    num_channels = size(sensorData,2);
    framePoints = size(sensorData,3);
    RawFrames = zeros(num_channels,framePoints*length(range));
    j = 1;
    for i = range
        RawFrames(:,(j-1)*framePoints+1:j*framePoints) = squeeze(sensorData(i,:,:));
        j = j+1;
    end
    figure;
    imagesc(RawFrames,[-3500,3500]);
    colormap(getColorMap);
    colorbar;
    title(['range:',num2str(range(1)),'~',num2str(range(end))]);
%     imshow(RawFrames,[],'border','tight');
end