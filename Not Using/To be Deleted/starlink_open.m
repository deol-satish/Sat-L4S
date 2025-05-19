
%url = 'https://celestrak.org/NORAD/elements/gp.php?GROUP=STARLINK&FORMAT=tle';
%filename = 'starlink.tle';
%websave(filename, url);

%tleData_readline = readlines("starlink.tle");

tleData = tleread(filename);



% Create a satellite scenario
sc = satelliteScenario;

% Read and add the satellites to the scenario
sat = satellite(sc, tleData_readline);

% Optional: Add a ground station for reference
gs = groundStation(sc, "Latitude", -35, "Longitude", 149, "Name", "Canberra");

% Visualize the scenario
visualize(sc);
