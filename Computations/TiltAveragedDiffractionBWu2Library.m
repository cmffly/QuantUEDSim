%% Compute and display tilt-averaged diffraction pattern

du2List = 0:0.001:0.015;
u2Init = 0.024;
uRMSList = sqrt((u2Init+du2List)/3);
nSims = numel(uRMSList);

nTheta = 64;
sigmaThetaMax = 0.16; % rad
sigmaThetaSamp = (sigmaThetaMax/nTheta)*(1:nTheta);

nUC = 50;
nIter1 = 8;
nIter = 9;
tArray = 0.1*sDiff.cellDim(3)*(1:nUC);

[savefile,savepath] = uiputfile('*.mat');

for iSim = 2:nSims
    options.uRMS = uRMSList(iSim);
    sDiff = setupSimBW(options);

    % Compute the first set of tilt-averaged patterns
    Ilib = computeTiltAveragedDiffraction(sigmaThetaSamp,nUC,nIter1,...
        'Bloch Waves',sDiff);
    % Further converge the smallest tilt-range patterns
    Ilib = computeTiltAveragedDiffraction(sigmaThetaSamp,nUC,nIter,...
        'Bloch Waves',sDiff,Ilib,nIter,4);

    save([savepath savefile(1:end-4) ...
        '_u' pad(num2str(iSim),2,'left','0') '.mat'],...
        'Ilib','sDiff',...
        'nTheta','sigmaThetaMax','sigmaThetaSamp',...
        'nUC','nIter','tArray');
end

%% Visualize resulting intensities and R factors

hklTest = [2 0 0;...
    2 2 0;...
    4 0 0;...
    4 2 0;...
    4 4 0;...
    6 0 0;...
    6 2 0];

nPeaks = size(hklTest,1);

peakNames = cell(nPeaks,1);
for iPeak = 1:nPeaks
    peakNames{iPeak} = strrep(num2str(hklTest(iPeak,:)),' ','');
end

GhklTest = computeScatteringVectors(hklTest,sDiff.Gvec);

IArray = zeros(nPeaks,nUC,nIter);
I0Array = zeros(1,nUC,nIter);
iTheta = 16;
for iIter = 1:nIter
    IArray(:,:,iIter) = extractIntsFromDP(Ilib(:,:,:,iTheta,iIter),...
        sDiff.qxaStore,sDiff.qyaStore,GhklTest);
    I0Array(:,:,iIter) = extractIntsFromDP(Ilib(:,:,:,iTheta,iIter),...
        sDiff.qxaStore,sDiff.qyaStore,[0 0 0]);
end

%% Plot intensity vs thickness for each peak vs iteration

showIvtVsParam(IArray,tArray,peakNames,'Iterations',1:nIter)

%% Plot intensity vs thickness for the max iteration
showIvt(IArray(:,:,end),I0Array(:,:,end),tArray,peakNames);

%% Compute and plot R for thickness bands

tBands = [0 5; 10 15; 15 20; 25 30; 35 40];
% tBands = [10 15];

RBands = computeRBands(IArray,tArray,tBands);

showRBands(RBands,tBands,1:nIter,'Iterations');


