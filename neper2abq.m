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
    materialinput=regexprep(inputfile,'__','_material.inp');
    %creating an input file for materials
    inpFile = fopen(materialinput,'wt');

   [A]=xlsread('input_file_info.xlsx','Material_parameters');
   for i=1:size(eulera,1) 
        fprintf(inpFile, '\n*Material, name=Grain_Mat%d',i);
        fprintf(inpFile, '\n*Depvar\n10000,');
        fprintf(inpFile, '\n*User Material, constants=175\n');
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(9),A(10),A(11),A(12),A(13),A(14),A(15),A(16));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(17),A(18),A(19),A(20),A(21),A(22),A(23),A(24));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(25),A(26),A(27),A(28),A(29),A(30),A(31),A(32));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(33),A(34),A(35),A(36),A(37),A(38),A(39),A(40));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(41),A(42),A(43),A(44),A(45),A(46),A(47),A(48));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(49),A(50),A(51),A(52),A(53),A(54),A(55),A(56));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', vecs1(1,1),vecs1(2,1),vecs1(3,1),rotvec1(1,1,i),rotvec1(2,1,i),rotvec1(3,1,i),A(63),A(64));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', vecs2(1,1),vecs2(2,1),vecs2(3,1),rotvec2(1,1,i),rotvec2(2,1,i),rotvec2(3,1,i),A(71),A(72));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(73),A(74),A(75),A(76),A(77),A(78),A(79),A(80));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(81),A(82),A(83),A(84),A(85),A(86),A(87),A(88));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(89),A(90),A(91),A(92),A(93),A(94),A(95),A(96));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(97),A(98),(A(99)),A(100),A(101),A(102),A(103),A(104));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(105),A(106),A(107),A(108),A(109),A(110),A(111),A(112));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(113),A(114),(A(115)),A(116),A(117),A(118),A(119),A(120));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(121),A(122),A(123),A(124),A(125),A(126),A(127),A(128));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(129),A(130),(A(131)),A(132),A(133),A(134),A(135),A(136));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(137),A(138),A(139),A(140),A(141),A(142),A(143),A(144));
        fprintf(inpFile, '%u, %u, %u, %u, %u, %u, %u, %u\n', A(145),A(146),A(147),A(148),A(149),A(150),A(151),A(152));
        fprintf(inpFile, '%u, %u, %u,  %u, %u, %u, %u, %u\n', A(153),A(154),A(155),A(156),A(157),A(158),A(159),A(160));
        fprintf(inpFile, '%u, %u,  %u, %u, %u, %u, %u, %u\n', A(161),A(162),A(163),A(164),A(165),A(166),A(167),A(168));
        fprintf(inpFile, '%u, %u,  %u, %u, %u, %u, %u\n',deg2rad(eulera(i,1)),deg2rad(eulera(i,2)),deg2rad(eulera(i,3)),centroid(i,1),centroid(i,2),centroid(i,3),diameq(i,1));
   end
   fclose(inpFile);
end