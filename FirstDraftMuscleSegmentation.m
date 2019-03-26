clearvars -except Subject
close all
clc

% This code provides a method for segmenting the muscle from a T2 weigthed
% MRI image.

%% Load

% Indset navn p� data
% load('Sorteret_MRI_data_SubjectsOnly.mat')

%% Information and show

IOrg = Subject(2).Session(1).T2(1).left(:,:,2);

figure;
subplot(3,3,1), imshow(IOrg,[])
title('Original image');

%% Intensity threshold
% Done to set the bome and skin to 0. And to enhance the edges.

I = IOrg;
I(I < 500)=0;
I(I > 2100)=0;

subplot(3,3,2), imshow(I,[])
title('Original image with intensity threshold');

%% Open and close
% Done to smooth.

B=strel('disk',7);

I = imclose(imopen(I,B),B);
subplot(3,3,3), imshow(I,[])
title('Open and Close image');

%% Edge detection
% Usign a sobel filter.

[~, threshold] = edge(I, 'canny'); % Brugte sobel f�r, men kan ikke rigtig se forskel.
fudgeFactor = .5;
BWs = edge(I,'canny', threshold * fudgeFactor);
subplot(3,3,4), imshow(BWs), title('binary gradient mask');

%% TILF�JELSE

Ithreshold = IOrg;
Ithreshold(Ithreshold > 200)=4000;
level = graythresh(Ithreshold);
Ithreshold = imbinarize(Ithreshold,level);

subplot(3,3,5), imshow(Ithreshold,[])
title('Original image with intensity threshold');

%% Fill Interior Gaps

BWdfill = imfill(Ithreshold, 'holes');
subplot(3,3,6), imshow(BWdfill,[]);
title('binary image with filled holes');

%% Remove too small objects

BWnosmall = bwareaopen(BWdfill, 200);
subplot(3,3,7), imshow(BWnosmall,[]), title('cleared off small objects');

%% Dilate

B=strel('disk',2);
BWnosmall = imdilate(BWnosmall,B);

%% Edge detection
% Usign a sobel filter.

[~, threshold] = edge(I, 'sobel');
fudgeFactor = .5;
BWs2 = edge(BWnosmall,'sobel', threshold * fudgeFactor);
subplot(3,3,8), imshow(BWs2), title('binary gradient mask');

%% Dilate the Image
% Dilate by two line (vertical and horizontal) with a size on 1.

se90 = strel('line', 4, 90);
se0 = strel('line', 4, 0);

BWsdil = imdilate(imdilate(BWs2, [se90 se0]), [se90 se0]);
subplot(3,3,9), imshow(BWsdil), title('dilated gradient mask');

%% Subtract

BWs(BWsdil==1)=0;
figure; subplot(3,3,1), imshow(BWs), title('subtract');

%% Dilate the Image TILF�JELSE STOP
% Dilate by two line (vertical and horizontal) with a size on 1.

se90 = strel('line', 4, 90);
se0 = strel('line', 4, 0);

BWsdil = imdilate(imdilate(BWs, [se90 se0]), [se90 se0]);
subplot(3,3,2), imshow(BWsdil), title('dilated gradient mask');

%% Fill Interior Gaps

BWdfill = imfill(BWsdil, 'holes');
subplot(3,3,3), imshow(BWdfill);
title('binary image with filled holes');

%% Remove Connected Objects on Border

BWnobord = imclearborder(BWdfill, 4);
subplot(3,3,4), imshow(BWnobord), title('cleared border image');

%% Smoothen the Object

seD = strel('diamond',2);
BWsmooth = imerode(BWnobord,seD);
BWsmooth = imerode(BWsmooth,seD);
subplot(3,3,5), imshow(BWsmooth), title('segmented image');

%% Remove too small objects

BWfinal = bwareaopen(BWsmooth, 5000);
subplot(3,3,6), imshow(BWfinal), title('cleared off small objects');

%% Open and close

B=strel('disk',5);

BWfinal = imclose(imopen(BWfinal,B),B);
B=strel('disk',6);   %%HER
BWfinal = imopen(BWfinal,B);
subplot(3,3,7), imshow(BWfinal,[])
title('Open and Close image');

%% Remove too small objects again

BWfinal = bwareaopen(BWfinal, 5000);
subplot(3,3,8), imshow(BWfinal,[])
title('Remove too small objects again');

%% Show outline

BWoutline = bwperim(BWfinal);
Segout = IOrg; 
Segout(BWoutline) = 3000; 
figure, imshow(Segout,[]), title('outlined original image');


%% Eksport the final section

Iexport=IOrg;
Iexport(BWfinal==0)=0;
figure, subplot(3,3,1), imshow(Iexport,[])
title('Open and Close image'); imshow(Iexport,[]), title('Eksported section');

%% Now find the bone

Iexport(I < 500)=0;
Iexport(I > 2000)=0;

subplot(3,3,2), imshow(Iexport,[])
title('Original image with intensity threshold');

%% Open and close

B=strel('disk',1);

I = imclose(imopen(Iexport,B),B);

subplot(3,3,3), imshow(I,[])
title('Open and Close image');

level = graythresh(I);

I = im2bw(I,level);
subplot(3,3,4), imshow(I,[])
title('Binary');

mask = zeros(size(I));
mask(25:end-25,25:end-25) = 1;

bw = activecontour(I,mask,300);

subplot(3,3,5), imshow(bw), title('Segmented Image')

%% Inverse

I = imcomplement(I);
subplot(3,3,6), imshow(I,[])
title('Inverse image');

I(BWfinal==0)=0;
subplot(3,3,7), imshow(I,[])
title('Remove background');

%% Remove too small objects and fill holes

BWnosmall = bwareaopen(I, 500);
BWdfill = imfill(BWnosmall, 'holes');
subplot(3,3,8), imshow(BWdfill), title('cleared off small objects');

B=strel('disk',2);
BWfinal = imdilate(BWdfill,B);

%% Mark on original image
BWoutline2 = bwperim(BWfinal);
Segout(BWoutline2) = 3000; 
figure, imshow(Segout,[]), title('outlined original image');

%% Chop the original image

Iexport(BWfinal==1)=0;
figure, imshow(Iexport,[]), title('Eksported section');

I2 = im2double(Iexport);
pic_jpg=imresize(I2,0.5,'bilinear');
imwrite(pic_jpg,'muscle.jpg','jpg')