%% get vessel mask and region map registration
clear 
clc
myPath = 'D:\demo';
cd(myPath) % change path to demo
%% imaging data
load('example_image_tomask.mat')
% avg_img is the mean of the imaging stack
%% filter vessl
% download vesselness2d for matlabcentral
% https://www.mathworks.com/matlabcentral/fileexchange/63171-jerman-enhancement-filter
vesselness = vesselness2D(avg_img,  3:4, [1;1], 1, false);
imshow(vesselness)
% get mask
mask = imbinarize(vesselness,'adaptive','Sensitivity',0);
imshow(mask)
% save mask
% save([pathname 'mask.mat'], 'mask')

%% region map reg
% load region map (from allen mice brain atlas)
load('region_map.mat')
% ================================================
t = 0.08;% try different t 0~1 to get a mask that best fit the image
%=================================================
J_reg = im2bw(uint8(avg_img/10),t);
J = avg_img;
J(find(edge(J_reg)==1))=0;
imagesc(J)
% still not work? try roipoly (manual_trim = 1)
manual_trim = 0;
if manual_trim
    J_reg = J_reg.*roipoly;
    imagesc(J_reg)
end
% if ok
J = avg_img;
J(find(edge(J_reg)==1))=0;
imagesc(J)
% reg using J_reg
% fix aspect ratio and image size
bbox = regionprops(imclose(J_reg,strel('disk',20)), 'BoundingBox');
bbox = bbox.BoundingBox;
dx0 = bbox(3);
dy0 = bbox(4);
bbox = regionprops(imrotate(region_map>0,90), 'BoundingBox');
bbox = bbox.BoundingBox;
dx = bbox(3);
dy = bbox(4);
SC = size(imrotate(region_map>0,90)).*[dy0/dy,dx0/dx];
map_mask = imresize(imrotate(region_map>0,90),SC);
imshowpair(map_mask, J_reg)
%% registration using ants
% downlad ANTS from https://github.com/ANTsX/ANTs
path =[myPath,'\ants']
cd(path)
temp = make_ana(uint8(J_reg));
save_untouch_nii(temp,'fixed');
temp = make_ana(uint8(map_mask>0));
save_untouch_nii(temp,'moving');
% linear
system(sprintf('ANTS 2 -m CC[fixed.img,moving.img,1,8] -i 0 -o ab.nii')); 
system(sprintf('WarpImageMultiTransform 2 moving.img bwarp.img -R fixed.img abAffine.txt'));
info = hdr_read_header([path horzcat('\b','warp.hdr')]);  
region_map_t = (hdr_read_volume(info))';
J2 = avg_img;
J2(find(edge(region_map_t)>0.5)) = 0;
J2(find(edge(J_reg)==1))=max(avg_img(1:end));
imagesc(J2)

% generate region_map_t
% load([path,'region_map.mat'])
map_mask = imresize(imrotate(region_map,90),SC,'nearest');
temp = make_ana(uint8(map_mask));
save_untouch_nii(temp,'moving');
system(sprintf('WarpImageMultiTransform 2 moving.img bwarp.img -R fixed.img abAffine.txt --use-NN'));
info = hdr_read_header([path horzcat('\b','warp.hdr')]);  
region_map_t = (hdr_read_volume(info))';
imshow(avg_img,[]),hold on
contour(region_map_t)
axis off

% save region map mask
% save([pathname 'mask_map.mat'], 'region_map_t')