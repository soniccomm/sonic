classdef manual_registration < handle
    properties
        fileName
        T0
    end

    properties (Access=protected)
        H
        ms1
        ms2
        scale0
        scale
        r1
        atlas
        x0
        y0
        z0
        nx
        ny
        nz
        colorComp
        colorData
        im1
        im4
        line1x
        line1y
        line4x
        line4y
        linmap
        hlinesS
        hlinesC
        hlinesT
        resultPath
    end

    methods
        function R= manual_registration(atlas,scananatomy, resultPath,initialTransf)

            % initial rotation
            if nargin==4
                R.T0=initialTransf.M;
                R.scale0=initialTransf.scale;
                R.scale=initialTransf.scale;
            else
                R.T0=eye(3);
                R.scale0=ones(2,1);
                R.scale=ones(2,1);
            end
            R.resultPath = resultPath;
            R.fileName='Transformation'; %default name

            R.atlas=atlas;
            [R.nx,R.nz,R.ny]=size(R.atlas.Histology);
            scananatomy.Data=equalizeImages(scananatomy.Data);

            % equalize images
            tmp=interpolate2D(atlas,scananatomy);
            % stupid method to have the same size eliminate
            m=affine2d(eye(3));
            ref=imref2d([R.nx,R.nz]);
            R.ms2=imwarp(tmp.Data,m,'OutputView',ref);
            R.colorData.method='fix';
            R.colorData.cmap=hot(128);
            R.colorData.caxis=[0.1 0.8];

            R.H=guihandles(openfig('manual_registration_gui.fig'));  % load GUI figure

            R.x0=round(R.nx/2);
            R.z0=round(R.nz/2);
            R.y0=round(R.ny/2);
            if nargin==3
                R.y0 =initialTransf.Plane;
            else
                R.y0=round(R.ny/2);
            end

            % set sliders
            R.H.slider2.Min=1;
            R.H.slider2.Max=R.ny;
            R.H.slider2.Value=R.y0;
            R.H.edit2.String=num2str(R.y0);
            R.H.caxis.String=num2str(R.colorData.caxis);

            % set scale
            R.H.scaleY.String=num2str(R.scale(1));
            R.H.scaleZ.String=num2str(R.scale(2));

            R.H.colormap.String='hot';              % set defoult colormap

            % create and init images to 0 in axes
            R.im1=imagesc(zeros(R.nx,R.nz),'parent',R.H.axes1);
            R.im4=imagesc(zeros(R.nx,R.nz),'parent',R.H.axes4);


            axis(R.H.axes1,'equal','tight');
            axis(R.H.axes4,'equal','tight');


            % lines are created empty and wraw in refresh
            R.line1x= line([0,0],[0,0],'Parent',R.H.axes1,'Color',[1 1 1]);
            R.line1y= line([0,0],[0,0],'Parent',R.H.axes1,'Color',[1 1 1]);

            R.line4x= line([0,0],[0,0],'Parent',R.H.axes4,'Color',[1 1 1]);
            R.line4y= line([0,0],[0,0],'Parent',R.H.axes4,'Color',[1 1 1]);


            % set callbacks
            set(R.H.colormap,        'Callback', {@setcolormap,R});
            set(R.H.caxis,           'Callback', {@setcaxis,R});
            set(R.H.slider2,         'Callback', {@readslider, R});
            set(R.H.edit2,           'Callback', {@readvalues, R});
            set(R.H.colormap,        'Callback', {@colormap, R});
            set(R.H.caxis,           'Callback', {@coloraxis, R});
            set(R.H.scaleY,          'Callback', {@applyRescale,R});
            set(R.H.scaleZ,          'Callback', {@applyRescale,R});
            set(R.H.save,            'Callback', {@saveCall, R});
            set(R.H.comparaVascular, 'Callback', {@comparativeAtlas, R,'vascular'});
            set(R.H.comparaHistology,'Callback', {@comparativeAtlas, R,'histology'});
            set(R.H.comparaRegions,  'Callback', {@comparativeAtlas, R,'regions'});

            % other inits
            R.linmap=atlas.Lines;
            R.hlinesS=[];
            R.hlinesC=[];
            R.hlinesT=[];
            % R.Trot=eye(4);

            % start movement in the images
            R.r1=moveimage(R.H.axes4,0);
            addlistener(R.r1,'movementDone', @(src,event)moveDone(src,event,R));
            comparativeAtlas([],[],R,'histology');
            R.refresh();
        end

        % refresh all the figure.
        function  refresh(V)
            V.line1x.XData= [0,   V.nz];   V.line1x.YData=[V.x0,V.x0];
            V.line1y.XData= [V.z0,V.z0];   V.line1y.YData=[0,   V.nx];

            V.line4x.XData= [0,   V.nz];   V.line4x.YData=[V.x0,V.x0];
            V.line4y.XData= [V.z0,V.z0];   V.line4y.YData=[0,   V.nx];

            V.H.slider2.Value=V.y0;
            V.H.edit2.String=num2str(V.y0);

            % refresh lines objects
            delete(V.hlinesC);
            delete(V.hlinesT);
            delete(V.hlinesS);
            V.hlinesC=addLines(V.H.axes4,V.linmap.Cor,V.y0);

            V.im1.CData=rgbfunc(squeeze(V.ms1(:,:,V.y0)),V.colorComp);


            moveDone([],[],V);
            drawnow;
        end
    end
end

