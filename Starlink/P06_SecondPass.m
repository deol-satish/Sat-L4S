%% Minimal Second Pass for Logging Access + Position
fprintf('Starting second pass to log positions and access...\n');
sampleIdx = 1;
for tIdx = 1:length(ts)
    t = ts(tIdx);
    sampleHasAccess = false;
    %% Check if any access exists (same logic as first pass)
    for i = 1:leoNum
        for gsIdx = 1:numel(leoGsList)
            lac = access(leoSats{i}, leoGsList{gsIdx});
            if accessStatus(lac, t)
                sampleHasAccess = true;
                break;
            end
        end
        if sampleHasAccess, break; end
    end
    

    %% If access occurred, log data
    if sampleHasAccess
        logData.Time(sampleIdx) = t;

        for i = 1:leoNum
            state = states(leoSats{i}, t, 'CoordinateFrame', 'geographic');
            logData.LEO(i).Latitude(sampleIdx) = state(1,1);
            logData.LEO(i).Longitude(sampleIdx) = mod(state(2,1), 360);

            for gsIdx = 1:numel(leoGsList)
                lac = access(leoSats{i}, leoGsList{gsIdx});
                logData.LEO(i).Access(sampleIdx, gsIdx) = accessStatus(lac, t);
            end

            
        end

        sampleIdx = sampleIdx + 1;
    end
end

fprintf('Second pass complete. %d time steps logged.\n', sampleIdx - 1);
