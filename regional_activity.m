% calculating regional activity for fig1

% Dependencies:
% mask and region_map_t are generated by: mask_and_register.mat

% load DAT data
clear;clc
myPath = 'D:\demo';
cd(myPath)
rawData = [];
allFileName = dir(fullfile(myPath, '*.dat'));
for i = 1:size(allFileName,1)
    fn = fullfile(myPath,allFileName(i).name);
    matdata = DAT2mat_x(fn);
    rawData = cat(3, rawData, matdata);
    clear matdata
end
msg = 'loaded all imaging data'

% df/f
avg_img = squeeze(mean(rawData,3));
df = double(rawData);
for i = 1:size(rawData,3)
    df(:,:,i) = (double(squeeze(df(:,:,i)))-avg_img)./avg_img;
end

% gsr
frames = reshape(df,[size(df,1)*size(df,2),size(df,3)]);
frames = frames';
mean_g = mean(frames, 2);
g_plus = squeeze(pinv(mean_g));
beta_g = g_plus * frames;
global_signal = mean_g * beta_g;
df470gsr = frames - global_signal;
df_gsr = reshape(df470gsr',[size(df,1) size(df,2) size(df,3)]);
clear df470gsr global_signal beta_g frames

% mask
load('mask.mat')
load('mask_map.mat')
temp = repmat(~mask,[1 1 size(df,3)]);
df_gsr = df_gsr.*temp;

%% regional activity
RA = [];
map_idx = unique(region_map_t);
for i = 1:10
    region_mask = (region_map_t) == map_idx(i+1);
    sc = sum(region_mask(1:end))/length(region_mask(1:end));
    region_mask = repmat(region_mask,[1 1 size(df,3)]);
    df2 = df_gsr.*region_mask;
    df2 = reshape(df2, [size(df2,1)*size(df2,2) size(df2,3)]);
    RA(i, :) = mean(df2,1)/sc;
    i
end
% normalize
RA = zscore(RA');

