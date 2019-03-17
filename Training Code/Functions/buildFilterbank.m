function filterbank = buildFilterbank(l,h,nFilt,nFFT,fs)

lowerMel = 1125 * log(1 + l/700);
higherMel = 1125 * log(1 + h/700);
melBand = linspace(lowerMel,higherMel,nFilt+2);
freqBand = 700*(exp(melBand/1125) - 1);
f = floor((nFFT + 1) * freqBand/fs);

filterbank = zeros(nFilt, nFFT/2);

for m = 2:nFilt+1
    for k = 1:nFFT/2
        
        if k > f(m-1) && k <= f(m)
            filterbank(m-1,k) = (k - f(m-1))/(f(m) - f(m-1));
        elseif k > f(m) && k <= f(m+1)
            filterbank(m-1,k) = (f(m+1) - k)/(f(m+1) - f(m));
        end
        
    end
end

filterbank = filterbank';