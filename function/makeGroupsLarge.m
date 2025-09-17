function groups = makeGroupsLarge(fileList, groupSize, keepRemainder)
% fileList: 文件路径 cell 数组，每个文件包含 200x200x10
% groupSize: 每组图像数量
% keepRemainder: true=保留最后不足组
% 返回: cell 数组，每个元素 200x200xgroupSize

    if nargin < 3
        keepRemainder = false;
    end

    groups = {};
    buffer = [];

    for f = 1:numel(fileList)
        % 只加载当前块
        S = load(fileList{f});        % 假设里面变量名是 'data'
        block = S.data;               % 200x200x10
        depth = size(block,3);

        for s = 1:depth
            buffer = cat(3, buffer, block(:,:,s));  %#ok<AGROW>

            if size(buffer,3) == groupSize
                groups{end+1} = buffer; %#ok<AGROW>
                buffer = [];
            end
        end
    end

    if ~isempty(buffer) && keepRemainder
        groups{end+1} = buffer;
    end
end
