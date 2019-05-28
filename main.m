function [ eq_string ] = main( fileName, showFigs, outputName )

%% Load Template Character Template Data and Identity Info
load('./Character_Palette/red_charPalette_withText_demo2.mat');
load('./Character_Palette/red_charPalette_Classifier_demo2.mat');

%% Read in desired equation
dir = strcat(pwd,'/Equations/Images/');
eq = imread(strcat(dir, fileName));
figure(1);
imshow(eq);

%% Optimize page and binarize
%% Done by python script
dir_opt = strcat(pwd, '/Equations/Cleaned/');
eq_opt = imread(strcat(dir_opt,fileName));
eq_opt = im2bw(eq_opt);
    
figure(3);
imshow(eq_opt);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Segment Characters and match them to database

eq_chars = ocr(eq_opt, X_orig, chars);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Pass struct of segmented characters (eq_chars) with matched character 
% data to equation creator

EqStruct.characters = eq_chars;
eq_string = fn_assemble_eq(EqStruct);

end

