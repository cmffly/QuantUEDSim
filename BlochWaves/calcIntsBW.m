function [Iarray,psi_G_array,hklSel,GhklSel] = calcIntsBW(theta1,theta2,nUC,...
    GxyThresh,sThresh,sDiff)
%CALCDIFFBW Calculate diffracted intensities using Bloch Wave method
%   theta1 = x component of sample tilt (rad)
%   theta2 = y component (rad)
%   GxyThresh = selection threshold on in-plane reciprocal lattice distance (inv
%   Angstroms)
%   sThresh = upper threshold on excitation error (inv Angstroms)
%   sDiff = setup struct
%   NOTE: ASSUMES CENTROSYMMETRIC CRYSTAL

% Unpack input variable structure
fieldNames = fieldnames(sDiff);
nFields = numel(fieldNames);
for iField = 1:nFields
    [~] = evalc([fieldNames{iField} ' = sDiff.' fieldNames{iField}]);
end

% Compute excitation errors (inv Angstroms)
s_G = computeExcitationError(theta1,theta2,Ghkl,lambElec); 

% Select beams within specified reciprocal space volume around 
% the Ewald sphere
Gxy = sqrt(Ghkl(:,1).^2 + Ghkl(:,2).^2);
% Gz = abs(Ghkl(:,3));
isSel = Gxy < GxyThresh ...
    & ~(U_G==0) ...
    & abs(s_G) < sThresh;
hklSel = hkl(isSel,:);
GhklSel = Ghkl(isSel,:);

%% Build and solve matrix equation
N = sum(isSel);
k0 = 1./lambElec;
k0z = k0*(-cos(theta1)*cos(theta2));

hklDiff = zeros(N,N,3);
for ii = 1:3
    hklDiff(:,:,ii) = repmat(hklSel(:,ii),[1 N])...
        -repmat(hklSel(:,ii)',[N 1]);
end

if any(hklDiff(:,:,1) > hRange(2) | hklDiff(:,:,1) < hRange(1),'all')
    disp('h out of range, need more h points')
end
if any(hklDiff(:,:,2) > kRange(2) | hklDiff(:,:,2) < kRange(1),'all')
    disp('k out of range, need more k points')
end
if any(hklDiff(:,:,3) > lRange(2) | hklDiff(:,:,3) < lRange(1),'all')
    disp('l out of range, need more l points')
end

indDiff = sub2ind([hLen,kLen,lLen],...
    hklDiff(:,:,1)-(hRange(1)-1),...
    hklDiff(:,:,2)-(kRange(1)-1),...
    hklDiff(:,:,3)-(lRange(1)-1));

A = diag(2*k0.*s_G(isSel))+U_G(indDiff).*(ones(N,N)-diag(ones(N,1)));

[Cvecs,eigvals] = eig(A);
Cvecsinv = conj(Cvecs');
% Cvecsinv = inv(Cvecs);

%% Compute exit wave components
% Initial condition (plane wave)
psiInit_G = zeros(N,1);
psiInit_G(hklSel(:,1)==0 & hklSel(:,2)==0 & hklSel(:,3)==0) = 1;

gam = eigvals/(2*k0z); % Inverse Angstroms

psi_G = @(z) Cvecs*(eye(N).*exp(2i*pi*gam*z))*Cvecsinv*psiInit_G;

dz = cellDim(3);
zTest = (1:nUC)*dz;
nZ = numel(zTest);

psi_G_array = zeros(N,nZ);

for iZ = 1:nZ
    psi_G_array(:,iZ) = psi_G(zTest(iZ));
end

Iarray = abs(psi_G_array).^2;

end

