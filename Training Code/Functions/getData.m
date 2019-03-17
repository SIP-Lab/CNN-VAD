function [noiseFiles, speechFiles, labels] = getData()

TIMIT_path = '../../PNNC/audio/*.wav';
Noise_path = '../../DCASE2017/audio/*.wav';

speechFiles = dir(TIMIT_path);
noiseFiles  = dir(Noise_path);

%%
fid = fopen('../../DCASE2017/meta.txt');
meta = textscan(fid, '%s %s %s');
labelNames = cell(meta{1,2});
fileNames = cell(meta{1,1});
fclose(fid);




% Segregate the noise files
fid = fopen('../../DCASE2017/error.txt');
error_files = textscan(fid, '%s %f %f %s');
errorFileNames = cell(size(error_files{1,1},1),1);

for i = 1:size(error_files{1,1},1)
    errorFileNames{i} = char(strrep(error_files{1,1}(i), 'audio/',''));    
end

status = fclose(fid);

%%
names = extractfield(noiseFiles, 'name');
[~, idx] = setdiff(names, errorFileNames);
noiseFiles = noiseFiles(idx);

%%

names = extractfield(noiseFiles, 'name');
labels = cell(size(names));
for i = 1:numel(names)
    
    idx = contains(fileNames, names(i));
    labels(i) = labelNames(idx);
    
end

labels = labels';


