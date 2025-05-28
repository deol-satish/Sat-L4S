%% P02_GStations
%% Ground Stations in Australia
fprintf('Setting up ground stations in Australia...\n');
geoCities = {
    'Sydney',       -33.8688, 151.2093;
    'Melbourne',    -37.8136, 144.9631;
};
leoCities = {
    'Sydney',       -33.8688, 151.2093;
    'Melbourne',    -37.8136, 144.9631;
};
geoGsList = cell(1, size(geoCities, 1));
leoGsList = cell(1, size(leoCities, 1));