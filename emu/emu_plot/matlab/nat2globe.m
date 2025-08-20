function glb = nat2globe(llc)
    % NAT2GLOBE  Rearrange LLC tile to global 2D image for plotting
    %
    %   glb = nat2globe(llc)
    %
    %   Input:
    %     llc - native LLC array of size (1170 x 90)
    %
    %   Output:
    %     glb - global image array of size (360 x 360)

    % Determine native tile size
    nx = size(llc, 1);        % typically 90
    nx2 = nx * 2;
    nx3 = nx * 3;
    nx4 = nx * 4;

    % Initialize output global array
    glb = zeros(nx4, nx4, class(llc));  % 360x360

    % Face 1 (top-left)
    glb(1:nx, 1:nx3) = llc(:, 1:nx3);

    % Face 2 (top-center)
    glb(nx+1:nx2, 1:nx3) = llc(:, nx3+1:2*nx3);

    % Face 3 (bottom-left)
    glb(1:nx, nx3+1:end) = rot90(llc(:, 2*nx3+1:2*nx3+nx), 1);

    % Face 4 (top-right)
    dum = zeros(nx3,nx,'single'); 
    dum(:) = llc(:, 2*nx3+nx+1:3*nx3+nx);
    glb(nx2+1:nx3, 1:nx3) =  rot90(dum,-1);

    % Face 5 (bottom-right)
    dum = zeros(nx3,nx,'single'); 
    dum(:) = llc(:, 3*nx3+nx+1:end);
    glb(nx3+1:nx4, 1:nx3) = rot90(dum,-1);

end
