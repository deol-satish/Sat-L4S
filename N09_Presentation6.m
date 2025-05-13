clear; close all hidden; clc;
%% === Parameters
E = wgs84Ellipsoid;
Re = earthRadius("m");
Param.h = 550e3;
Elem.a = Re + Param.h;
Elem.Inc = 53;
Param.NPln = 8; Param.NSat = 11;
Param.TNSats = Param.NPln * Param.NSat;
Param.sampleTime = 60;
startTime = datetime(2025,3,6,15,0,0);
stopTime  = startTime + hours(1);
%% === Satellite Scenario
sc = satelliteScenario(startTime, stopTime, Param.sampleTime);
sats = walkerDelta(sc, Elem.a, Elem.Inc, Param.TNSats, Param.NPln, 1);
set(sats, 'ShowLabel', false);
%% === Ground Stations
gs1 = groundStation(sc, "Latitude", 28, "Longitude", 10, 'Name',' ');
v  = satelliteScenarioViewer(sc);
% campos(v ,28, 10, 200e5);                   
play(sc,PlaybackSpeedMultiplier=100);
