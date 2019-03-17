clear all
close all
clc

rng(0);

addpath('Functions/');

[data.noiseFiles, data.speechFiles, classes] = getData();

data.nSpeechFiles = numel(data.speechFiles);
data.nNoiseFiles  = numel(data.noiseFiles);
%%

classesNumerical = grp2idx(classes);

nClass = unique(classesNumerical);
nFilePerClass = numel(data.speechFiles)/numel(nClass);
selectiveNoiseFiles = [];
classLabels = [];

for i = 1:numel(nClass)
    
    idx = classesNumerical == i;
    fileClass = data.noiseFiles(idx);
    temp = fileClass(randperm(numel(fileClass), nFilePerClass));
    selectiveNoiseFiles = [selectiveNoiseFiles; temp];
    classLabels = [classLabels; i*ones(numel(temp), 1)];
end


%%

% Low Pass Parameters
filter.N   = 80;
N = 80;
filter.Fp  = 6e3;
filter.Fs  = 48e3;
filter.Rp  = 0.00057565;
filter.Rst = 1e-4;

% Calculate the Filter Coefficients, Can be used in C
filter.eqnum = firceqrip(filter.N, filter.Fp/(filter.Fs/2),...
    [filter.Rp filter.Rst], 'passedge');

%%

params.fs               = 48000;
params.fs2              = 16000;
params.overlap          = 600;
params.frameSize        = 2*params.overlap;
params.overlap_dec      = params.overlap * params.fs2/params.fs;
params.frameSize_dec    = 2*params.overlap_dec;
params.nfft             = 2^(nextpow2(params.frameSize_dec));
params.fmin             = 300;
params.fmax             = 8000;
params.n_mels           = 40;
params.maxN             = params.overlap_dec*floor(params.fs2*10/params.overlap_dec);
params.filterbank       = buildFilterbank(params.fmin, params.fmax, params.n_mels, params.nfft, params.fs2);
params.window           = hanning(params.frameSize_dec);

params.snr = 0;

%%

features.trainingIndex      = zeros(data.nSpeechFiles,2);
features.trainingIndex(:,1) = randperm(data.nNoiseFiles, data.nSpeechFiles);
features.trainingIndex(:,2) = randperm(data.nSpeechFiles);
features.trainVals          = 0.75*data.nSpeechFiles;
features.testVals           = data.nSpeechFiles - features.trainVals;

trainData = cell(features.trainVals,1);
testData  = cell(features.testVals,1);

