function img_log = log_compressed(img_dsc)
    img_dsc = img_dsc/max(img_dsc,[],'all');
    img_log = 20*log10(img_dsc);
end