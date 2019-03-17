clear all
close all
clc

filename = '../Data/VAD_features_SNR_10.mat';

%Enter the path to your extracted features mat file
b = load(filename);
width = 5;

%%

trainData = cell2mat(b.trainData);
testData  = cell2mat(b.testData);

fileNumbers = unique(trainData(:,42));

init = 0;

for n = 1:numel(fileNumbers)
    
    index = trainData(:,42) == fileNumbers(n);
    melData = trainData(index, 1:40)';
    labels  = trainData(index, 41);
    class   = trainData(index, 43);
    
    beginIndex = 1:5:size(melData,2) - 39;
    endIndex = 40:5:size(melData,2);
    
    if init == 0
        
        nImagesPerFile = numel(beginIndex);
        nImagesTotal   = nImagesPerFile * numel(fileNumbers);
        trainingData   = zeros(nImagesTotal,40,40);
        trainingLabels = zeros(nImagesTotal, 2);
        trainingClass  = zeros(nImagesTotal, 1);
        sectionStart   = 0;
        init           = 1;
        
    end
   
    for i = 1:numel(beginIndex)
        
        trainingData(sectionStart + i,:,:) = melData(:, beginIndex(i):endIndex(i));
        
        if(sum(labels(beginIndex(i):endIndex(i))) > width)
            trainingLabels(sectionStart + i, :) = [0,1];
        else
            trainingLabels(sectionStart + i, :) = [1,0];
        end
        trainingClass(sectionStart + i) = class(i);
    end
    
    sectionStart = sectionStart + i;
    
end

%%

fileNumbers = unique(testData(:,42));

init = 0;

for n = 1:numel(fileNumbers)
    
    index = testData(:,42) == fileNumbers(n);
    melData = testData(index, 1:40)';
    labels  = testData(index, 41);
    class   = trainData(index, 43);
    
    beginIndex = 1:5:size(melData,2) - 39;
    endIndex = 40:5:size(melData,2);
    
    if init == 0
        
        nImagesPerFile = numel(beginIndex);
        nImagesTotal   = nImagesPerFile * numel(fileNumbers);
        testingData   = zeros(nImagesTotal,40,40);
        testingLabels = zeros(nImagesTotal, 2);
        testingClass  = zeros(nImagesTotal, 1);
        sectionStart   = 0;
        init           = 1;
        
    end
   
    for i = 1:numel(beginIndex)
        
        testingData(sectionStart + i,:,:) = melData(:, beginIndex(i):endIndex(i));
        
        if(sum(labels(beginIndex(i):endIndex(i))) > width)
            testingLabels(sectionStart + i, :) = [0,1];
        else
            testingLabels(sectionStart + i, :) = [1,0];
        end
        testingClass(sectionStart + i) = class(i);
    end
    
    sectionStart = sectionStart + i;
    
end

filename = strrep(filename, 'features', 'Training_data');

save(filename,'testingData', ...
    'testingLabels', 'trainingData', 'trainingLabels', ...
    'trainingClass', 'testingClass', '-v7.3');
disp('Done');