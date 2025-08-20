% ijloc.m
% MATLAB equivalent of IDL's ijloc.pro
% Returns the (i,j) index of the closest model grid point to a given lon/lat

function [ix, jy] = ijloc(xlon, ylat)

% Access EMU grid variables
global emu

% Convert to -180 to 180 for longitude
xlon = mod(xlon, 360);
if xlon > 180
    xlon = xlon - 360;
end

% Normalize latitude to [-90, 90]
ylat = mod(ylat, 360);
if ylat > 180
    ylat = 180 - ylat;
end
if ylat < -90
    ylat = -180 - ylat;
end

% Search for closest grid point
best_dist = inf;
ix = -1;
jy = -1;
d2r = pi / 180;

for j = 1:emu.ny
    for i = 1:emu.nx
        if abs(emu.yc(i,j) - ylat) < 10.0
            dumdist = sin(ylat * d2r) * sin(emu.yc(i,j) * d2r) + ...
                      cos(ylat * d2r) * cos(emu.yc(i,j) * d2r) * cos((emu.xc(i,j) - xlon) * d2r);
            dumdist = acos(min(max(dumdist, -1), 1));  % Clamp value to [-1,1] for numerical safety
            if dumdist < best_dist
                best_dist = dumdist;
                ix = i;
                jy = j;
            end
        end
    end
end

end
