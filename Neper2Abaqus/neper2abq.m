function neper2abq(inputfile)
%% Purpose
%Create a microstructure using Neper, with the output of the microstructure
%format as an Abaqus input file and update the Abaqus input file to include
%materials and sections for each generated grain.

%The purpose of including the volume and seed information is to calculate 
%the equivalent spherical diameter of each grain and the centroid location 
%which are used by the current UMAT to determine the location of the 
%integration point with respect to the grain boundary.

%Please note, this has only currently been created with the most current 
%UMAT in mind. I will add more functionality as I progress.

%% How to use
%Run from the command line using: neper2abq('name__') where 'name' is
%the name of the input file. Please also include the double underscore at 
%the end of the name you choose.

%Running this function will create two files:

%'name_material.inp'
%'name_sections.inp'

%% Author
%Dylan Agius
%dylan.agius@bristol.ac.uk

%%
    %import euler angles of grains
    eulera = xlsread('input_file_info.xlsx','orientations');
    %import grain information
    centroid = xlsread('input_file_info.xlsx','seed');
    %import volume for each grain
    volume = xlsread('input_file_info.xlsx','volume');

    %calculate the equivalent spherical diameter
    for i=1:size(eulera,1)
        diameq(i,1)=((6.0*volume(i))/pi)^(1/3);
    end

    %create transformation matrix
    zrot=zeros(3,3,size(eulera,1));
    xrot=zeros(3,3,size(eulera,1));
    zrot2=zeros(3,3,size(eulera,1));
    total_rot=zeros(3,3,size(eulera,1));

    for i=1:size(eulera,1)
        zrot(:,:,i)=[cosd(eulera(i,1)), sind(eulera(i,1)), 0; -sind(eulera(i,1)), cosd(eulera(i,1)),0; 0,0,1];
        xrot(:,:,i)=[1,0,0;0,cosd(eulera(i,2)),sind(eulera(i,2));0,-sind(eulera(i,2)),cosd(eulera(i,2))];  
        zrot2(:,:,i)=[cosd(eulera(i,3)),sind(eulera(i,3)),0;-sind(eulera(i,3)),cosd(eulera(i,3)),0;0,0,1];
        total_rot(:,:,i)=transpose(zrot2(:,:,i)*xrot(:,:,i)*zrot(:,:,i));
    end
 
    %vectors in the local coordinate system
    vecs1=[1;0;0];
    vecs2=[0;1;0];

    %rotating local vectors to global system using the transformation matrix
    %developed from the euler angles representing the orientation of each grain
    for i=1:size(eulera,1)
        rotvec1(:,:,i)=(total_rot(:,:,i)*vecs1);
        rotvec2(:,:,i)=(total_rot(:,:,i)*vecs2);
    end

    %creating an input file with the sections required
    %create name
    sectionsinput=regexprep(inputfile,'__','_sections.inp');

    inpFiles = fopen(sectionsinput,'wt');
    for i=1:size(eulera,1) 
        fprintf(inpFiles,'**Section: Section_Grain_Mat%d\n*Solid Section, elset=poly%d, material=Grain_Mat%d\n,\n',i,i,i);
    end
    fclose(inpFiles);  
  
    %create name
    materialinput=regexprep(inputfile,'__','_materials.inp');
    %creating an input file for materials
    inpFile = fopen(materialinput,'wt');

    [A]=xlsread('input_file_info.xlsx','Material_parameters');
    %updating the material parameters with the defined local vectors.
    A(57:59)=vecs1;
    A(65:67)=vecs2;
    for i=1:size(eulera,1) 
        fprintf(inpFile, '\n*Material, name=Grain_Mat%d',i);
        fprintf(inpFile, '\n*Depvar\n10000,');
        fprintf(inpFile, '\n*User Material, constants=175\n');
        %updating the material parameters with global vectors
        A(60:62)=rotvec1(:,:,i);
        A(68:70)=rotvec2(:,:,i);
        %adding euler angles in radians to be used in the UMAT to calculate
        %the angle of the grain with respect to the global system
        A(169:171)=deg2rad(eulera(i,:));
        %adding the centroid information in x,y,z coordinates
        A(172:174)=deg2rad(centroid(i,:));
        %adding the calculated equivalent spherical diameter for each grain
        A(175)=diameq(i,1);
        %printing this information to file
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n',A);
    
    end

   fclose(inpFile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This section is a working progress on how to add the created input files
% directly into the Neper input file.
   
%    fid = fopen('316H_centroid2.inp');
% %    line1=fgetl(fid)
% %    
% %    if isempty(regexp(line1,'*Include'))
% %     t=line1
% %    end
%    input=111111;
%     tline = fgetl(fid);
%         while ischar(tline)
%             if regexp(tline,'*Include')
%                 fprintf(fid,'%s\n',input);
%             end
%       
%         end
%    fclose(fid);
%    
%    
% %         if fid ~= -1
% %             fprintf(fid, '*Include, Input = %s',materialinput);
% %         fclose(fid);
% %         end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end