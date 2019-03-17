function mSpec = melFilterBank(fft,nFFT, filterBank, nFilter)
mSpec = zeros(nFilter,1);
melMin = -20;
melMax = 20;
for i = 1:nFilter
    
    mSpec(i) = log(sum(filterBank(:,i).*fft(1:nFFT/2)));
    
    %mSpec(i) = (mSpec(i) - melMin)/(melMax - melMin);
    
end