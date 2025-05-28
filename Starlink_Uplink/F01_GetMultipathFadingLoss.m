function fadingLoss_dB = F01_GetMultipathFadingLoss(fadingModel, K_dB)
    switch fadingModel
        case 'None'
            fadingLoss_dB = 0;
        case 'Rayleigh'
            h = (randn + 1j*randn)/sqrt(2);  % Rayleigh fading coefficient
            fadingLoss_dB = -20 * log10(abs(h));  % dB loss
        case 'Rician'
            K = 10^(K_dB/10);
            s = sqrt(K / (K + 1));
            sigma = sqrt(1 / (2 * (K + 1)));
            h = s + sigma * (randn + 1j*randn);  % Rician fading
            fadingLoss_dB = -20 * log10(abs(h));
        otherwise
            error('Unsupported fading model');
    end
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Second Option %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function fading_dB = F01_GetMultipathFadingLoss(model, K_dB, el)
%     if el < 10  % Below 10 degrees, consider scattering dominant
%         model = 'Rayleigh';
%     end
%     switch model
%         case 'None'
%             fading_dB = 0;
%         case 'Rayleigh'
%             h = (randn + 1j*randn)/sqrt(2);
%             fading_dB = -20 * log10(abs(h));
%         case 'Rician'
%             K = 10^(K_dB/10);
%             s = sqrt(K / (K + 1));
%             sigma = sqrt(1 / (2 * (K + 1)));
%             h = s + sigma * (randn + 1j*randn);
%             fading_dB = -20 * log10(abs(h));
%         otherwise
%             error('Invalid fading model');
%     end
% end
