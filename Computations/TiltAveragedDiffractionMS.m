%% Compute and display Multislice tilt-averaged library
% as used in D.B. Durham et al, ArXiv Preprint 2022 

sDiff = setupSimMS();

nTheta = 64;
sigmaThetaMax = 0.16; % rad
sigmaThetaSamp = (sigmaThetaMax/nTheta)*(1:nTheta);

nUC = 100;
nIter = 9;

% Compute the first set of tilt-averaged patterns
Ilib = computeTiltAveragedDiffraction(sigmaThetaSamp,nUC,nIter,sDiff);
% Further converge the smallest tilt-range patterns
Ilib = computeTiltAveragedDiffraction(sigmaThetaSamp,nUC,10,sDiff,Ilib,10,4);

tArray = 0.1*sDiff.cellDim(3)*(1:nUC);

StackViewerDiff(fftshift(fftshift(Ilib(:,:,:,end,5),1),2),tArray)

[savefile,savepath] = uiputfile('*.mat');
save([savepath savefile],'Ilib','sDiff',...
    'nTheta','sigmaThetaMax','sigmaThetaSamp',...
    'nUC','nIter','tArray');

%% Visualization
VisualizeTiltAveragedDiffraction;