%% Training Data
trainingIndex = features.trainingIndex;
parfor n = 1:features.trainVals
    
    noiseIdx  = trainingIndex(n,2);
    speechIdx = trainingIndex(n,2);
    
    noiseFile  = [selectiveNoiseFiles(noiseIdx).folder '\' selectiveNoiseFiles(noiseIdx).name];
    speechFile = [data.speechFiles(speechIdx).folder '\' data.speechFiles(speechIdx).name];
    
    [noiseData, fs] = audioread(noiseFile);
    noiseData = 0.5*(noiseData(:,1) + noiseData(:,2));
    noiseData = resample(noiseData, params.fs2, fs);
    
    [speechData, fs] = audioread(speechFile);
    speechData = 0.5*resample(speechData, params.fs2, fs);
    
    front = floor((numel(noiseData) - numel(speechData))/2);
    back  = ceil((numel(noiseData) - numel(speechData))/2);
    labels = [zeros(front,1); ones(numel(speechData),1); zeros(back,1)];
    speechData = [zeros(front,1); speechData; zeros(back,1)];
    
    [noisySpeech, amp_noise] = addnoise_asl_nseg(speechData, params.fs2, 16, noiseData, params.fs2, 16, params.snr);
    
    audioFrames = reshape(noisySpeech(1:params.maxN), params.overlap_dec, []);
    
%     downFrames  = zeros(size(audioFrames));
%     
%     for i = 1:size(audioFrames, 2) - 1
%     
%         frame = [audioFrames(:,i); audioFrames(:,i+1)];
% 
%         for j = 1:params.overlap
% 
%             temp = 0;
%             for k = 1:N+1            
%                 idx = params.overlap + (j - k);
%                 temp = temp + (frame(idx) * filter.eqnum(k));            
%             end
%             downFrames(j, i) = temp;
%         end
% 
%     end
% 
%     % Decimated Frames
%     decFrames = downFrames(1:3:end,:);
    
    procFrames = params.window .* [audioFrames(:,1:end-1); audioFrames(:,2:end)];
    procFFT = abs(fft(procFrames, params.nfft)).^2;
    melFeatures = zeros(params.n_mels, size(procFFT,2));
    
    for i = 1:size(procFFT, 2)
        
        melFeatures(:,i) = melFilterBank(procFFT(:,i), params.nfft,...
            params.filterbank, params.n_mels);
        
    end
    
    melLabels = double(sum(reshape(labels(1:params.maxN),...
        params.overlap_dec, [])) > params.overlap_dec/2);
    
    trainData(n) = {[melFeatures', melLabels(2:end)', ...
        n*ones(size(melLabels(2:end)))', classLabels(noiseIdx)*ones(size(melLabels(2:end)))']};
    
    runInfo = ['Train Data ' num2str(n) '/' num2str(features.trainVals)];
    disp(runInfo);
    
end

%% Testing Data

parfor n = 1:features.testVals
    
    noiseIdx  = features.trainingIndex(n + features.trainVals,2);
    speechIdx = features.trainingIndex(n + features.trainVals,2);
    
    noiseFile  = [selectiveNoiseFiles(noiseIdx).folder '\' selectiveNoiseFiles(noiseIdx).name];
    speechFile = [data.speechFiles(speechIdx).folder '\' data.speechFiles(speechIdx).name];
    
    [noiseData, fs] = audioread(noiseFile);
    noiseData = 0.5*(noiseData(:,1) + noiseData(:,2));
    noiseData = resample(noiseData, params.fs2, fs);
    
    [speechData, fs] = audioread(speechFile);
    speechData = 0.5*resample(speechData, params.fs2, fs);
    
    front = floor((numel(noiseData) - numel(speechData))/2);
    back  = ceil((numel(noiseData) - numel(speechData))/2);
    labels = [zeros(front,1); ones(numel(speechData),1); zeros(back,1)];
    speechData = [zeros(front,1); speechData; zeros(back,1)];
    
    noisySpeech = addnoise_asl_nseg(speechData, params.fs, 16, noiseData, params.fs, 16, params.snr);
    
    audioFrames = reshape(noisySpeech(1:params.maxN), params.overlap_dec, []);
    
%     downFrames  = zeros(size(audioFrames));
%     
%     for i = 1:size(audioFrames, 2) - 1
%     
%         frame = [audioFrames(:,i); audioFrames(:,i+1)];
% 
%         for j = 1:params.overlap
% 
%             temp = 0;
%             for k = 1:filter.N+1            
%                 idx = params.overlap + (j - k);
%                 temp = temp + (frame(idx) * filter.eqnum(k));            
%             end
%             downFrames(j, i) = temp;
%         end
% 
%     end
% 
%     % Decimated Frames
%     decFrames = downFrames(1:3:end,:);
    
    procFrames = params.window .* [audioFrames(:,1:end-1); audioFrames(:,2:end)];
    procFFT = abs(fft(procFrames, params.nfft)).^2;
    melFeatures = zeros(params.n_mels, size(procFFT,2));
    
    for i = 1:size(procFFT, 2)
        
        melFeatures(:,i) = melFilterBank(procFFT(:,i), params.nfft,...
            params.filterbank, params.n_mels);
        
    end
    
    melLabels = double(sum(reshape(labels(1:params.maxN),...
        params.overlap_dec, [])) > params.overlap_dec/2);
    
    testData(n) = {[melFeatures', melLabels(2:end)', ...
        n*ones(size(melLabels(2:end)))', classLabels(noiseIdx)*ones(size(melLabels(2:end)))']};
    
    runInfo = ['Test Data ' num2str(n) '/' num2str(features.testVals)];
    disp(runInfo);
    
end

filename = ['../Data/VAD_features_SNR_' num2str(params.snr) '.mat'];
save(filename,'trainData','testData');
