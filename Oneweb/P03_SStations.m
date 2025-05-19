%% Create GEO and LEO ground statsions
for i = 1:size(geoCities,1)
    geoGsList{i} = groundStation(sc, geoCities{i,2}, geoCities{i,3}, 'Name', geoCities{i,1});
    geoGsList{i}.MarkerColor = [1 0 0];  % Red
end
for i = 1:size(leoCities,1)
    leoGsList{i} = groundStation(sc, leoCities{i,2}, leoCities{i,3}, 'Name', leoCities{i,1});
    leoGsList{i}.MarkerColor = [0 0 1];  % Blue
end
