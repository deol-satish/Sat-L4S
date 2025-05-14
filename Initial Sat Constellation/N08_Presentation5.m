clc, clear, close all
%% Step 0: Creating and plotting Earth spheroid
E = wgs84Ellipsoid; % Create an ellipsoid object representing Earth according to the World Geodetic System 1984
Re = earthRadius; %Store Earth radius into Re variable
[x_E, y_E, z_E] = ellipsoid(0,0,0,E.SemimajorAxis, E.SemimajorAxis, E.SemiminorAxis,36); % Create a surface mesh according to the elliposid object
% Image from NASA
Im = flip(imread('world.topo.bathy.200412.3x5400x2700.jpg')); % Read image overlay of Earth
ax=gca;
surf(x_E, y_E, z_E, 'EdgeColor', 'none', 'FaceColor', 'texturemap', 'CData', Im);
% surf(x_E, y_E, z_E,  'EdgeColor', 0.7*[1 1 1], 'FaceColor', 'texture','CData', Im); % Draw the Earth elliposid and apply overlay
% line([0 0],[0 0], 1.25*E.MeanRadius*[-1 1],'linewidth',2) % draw the rotational axis
% view(96,43)
% ax.CameraViewAngle=2.5;
lighting gouraud; 
camlight('right'); 
material dull
view(96,43); 
axis equal, axis off,hold on
%% Step 1: Add Orbits Around Earth
% Plotting Walker-Delta Orbits (Light Grey)
Nplanes = 8;                % Number of orbital planes
NsatsPerPlane = 11;         % Satellites per plane
alt = 550e3;                % Altitude [m]
r_orbit = Re + alt;         % Orbit radius
Inc = 53;                   % Inclination [deg]

theta = linspace(0, 2*pi, 200); % Full orbit path
orbitColor = [0.8 0.8 0.8];     % Light grey (RGB)

for p = 0:Nplanes-1
    RAAN = deg2rad(p * (360 / Nplanes)); % RAAN spacing
    % Rotation matrices
    R_inc = [1 0 0;
             0 cosd(Inc) -sind(Inc);
             0 sind(Inc)  cosd(Inc)];
    R_raan = [cos(RAAN) -sin(RAAN) 0;
              sin(RAAN)  cos(RAAN) 0;
              0           0        1];
    % Orbit path in XY plane (before rotation)
    x_orbit = r_orbit * cos(theta);
    y_orbit = r_orbit * sin(theta);
    z_orbit = zeros(size(theta));
    orbit = R_raan * R_inc * [x_orbit; y_orbit; z_orbit];
    plot3(orbit(1,:), orbit(2,:), orbit(3,:), ...
        'Color', orbitColor, 'LineWidth', 1);
end
%% Step 2: Add Satellite Markers on Each Orbit
for p = 0:Nplanes-1
    RAAN = deg2rad(p * (360 / Nplanes)); % RAAN spacing
    for s = 0:NsatsPerPlane-1
        trueAnom = deg2rad(s * (360 / NsatsPerPlane)); % evenly spaced
        % Position in XY orbital plane
        pos_orb = [r_orbit * cos(trueAnom);
                   r_orbit * sin(trueAnom);
                   0];
        % Rotation matrices
        R_inc = [1 0 0;
                 0 cosd(Inc) -sind(Inc);
                 0 sind(Inc)  cosd(Inc)];
        R_raan = [cos(RAAN) -sin(RAAN) 0;
                  sin(RAAN)  cos(RAAN) 0;
                  0           0        1];
        % Final ECI/ECEF position
        pos_final = R_raan * R_inc * pos_orb;
        % Plot the satellite point
        plot3(pos_final(1), pos_final(2), pos_final(3), ...
            'o', 'MarkerSize', 4, 'MarkerFaceColor', 'cyan', ...
            'MarkerEdgeColor', 'k');
    end
end
%% Step 3: Add a Ground Station 
gsLat = 28;       % Latitude in degrees
gsLon = 10;     % Longitude in degrees
gsAlt = 0;           % Altitude in meters (surface)
% Convert to ECEF coordinates
[xGS, yGS, zGS] = geodetic2ecef(E, gsLat, gsLon, gsAlt);
% Plot the ground station as a red triangle
scatter3(xGS, yGS, zGS, 20, 'r', 'filled', 'v');
% text(xGS, yGS, zGS + 3e5, 'Los Angeles', 'Color', 'w', ...
     % 'FontSize', 10, 'FontWeight', 'bold');
%% Step 4: Draw Cones from Selected Satellites to Ground Station
Ncones = 8;  % Number of satellites to draw cones from
satCount = 0;
for p = 0:Nplanes-1
    if satCount >= Ncones, break; end

    RAAN = deg2rad(p * (360 / Nplanes));
    for s = 0:NsatsPerPlane-1
        if satCount >= Ncones, break; end

        trueAnom = deg2rad(s * (360 / NsatsPerPlane));
        pos_orb = [r_orbit * cos(trueAnom);
                   r_orbit * sin(trueAnom);
                   0];
        % Rotate to ECEF
        R_inc = [1 0 0;
                 0 cosd(Inc) -sind(Inc);
                 0 sind(Inc)  cosd(Inc)];
        R_raan = [cos(RAAN) -sin(RAAN) 0;
                  sin(RAAN)  cos(RAAN) 0;
                  0 0 1];
        satPos = R_raan * R_inc * pos_orb;
        % Direction vector to ground station
        dir = [xGS; yGS; zGS] - satPos;
        vec = dir / norm(dir);
        % Build cone mesh (cylinder with one radius = 0)
        cone_length = 1 * norm(dir);                    % Define cone length
        cone_radius = 0.2 * Re;                         % Define cone base width
        
        [cx, cy, cz] = cylinder([0 cone_radius], 20);   % Cone shape
        cz = cz * cone_length;                          % Height scaling
        conePts = [cx(:)'; cy(:)'; cz(:)'];             % Cone points

        R = vrrotvec2mat(vrrotvec([0 0 1], vec));       % Rotation matrix
        coords = R * conePts;                           % Apply rotation
        cx_r = reshape(coords(1,:), size(cx)) + satPos(1);
        cy_r = reshape(coords(2,:), size(cy)) + satPos(2);
        cz_r = reshape(coords(3,:), size(cz)) + satPos(3);
        surf(cx_r, cy_r, cz_r, 'FaceAlpha', 0.25, ...
             'EdgeColor', 'none', 'FaceColor', 'cyan');
        satCount = satCount + 1;
    end
end
