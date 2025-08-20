function [timestep] = get_timestep(fname, fprefix)
% Extract time-step from MITgcm output file name

% Default value if not found
timestep = -999999999;

% Find the position of prefix string
pos = strfind(fname, fprefix);

if ~isempty(pos)
    % Find first dot after prefix
    dot_pos = find(fname == '.');
    if ~isempty(dot_pos)
        dot_pos = dot_pos + pos - 1;
        % Extract number after the dot
        number_string = fname(dot_pos(1)+1:dot_pos(2)-1);
        timestep = str2double(number_string);
    else
        fprintf('No dot found after prefix string.\n');
    end
else
    fprintf('Prefix string not found.\n');
end

end
