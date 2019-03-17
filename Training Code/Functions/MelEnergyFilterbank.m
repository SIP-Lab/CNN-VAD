classdef MelEnergyFilterbank
    
    properties
        
        freq_l
        freq_h
        nFFT
        nFilt
        fs
        filterbank
        melEnergy
        
    end
    
    methods
        
        function obj = MelEnergyFilterbank(freq_l, freq_h, nFFT, nFilt, fs)
        
            obj.freq_l  = freq_l;
            obj.freq_h  = freq_h;
            obj.nFFT    = nFFT;
            obj.nFilt   = nFilt;
            obj.fs      = fs;
            
            lowerMel = 1125 * log(1 + freq_l/700);
            higherMel = 1125 * log(1 + freq_h/700);
            melBand = linspace(lowerMel,higherMel,nFilt+2);
            freqBand = 700*(exp(melBand/1125) - 1);
            f = floor((nFFT + 1) * freqBand/fs);
            
            obj.filterbank = zeros(nFilt, nFFT/2);
            
            for m = 2:nFilt+1
                for k = 1:nFFT/2
        
                    if k > f(m-1) && k <= f(m)
                        obj.filterbank(m-1,k) = (k - f(m-1))/(f(m) - f(m-1));
                    elseif k > f(m) && k <= f(m+1)
                        obj.filterbank(m-1,k) = (f(m+1) - k)/(f(m+1) - f(m));
                    end
        
                end
            end

            obj.filterbank = obj.filterbank';
            
            obj.melEnergy  = zeros(nFilt, 1);
            
        end
        
        function [obj, melEnergy] = compute(obj, fftPower)
            
            for i = 1:obj.nFilt
                
                obj.melEnergy(i) = log(sum(obj.filterbank(:,i).*fftPower(1:obj.nFFT/2)));
                
            end
            melEnergy = obj.melEnergy;
        end
    end
    
end