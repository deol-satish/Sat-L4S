function overlapFactor = F02_GetOverlapFactor(txFreq, txBW, intfFreq, intfBW)
    txRange = [txFreq - txBW/2, txFreq + txBW/2];
    intfRange = [intfFreq - intfBW/2, intfFreq + intfBW/2];
    overlap = max(0, min(txRange(2), intfRange(2)) - max(txRange(1), intfRange(1)));
    overlapFactor = overlap / intfBW;
end