% changes the atlas to compare (vascular, histology or regions)
function comparativeAtlas(~,~,R,map)
switch map
    case 'histology'
        R.ms1=R.atlas.Histology;
        R.colorComp.method='fix';
        R.colorComp.cmap=gray(256);
        R.colorComp.caxis=[0 256];
    case 'vascular'
        R.ms1=R.atlas.Vascular;
        R.colorComp.method='auto';
        R.colorComp.cmap=gray(128);
        R.colorComp.caxis=[0 128];
    case 'regions'
        R.ms1=R.atlas.Regions;
        R.colorComp.method='index';
        R.colorComp.cmap=R.atlas.infoRegions.rgb;
        R.colorComp.caxis=[0 128];
end
R.refresh();
end

function moveDone(~,~,R)
[nz0,nx0]=size(R.ms2);
R.ms2(1)=0;

tot=build2DrotationDif(R);
m=affine2d(tot);
[nz,nx,~]=size(R.ms1);

[X,Z] = meshgrid((1:nx),(1:nz));
convert();
p=reshape(p,[nz,nx]);

R.im4.CData=rgbfunc(p,R.colorData);



    function convert()
        [Xt,Zt]=transformPointsInverse(m,X,Z);
        Xt=round(Xt-1);  Xt(Xt<0)=NaN; Xt(Xt>=nx0)=NaN;
        Zt=round(Zt-1);  Zt(Zt<0)=NaN; Zt(Zt>=nz0)=NaN;
        pos=Zt(:)+nz0*Xt(:)+1;
        pos(isnan(pos))=1;
        p=R.ms2(pos);
    end
end

% changes colormap
function colormap(h,~,R)
R.colorData.cmap=evalin('base',h.String);
R.refresh();
end

% changest coloraxis
function coloraxis(h, ~,R)
R.colorData.caxis=str2num(h.String);
R.refresh();
end

% rescale
function applyRescale(~, ~,R)
R.scale=[ str2double(get(R.H.scaleY,'String')),str2double(get(R.H.scaleZ,'String'))] ;
R.refresh();
set (R.H.figure1,'Pointer','arrow');
end


function saveCall(~,~,R)
Transf.M= build2DrotationDif(R);
Transf.size=[R.nx, R.nz];
Transf.VoxelSize=R.atlas.VoxelSize(1:2);
Transf.scale=R.scale;
Transf.Plane = R.y0;
eval( strcat('save' ,32,R.resultPath,'\',R.fileName,'.mat',32,'Transf'));


disp("Transformation 参数已保存,路径为："+R.resultPath);

end

function  setcaxis(h, ~,V)
V.caxis=str2double(h.String);
refresh(V);
end

function  setcolormap(h, ~,V)
eval(['tmp=' h.String '(128);']);
V.cmap=tmp;
refresh(V);
end

function  readslider(~, ~,V)
V.y0=round(V.H.slider2.Value);
V.refresh();
end

function  readvalues(~, ~,V)
py=round(str2double(V.H.edit2.String));
if py>1 && py<V.ny, V.y0=py; V.y0=py; end
refresh(V);
end

%
% auxiliar functions
%


function tot=build2DrotationDif(R)
tot=eye(3);
tot(1,1)=R.scale(1)/R.scale0(1);
tot(2,2)=R.scale(2)/R.scale0(2);


tmpx=R.r1.Trans;
% tmpx(1:2,1:2)=tmpx(1:2,1:2)';
% tmpx(3,1:2)=fliplr(tmpx(3,1:2));
tmp=tmpx;
tmp(1,1)=1; tot=tot*tmp;

tot=R.T0*tot;

end

% draw border lines
function h=addLines(ax,LL,ip)
L=LL{ip};
hold(ax,'on');
nb=length(L);
h=gobjects(nb,1);
for ib=1:nb
    x=L{ib};
    h(ib)=plot(ax,x(:,2),x(:,1),'w:');        % change the color trae line etc here!
end
hold(ax,'off');
end


function b=rgbfunc(a,colorstr)
[nx,ny]=size(a);
aa=double(a(:));
method=colorstr.method;
cmap=colorstr.cmap;
caxis=colorstr.caxis;
if strcmp(method,'auto')
    norm=max(aa)-min(aa);
    aa=(aa-min(aa))/norm;
    aa=uint16(round(aa(:)*(length(cmap)-1)+1));
    aa(aa==0)=1;
    b=cmap(aa,:);
    b=reshape(b,nx,ny,3);
elseif strcmp(method,'fix')
    aa=(aa-caxis(1))/(caxis(2)-caxis(1));
    aa=uint16(round(aa(:)*(length(cmap)-1)+1));
    aa(aa<1)=1;
    aa(aa>length(cmap))=length(cmap);
    b=cmap(aa,:);
    b=reshape(b,nx,ny,3);
elseif strcmp(method,'index')
    aa(aa==0)=1;
    b=cmap(abs(aa),:);
    b=reshape(b,nx,ny,3);
else
    error('mapscan unknown rgb method')
end
end


% normalize data for view
function DataNorm=equalizeImages(Data)
DataNorm=Data-min(Data(:));
DataNorm=DataNorm./max(DataNorm(:));
m=median(DataNorm(:));
comp=-2/log2(m);
DataNorm=DataNorm.^comp;
DataNorm=DataNorm-min(DataNorm(:));
DataNorm=DataNorm./max(DataNorm(:));
end



