c LLC grid subroutines for ECCO Modeling Utilities (EMU).
c
c Subroutines and what they do
c ------------------------
c grid_info: Read metric terms defining the model grid 
c convert2gcmfaces: Convert array (compact to gcmfaces)
c convert4gcmfaces: Convert array (compact from gcmfaces)
c exch_uv_llc: Fill halos of vector gcmfaces array 
c exch_t_n_llc: Fill halos of scalar gcmfaces array
c
c convert_latlon_to_cartesian: Lat/Lon to cartesian (xyz)
c get_section_line_masks: 2D mask for a great circle 
c rotate_the_grid: Rotate model's tracer lat/lon coordinate 
c get_edge_mask: ID boundary of 0/1 mask 
c grid_interp: Interpolate tracer grid array to W- or S-grid. 
c grid_diff: Difference tracer grid array in i (W) or j (S)
c grid_interp_2d: Interpolate W- and S-grid values to tracer grid
c arc_mask: ID arc of great circle 
c 
c ============================================================
c 
      subroutine grid_info
c -----------------------------------------------------
c Read model grid information. See MITgcm manual for details. 
c 
c Output
c    -------
c    xc, yc, rc, bathy, ibathy (in common block grid)
c    rf, drf, hfacc, kmt, dxg, dyg, dvol3d, rac (in common block grid2)
c
c    xc, yc : Longitude (E) and latitude (N) of model tracer grid 
c    rc : Depth of grid (m)
c    bathy : Bathymetry (m)
c    ibathy : Inverse bathymetry (1/m)
c    rf : Depth of layer boundary (m)
c    drf : Layer thickness (m)
c    hfacc : Fractional layer thickness at tracer grid point 
c    hfacw : Fractional layer thickness of tracer grid west face 
c    hfacs : Fractional layer thickness of tracer grid south face 
c    kmt : Number of wet vertical levels of tracer grid 
c    dxg : Length of "southern" edge of tracer cell (m)
c    dyg : Length of "wetern" edge of tracer cell (m)
c    dvol3d : Volume of tracer cell (m^3)
c    rac : Horizontal area of tracer cell (m^2)
c
c -----------------------------------------------------
      external StripSpaces
c files
      character*256 f_inputdir   
      common /tool/f_inputdir
      character*256 file_in, file_out, file_dum  ! file names 
      logical f_exist

      character*256 f_setup   ! directory where tool files are 

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c model arrays
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr)
      real*4 hfacc(nx,ny,nr), hfacw(nx,ny,nr), hfacs(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, hfacw, hfacs,
     $     kmt, dxg, dyg, dvol3d, rac

c --------------
c Read model grid

cc Directory where tool files exist
c      open (50, file='tool_setup_dir')
c      read (50,'(a)') f_setup
c      close (50)

c
c      file_in = trim(f_setup) // '/emu/emu_input/XC.data'
      file_in = trim(f_inputdir) // '/emu_ref/XC.data'
      inquire (file=trim(file_in), EXIST=f_exist)
      if (.not. f_exist) then
         write (6,*) ' **** Error: model grid file = ',
     $        trim(file_in) 
         write (6,*) '**** does not exist'
         stop
      endif
      open (50, file=file_in, action='read', access='stream')
      read (50) xc
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/YC.data'
      file_in = trim(f_inputdir) // '/emu_ref/YC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) yc
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/RC.data'
      file_in = trim(f_inputdir) // '/emu_ref/RC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) rc
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/Depth.data'
      file_in = trim(f_inputdir) // '/emu_ref/Depth.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) bathy
      close (50)
      
c      file_in = trim(f_setup) // '/emu/emu_input/RF.data'
      file_in = trim(f_inputdir) // '/emu_ref/RF.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) rf   ! depth of layer boundary
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/hFacC.data'
      file_in = trim(f_inputdir) // '/emu_ref/hFacC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) hfacc
      close (50)

      file_in = trim(f_inputdir) // '/emu_ref/hFacW.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) hfacw
      close (50)

      file_in = trim(f_inputdir) // '/emu_ref/hFacS.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) hfacs
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/RAC.data'
      file_in = trim(f_inputdir) // '/emu_ref/RAC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) rac 
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/DRF.data'
      file_in = trim(f_inputdir) // '/emu_ref/DRF.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) drf
      close (50)

      file_in = trim(f_inputdir) // '/emu_ref/DXG.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) dxg
      close (50)

      file_in = trim(f_inputdir) // '/emu_ref/DYG.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) dyg
      close (50)

c Derived quantities
      kmt(:,:) = 0
      do i=1,nx
         do j=1,ny
            do k=1,nr
               if (hfacc(i,j,k).ne.0.) kmt(i,j)=k
            enddo
         enddo
      enddo

c Inverse depth
      ibathy(:,:) = 0.
      do i=1,nx
         do j=1,ny
            if (bathy(i,j).ne.0.) ibathy(i,j)=1./bathy(i,j)
         enddo
      enddo

c Volume
      dvol3d(:,:,:) = 0.
      do k=1,nr
         dvol3d(:,:,k) = rac(:,:)*hfacc(:,:,k)*drf(k)
      enddo

      return
      end subroutine grid_info
c 
c ============================================================
c 
      subroutine convert2gcmfaces(fx, u1,u2,u3,u4,u5)
c -----------------------------------------------------
c Convert compact nx*ny array to gcmfaces array
c (Reverse of convert4gcmfaces.)
c 
c Input
c    ----------
c    fx : 2D array in compact form (nx by ny)
c
c Output
c    -------
c    u1, u2 : Faces 1 and 2 (nx by 3*nx) 
c    u3 : Face 3 (nx by nx) 
c    u4, u5 : Faces 4 and 5 (*3nx by nx) 
c
c -----------------------------------------------------
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c native version 
      real*4 fx(nx,ny)

c gcmfaces version
      real*4 u1(nx,3*nx), u2(nx,3*nx), u3(nx,nx)
      real*4 u4(3*nx,nx), u5(3*nx,nx)

c ------------------------------------

      u1(:,:) = fx(:,1:3*nx)
      u2(:,:) = fx(:,3*nx+1:6*nx)
      u3(:,:) = fx(:,6*nx+1:7*nx)

      do j=1,nx
         joff = 7*nx+1
         u4(1:nx,j)        = fx(:,3*(j-1)+joff)
         u4(nx+1:2*nx,j)   = fx(:,3*(j-1)+1+joff)
         u4(2*nx+1:3*nx,j) = fx(:,3*(j-1)+2+joff)
      enddo

      do j=1,nx
         joff = 10*nx+1
         u5(1:nx,j)        = fx(:,3*(j-1)+joff)
         u5(nx+1:2*nx,j)   = fx(:,3*(j-1)+1+joff)
         u5(2*nx+1:3*nx,j) = fx(:,3*(j-1)+2+joff)
      enddo

      return
      end subroutine convert2gcmfaces 
c 
c ============================================================
c 
      subroutine convert4gcmfaces(fx, u1,u2,u3,u4,u5)
c -----------------------------------------------------
c Convert gcmfaces array to compact nx*ny array 
c (Reverse of convert2gcmfaces.)
c 
c Input
c    ----------
c    u1, u2 : Faces 1 and 2 (nx by 3*nx) 
c    u3 : Face 3 (nx by nx) 
c    u4, u5 : Faces 4 and 5 (*3nx by nx) 
c
c Output
c    -------
c    fx : 2D array in compact form (nx by ny)
c
c -----------------------------------------------------
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c native version 
      real*4 fx(nx,ny)

c gcmfaces version
      real*4 u1(nx,3*nx), u2(nx,3*nx), u3(nx,nx)
      real*4 u4(3*nx,nx), u5(3*nx,nx)

c ------------------------------------

      fx(:,1:3*nx)      = u1(:,:) 
      fx(:,3*nx+1:6*nx) = u2(:,:) 
      fx(:,6*nx+1:7*nx) = u3(:,:) 

      do j=1,nx
         joff = 7*nx+1
         fx(:,3*(j-1)+joff)   = u4(1:nx,j)        
         fx(:,3*(j-1)+1+joff) = u4(nx+1:2*nx,j)   
         fx(:,3*(j-1)+2+joff) = u4(2*nx+1:3*nx,j) 
      enddo

      do j=1,nx
         joff = 10*nx+1
         fx(:,3*(j-1)+joff)   = u5(1:nx,j)       
         fx(:,3*(j-1)+1+joff) = u5(nx+1:2*nx,j)  
         fx(:,3*(j-1)+2+joff) = u5(2*nx+1:3*nx,j)
      enddo

      return
      end subroutine convert4gcmfaces
c 
c ============================================================
c 
      subroutine exch_uv_llc(u1,u2,u3,u4,u5, v1,v2,v3,v4,v5,
     $     u1h,u2h,u3h,u4h,u5h, v1h,v2h,v3h,v4h,v5h)
c -----------------------------------------------------
c Modeled after routine in MITgcm. 
c Fill halos of vector gcmfaces array. 
c 
c Input
c    ----------
c    u1, u2, u3, u4, u5 : gcmfaces array of U-component
c    v1, v2, v3, v4, v5 : gcmfaces array of V-component
c
c Output
c    -------
c    u1h, u2h, u3h, u4h, u5h : gcmfaces array of U-component with halos 
c    v1h, v2h, v3h, v4h, v5h : gcmfaces array of V-component with halos 
c
c -----------------------------------------------------
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c gcmfaces version
      real*4 u1(nx,3*nx), u2(nx,3*nx), u3(nx,nx)
      real*4 u4(3*nx,nx), u5(3*nx,nx)

      real*4 v1(nx,3*nx), v2(nx,3*nx), v3(nx,nx)
      real*4 v4(3*nx,nx), v5(3*nx,nx)

c gcmfaces with halos 
      real*4 u1h(nx+2,3*nx+2), u2h(nx+2,3*nx+2)
      real*4 u3h(nx+2,nx+2)
      real*4 u4h(3*nx+2,nx+2), u5h(3*nx+2,nx+2)

      real*4 v1h(nx+2,3*nx+2), v2h(nx+2,3*nx+2)
      real*4 v3h(nx+2,nx+2)
      real*4 v4h(3*nx+2,nx+2), v5h(3*nx+2,nx+2)

c Temporary storage of just halos 
      real*4 u1hx(2,3*nx+2), u1hy(nx+2,2)
      real*4 u2hx(2,3*nx+2), u2hy(nx+2,2)
      real*4 u3hx(2,nx+2),   u3hy(nx+2,2)
      real*4 u4hx(2,nx+2),   u4hy(3*nx+2,2)
      real*4 u5hx(2,nx+2),   u5hy(3*nx+2,2)

      real*4 v1hx(2,3*nx+2), v1hy(nx+2,2)
      real*4 v2hx(2,3*nx+2), v2hy(nx+2,2)
      real*4 v3hx(2,nx+2),   v3hy(nx+2,2)
      real*4 v4hx(2,nx+2),   v4hy(3*nx+2,2)
      real*4 v5hx(2,nx+2),   v5hy(3*nx+2,2)

c ------------------------------------

c First exchange as scalar
      call exch_t_n_llc(u1,u2,u3,u4,u5, u1h,u2h,u3h,u4h,u5h)
      call exch_t_n_llc(v1,v2,v3,v4,v5, v1h,v2h,v3h,v4h,v5h)
      
c Temporarily save scalar halos to correct vector halos 
      u1hx(1,:) = u1h(1,:)
      u1hx(2,:) = u1h(nx+2,:)
      u1hy(:,1) = u1h(:,1)
      u1hy(:,2) = u1h(:,3*nx+2)

      u2hx(1,:) = u2h(1,:)
      u2hx(2,:) = u2h(nx+2,:)
      u2hy(:,1) = u2h(:,1)
      u2hy(:,2) = u2h(:,3*nx+2)

      u3hx(1,:) = u3h(1,:)
      u3hx(2,:) = u3h(nx+2,:)
      u3hy(:,1) = u3h(:,1)
      u3hy(:,2) = u3h(:,nx+2)

      u4hx(1,:) = u4h(1,:)
      u4hx(2,:) = u4h(3*nx+2,:)
      u4hy(:,1) = u4h(:,1)
      u4hy(:,2) = u4h(:,nx+2)

      u5hx(1,:) = u5h(1,:)
      u5hx(2,:) = u5h(3*nx+2,:)
      u5hy(:,1) = u5h(:,1)
      u5hy(:,2) = u5h(:,nx+2)
c 
      v1hx(1,:) = v1h(1,:)
      v1hx(2,:) = v1h(nx+2,:)
      v1hy(:,1) = v1h(:,1)
      v1hy(:,2) = v1h(:,3*nx+2)

      v2hx(1,:) = v2h(1,:)
      v2hx(2,:) = v2h(nx+2,:)
      v2hy(:,1) = v2h(:,1)
      v2hy(:,2) = v2h(:,3*nx+2)

      v3hx(1,:) = v3h(1,:)
      v3hx(2,:) = v3h(nx+2,:)
      v3hy(:,1) = v3h(:,1)
      v3hy(:,2) = v3h(:,nx+2)

      v4hx(1,:) = v4h(1,:)
      v4hx(2,:) = v4h(3*nx+2,:)
      v4hy(:,1) = v4h(:,1)
      v4hy(:,2) = v4h(:,nx+2)

      v5hx(1,:) = v5h(1,:)
      v5hx(2,:) = v5h(3*nx+2,:)
      v5hy(:,1) = v5h(:,1)
      v5hy(:,2) = v5h(:,nx+2)

c Correct vector halos
      u1h(1,:)      = v1hx(1,:)
      u1h(:,3*nx+2) = -v1hy(:,2)
      v1h(1,:)      = -u1hx(1,:)
      v1h(:,3*nx+2) = u1hy(:,2)

      u2h(nx+2,:) =  v2hx(2,:)
      v2h(nx+2,:) = -u2hx(2,:)

      u3h(1,:)    =  v3hx(1,:)
      v3h(1,:)    = -u3hx(1,:)
      u3h(:,nx+2) = -v3hy(:,2)
      v3h(:,nx+2) =  u3hy(:,2)

      u4h(:,1) = -v4hy(:,1)
      v4h(:,1) =  u4hy(:,1)

      u5h(1,:)    = v5hx(1,:)
      u5h(:,nx+2) = -v5hy(:,2)
      v5h(1,:)    = -u5hx(1,:)
      v5h(:,nx+2) = u5hy(:,2)

      return
      end subroutine exch_uv_llc
c 
c ============================================================
c 
      subroutine exch_t_n_llc(c1,c2,c3,c4,c5, c1h,c2h,c3h,c4h,c5h)
c -----------------------------------------------------
c Modeled after routine in MITgcm. 
c Fill halos of scalar gcmfaces array.
c 
c Input
c    ----------
c    c1, c2, c3, c4, c5 : gcmfaces array of tracer grid values 
c
c Output
c    -------
c    c1h, c2h, c3h, c4h, c5h : gcmfaces array of tracer grid with halos 
c
c -----------------------------------------------------
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c gcmfaces version
      real*4 c1(nx,3*nx), c2(nx,3*nx), c3(nx,nx)
      real*4 c4(3*nx,nx), c5(3*nx,nx)

c gcmfaces with halos 
      real*4 c1h(nx+2,3*nx+2), c2h(nx+2,3*nx+2)
      real*4 c3h(nx+2,nx+2)
      real*4 c4h(3*nx+2,nx+2), c5h(3*nx+2,nx+2)

c ------------------------------------

c First fill interior (non-halo)
      c1h(2:nx+1,2:3*nx+1) = c1(:,:)
      c2h(2:nx+1,2:3*nx+1) = c2(:,:)
      c3h(2:nx+1,2:nx+1)   = c3(:,:)
      c4h(2:3*nx+1,2:nx+1) = c4(:,:)
      c5h(2:3*nx+1,2:nx+1) = c5(:,:)

c Fill halo
      do j=1,3*nx
         c1h(1,j+1) = c5(3*nx+1-j,nx)
         c1h(nx+2,j+1) = c2(1,j)

         c2h(1,j+1) = c1(nx,j)
         c2h(nx+2,j+1) = c4(3*nx+1-j,1)

         c4h(j+1,1) = c2(nx,3*nx+1-j)
         c4h(j+1,nx+2) = c5(j,1)

         c5h(j+1,1) = c4(j,nx)
         c5h(j+1,nx+2) = c1(1,3*nx+1-j)
      enddo

      do i=1,nx
         c1h(i+1,3*nx+2) = c3(1,nx+1-i)
         c2h(i+1,3*nx+2) = c3(i,1)
         c4h(1,i+1) = c3(nx,i)
         c5h(1,i+1) = c3(nx+1-i,nx)

         c3h(1,i+1) = c1(nx+1-i,3*nx)
         c3h(i+1,1) = c2(i,3*nx)
         c3h(nx+2,i+1) = c4(1,i)
         c3h(i+1,nx+2) = c5(1,nx+1-i)
      enddo

      return
      end subroutine exch_t_n_llc
c
c ============================================================
c 
      subroutine convert_latlon_to_cartesian(lon, lat, x, y, z)
c -----------------------------------------------------
c Modeled after routine in ecco_v4_py.
c Convert latitude, longitude (degrees) to cartesian coordinates
c e.g., 
c     (  lon, lat) = ( x, y, z)
c     (   0E,  0N) = ( 1, 0, 0)
c     ( -90E,  0N) = ( 0,-1, 0)
c     (-180E,  0N) = (-1, 0, 0)
c     (  90E,  0N) = ( 0, 1, 0)
c     (   0E, 90N) = ( 0, 0, 1)
c     (   0E, 90S) = ( 0, 0,-1)
c 
c Note: conversion to cartesian differs from what is found at
c e.g. Wolfram because here lat is [-pi/2, pi/2] with 0 at equator, 
c not [0, pi], pi/2 at equator
c 
c Input
c    ----------
c    lon : longitude in degrees (-180E, 180E) 
c    lat : latitude in degrees (-90N, 90N) 
c
c Output
c    -------
c    x : x- component of cartesian coordinate
c    y : y- component of cartesian coordinate
c    z : z- component of cartesian coordinate
c
c -----------------------------------------------------

      implicit none

c Input arguments
      real*4, intent(in) :: lon, lat

c Output arguments
      real*4, intent(out) :: x, y, z

c Local variables
      real*4 :: d2r

c Conversion factor from degrees to radians
      d2r = 3.1415926 / 180.0

c Loop over all input points
      x = cos(lat*d2r) * cos(lon*d2r)
      y = cos(lat*d2r) * sin(lon*d2r)
      z = sin(lat*d2r)

      end subroutine convert_latlon_to_cartesian
c 
c ============================================================
c 
      subroutine get_section_line_masks(pt1, pt2, maskC, maskW, maskS)
c -----------------------------------------------------
c Modeled after routine in ecco_v4_py.
c Construct 2D mask for horizontal transport (maskW, maskS) across the
c great circle from pt1 to pt2.
c 
c NOTE: The W (i-velocity) and S (j-velocity) masks are signed with
c positive values going right to left looking from pt1 to pt2; values
c are either 1 or -1 along the transport section and zero otherwise. For
c positive northward transport, pt1 should be chosen west of pt2. For
c positive eastward transport, pt1 should be north of pt2. The W and S
c masks are invariant except for their sign when pt1 and pt2 are
c reversed. The C (tracer point) mask identifies the tracer points
c immediately upstream of the transport section with values of 1 and
c zero otherwise. The C mask varies when pt1 and pt2 are reversed as the
c upstream direction varies.
c
c Input
c   ----------
c   pt1, pt2 : longitude, latitude of two endpoints 
c
c Output
c   -------
c   maskC, maskW, maskS : 2D masks on C-, W-, and S- grid. 
c
c -----------------------------------------------------

      implicit none

c Input arguments
      real*4, intent(in) :: pt1(2), pt2(2)

c Output arguments
      real*4 x1, y1, z1
      real*4 x2, y2, z2
      real*4 xyz(3)
      real*4 rot_1(3,3), rot_2(3,3), rot_3(3,3), rot_0(3,3)
      real*4 theta_1, theta_2, theta_3

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

      real*4 xcr(nx,ny), ycr(nx,ny), zcr(nx,ny)
      common /rot_grid/xcr, ycr, zcr 

      real*4 maskD(nx,ny), maskC(nx,ny)
      real*4 maskS(nx,ny), maskW(nx,ny)
      real*4 xw(nx,ny), yw(nx,ny)
      real*4 xs(nx,ny), ys(nx,ny)

      integer i,j

c --------------
c Get cartesian coordinates of end points
      call convert_latlon_to_cartesian(pt1(1), pt1(2), x1, y1, z1)
      call convert_latlon_to_cartesian(pt2(1), pt2(2), x2, y2, z2)

c      print *,'pt1: ',x1,y1,z1
c      print *,'pt2: ',x2,y2,z2

c Compute rotation matrices

c 1. Rotate around x-axis to put first point at z = 0
      theta_1 = atan2(-z1, y1)
      rot_1(1,1) = 1.
      rot_1(1,2) = 0.
      rot_1(1,3) = 0.

      rot_1(2,1) = 0.
      rot_1(2,2) = cos(theta_1)
      rot_1(2,3) = -sin(theta_1)

      rot_1(3,1) = 0.
      rot_1(3,2) = sin(theta_1)
      rot_1(3,3) = cos(theta_1)

      xyz = matmul(rot_1, (/x1,y1,z1/))
      x1 = xyz(1)
      y1 = xyz(2)
      z1 = xyz(3)

      xyz = matmul(rot_1, (/x2,y2,z2/))
      x2 = xyz(1)
      y2 = xyz(2)
      z2 = xyz(3)

c      print *,'pt1: ',x1,y1,z1
c      print *,'pt2: ',x2,y2,z2

c 2. Rotate around z-axis to put first point at x = 0
      theta_2 = atan2(x1,y1)
      rot_2(1,1) = cos(theta_2)
      rot_2(1,2) = -sin(theta_2)
      rot_2(1,3) = 0.

      rot_2(2,1) = sin(theta_2)
      rot_2(2,2) = cos(theta_2)
      rot_2(2,3) = 0.

      rot_2(3,1) = 0.
      rot_2(3,2) = 0.
      rot_2(3,3) = 1.

      xyz = matmul(rot_2, (/x1,y1,z1/))
      x1 = xyz(1)
      y1 = xyz(2)
      z1 = xyz(3)

      xyz = matmul(rot_2, (/x2,y2,z2/))
      x2 = xyz(1)
      y2 = xyz(2)
      z2 = xyz(3)

c      print *,'pt1: ',x1,y1,z1
c      print *,'pt2: ',x2,y2,z2

c 3. Rotate around y-axis to put second point at z = 0
      theta_3 = atan2(-z2, -x2)
      rot_3(1,1) = cos(theta_3)
      rot_3(1,2) = 0. 
      rot_3(1,3) = sin(theta_3)

      rot_3(2,1) = 0.
      rot_3(2,2) = 1.
      rot_3(2,3) = 0.

      rot_3(3,1) = -sin(theta_3)
      rot_3(3,2) = 0.
      rot_3(3,3) = cos(theta_3)

      xyz = matmul(rot_3, (/x1,y1,z1/))
      x1 = xyz(1)
      y1 = xyz(2)
      z1 = xyz(3)

      xyz = matmul(rot_3, (/x2,y2,z2/))
      x2 = xyz(1)
      y2 = xyz(2)
      z2 = xyz(3)

c      print *,'pt1: ',x1,y1,z1
c      print *,'pt2: ',x2,y2,z2

c Now apply rotations to the grid
c and get cartesian coordinates at cell centers
      rot_0 = matmul(rot_2, rot_1)
      rot_1 = matmul(rot_3, rot_0)

      call rotate_the_grid(rot_1)

      maskD = 0.
      do i=1,nx
         do j=1,ny
            if (zcr(i,j) .gt. 0.) maskD(i,j) = 1.
         enddo
      enddo

c Interpolate for x,y to west and south edges
      call grid_interp(xcr,'X',xw)
      call grid_interp(ycr,'X',yw)
      call grid_interp(xcr,'Y',xs)
      call grid_interp(ycr,'Y',ys)

c Compute the great circle mask, covering the entire globe
      call get_edge_mask(maskD, maskC)
      call grid_diff(maskD,'X',maskW)
      call grid_diff(maskD,'Y',maskS)

c Get section of mask pt1 -> pt2 only
      call arc_mask(maskC, x1, y1, x2, y2, xcr, ycr)
      call arc_mask(maskW, x1, y1, x2, y2, xw, yw)
      call arc_mask(maskS, x1, y1, x2, y2, xs, ys)

      end subroutine get_section_line_masks
c 
c ============================================================
c 
      subroutine rotate_the_grid(rot_1)
c -----------------------------------------------------
c Modeled after routine in ecco_v4_py.
c Transform (rotate) the model grid by matrix rot_1
c 
c Input
c    ----------
c    rot_1 : 3-by-3 rotation matrix in cartesian coordinates 
c 
c Output
c    -------
c    xcr, ycr, zcr: Model grid in rotated Cartesian coordinate 
c                   returned in common block rot_grid
c 
c -----------------------------------------------------

c Rotation operator in cartesian coordinates 
      real*4 rot_1(3,3)

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c model arrays
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 xcr(nx,ny), ycr(nx,ny), zcr(nx,ny)
      common /rot_grid/xcr, ycr, zcr 

c Local variables
      real*4 :: d2r, lon, lat
      real*4 xyz(3)

c --------------
c Conversion factor from degrees to radians
      d2r = 3.1415926 / 180.0

c Loop over all input points
c (Done here rather than calling convert_latlon_to_cartesian.)
      do i=1,nx
         do j=1,ny
            lat = yc(i,j)*d2r
            lon = xc(i,j)*d2r
            xcr(i,j) = cos(lat) * cos(lon)
            ycr(i,j) = cos(lat) * sin(lon)
            zcr(i,j) = sin(lat)
         enddo
      enddo

c Rotate the grid
      do i=1,nx
         do j=1,ny
            xyz = matmul(rot_1, (/xcr(i,j),ycr(i,j),zcr(i,j)/))
            xcr(i,j) = xyz(1)
            ycr(i,j) = xyz(2)
            zcr(i,j) = xyz(3)
         enddo
      enddo

      end subroutine rotate_the_grid
c 
c ============================================================
c 
      subroutine get_edge_mask(maskC, maskCedge)
c -----------------------------------------------------
c Modeled after routine in ecco_v4_py.
c Get the edge of maskC defined as being 0 with neighboring 1
c
c Input
c    ----------
c    maskC : 2D array with values of 0 and 1 
c 
c Output
c    -------
c    maskCedge : 2D array with values of 1 where maskC is 0 neighboring
c                1, and 0 otherwise.
c                
c -----------------------------------------------------

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      
      real*4 maskC(nx,ny)
      real*4 maskX(nx,ny), maskY(nx,ny)
      real*4 maskXc(nx,ny), maskYc(nx,ny)
      real*4 maskCedge(nx,ny)

c Interpolate to West and South cell edges.
      call grid_interp(maskC,'X',maskX)
      call grid_interp(maskC,'Y',maskY)

c Interpolate back to cell center
      call grid_interp_2d(maskX,maskY,maskXc,maskYc)

c Anywhere maskXc and/or maskYc is nonzero and
c maskC is zero is the boundary
      maskCedge = 0.
      do i=1,nx
         do j=1,ny
            if (maskC(i,j).eq.0 .and.
     $           (maskXc(i,j)+maskYc(i,j)).gt.0.) 
     $           maskCedge(i,j)=1.
         enddo
      enddo

      end subroutine get_edge_mask
c 
c ============================================================
c 
      subroutine grid_interp(ain,drct,aout)
c -----------------------------------------------------
c Modeled after routine in ecco_v4_py.
c Average ("interpolate") C-grid array ain to W-grid (drct='X') 
c or S-grid (drct='Y'). 
c 
c Input
c    ----------
c    ain : 2D array 
c    drct : character*1 that's either 'X/x' or 'Y/y'
c 
c Output
c    -------
c    aout : 2D array of average values on W-grid (when drct='x' 
c           or 'X') or S-grid (otherwise).
c
c -----------------------------------------------------

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      
      real*4 ain(nx,ny)
      real*4 aout(nx,ny)      
      character*1 drct

c gcmfaces version
      real*4 u1(nx,3*nx), u2(nx,3*nx), u3(nx,nx)
      real*4 u4(3*nx,nx), u5(3*nx,nx)

c gcmfaces with halos 
      real*4 u1h(nx+2,3*nx+2), u2h(nx+2,3*nx+2)
      real*4 u3h(nx+2,nx+2)
      real*4 u4h(3*nx+2,nx+2), u5h(3*nx+2,nx+2)
c -----------------
      call convert2gcmfaces(ain, u1,u2,u3,u4,u5)
      call exch_t_n_llc(u1,u2,u3,u4,u5, u1h,u2h,u3h,u4h,u5h)

      if (drct.eq.'x' .or. drct.eq.'X') then 
c interpolate to W
         do j=1,3*nx
            do i=1,nx
               u1(i,j) = 0.5*(u1h(i,j+1)+u1h(i+1,j+1))
               u2(i,j) = 0.5*(u2h(i,j+1)+u2h(i+1,j+1))
            enddo
         enddo

         do j=1,nx
            do i=1,nx
               u3(i,j) = 0.5*(u3h(i,j+1)+u3h(i+1,j+1))
            enddo
         enddo

         do j=1,nx
            do i=1,3*nx
               u4(i,j) = 0.5*(u4h(i,j+1)+u4h(i+1,j+1))
               u5(i,j) = 0.5*(u5h(i,j+1)+u5h(i+1,j+1))
            enddo
         enddo
      else
c interpolate to S
         do i=1,nx
            do j=1,3*nx
               u1(i,j) = 0.5*(u1h(i+1,j)+u1h(i+1,j+1))
               u2(i,j) = 0.5*(u2h(i+1,j)+u2h(i+1,j+1))
            enddo
         enddo

         do i=1,nx
            do j=1,nx
               u3(i,j) = 0.5*(u3h(i+1,j)+u3h(i+1,j+1))
            enddo
         enddo

         do i=1,3*nx
            do j=1,nx
               u4(i,j) = 0.5*(u4h(i+1,j)+u4h(i+1,j+1))
               u5(i,j) = 0.5*(u5h(i+1,j)+u5h(i+1,j+1))
            enddo
         enddo
      endif

      call convert4gcmfaces(aout, u1,u2,u3,u4,u5)

      end subroutine grid_interp
c 
c ============================================================
c 
      subroutine grid_diff(ain,drct,aout)
c -----------------------------------------------------
c Modeled after routine in ecco_v4_py.
c Difference C-grid array ain to W (drct='X') or S (drct='Y')
c 
c Input
c    ----------
c    ain : 2D array 
c    drct : character*1 that's either 'X/x' or 'Y/y'
c 
c Output
c    -------
c    aout : 2D array of difference values on W-grid (when drct='x' 
c           or 'X') or S-grid (otherwise).
c
c -----------------------------------------------------

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      
      real*4 ain(nx,ny)
      real*4 aout(nx,ny)      
      character*1 drct

c gcmfaces version
      real*4 u1(nx,3*nx), u2(nx,3*nx), u3(nx,nx)
      real*4 u4(3*nx,nx), u5(3*nx,nx)

c gcmfaces with halos 
      real*4 u1h(nx+2,3*nx+2), u2h(nx+2,3*nx+2)
      real*4 u3h(nx+2,nx+2)
      real*4 u4h(3*nx+2,nx+2), u5h(3*nx+2,nx+2)
c -----------------
      call convert2gcmfaces(ain, u1,u2,u3,u4,u5)
      call exch_t_n_llc(u1,u2,u3,u4,u5, u1h,u2h,u3h,u4h,u5h)

      if (drct.eq.'x' .or. drct.eq.'X') then 
c interpolate to W
         do j=1,3*nx
            do i=1,nx
               u1(i,j) = u1h(i+1,j+1)-u1h(i,j+1)
               u2(i,j) = u2h(i+1,j+1)-u2h(i,j+1)
            enddo
         enddo

         do j=1,nx
            do i=1,nx
               u3(i,j) = u3h(i+1,j+1)-u3h(i,j+1)
            enddo
         enddo

         do j=1,nx
            do i=1,3*nx
               u4(i,j) = u4h(i+1,j+1)-u4h(i,j+1)
               u5(i,j) = u5h(i+1,j+1)-u5h(i,j+1)
            enddo
         enddo
      else
c interpolate to S
         do i=1,nx
            do j=1,3*nx
               u1(i,j) = u1h(i+1,j+1)-u1h(i+1,j)
               u2(i,j) = u2h(i+1,j+1)-u2h(i+1,j)
            enddo
         enddo

         do i=1,nx
            do j=1,nx
               u3(i,j) = u3h(i+1,j+1)-u3h(i+1,j)
            enddo
         enddo

         do i=1,3*nx
            do j=1,nx
               u4(i,j) = u4h(i+1,j+1)-u4h(i+1,j)
               u5(i,j) = u5h(i+1,j+1)-u5h(i+1,j)
            enddo
         enddo
      endif

      call convert4gcmfaces(aout, u1,u2,u3,u4,u5)

      end subroutine grid_diff
c 
c ============================================================
c 
      subroutine grid_interp_2d(ainX,ainY,aoutX,aoutY)
c -----------------------------------------------------
c Modeled after routine in ecco_v4_py.
c Average (interpolate) W-grid (ainX) and S-grid (ainY) values 
c to C-grid (aoutX, aoutY)
c 
c Input
c    ----------
c    ainX : 2D array on W-grid 
c    ainY : 2D array on S-grid 
c 
c Output
c    -------
c    aoutX : 2D array of averaging ainX onto C-grid
c    aoutY : 2D array of averaging ainY onto C-grid
c
c -----------------------------------------------------

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      
      real*4 ainX(nx,ny), ainY(nx,ny)
      real*4 aoutX(nx,ny), aoutY(nx,ny)
      character*1 drct

c gcmfaces version
      real*4 u1(nx,3*nx), u2(nx,3*nx), u3(nx,nx)
      real*4 u4(3*nx,nx), u5(3*nx,nx)

      real*4 v1(nx,3*nx), v2(nx,3*nx), v3(nx,nx)
      real*4 v4(3*nx,nx), v5(3*nx,nx)

c gcmfaces with halos 
      real*4 u1h(nx+2,3*nx+2), u2h(nx+2,3*nx+2)
      real*4 u3h(nx+2,nx+2)
      real*4 u4h(3*nx+2,nx+2), u5h(3*nx+2,nx+2)

      real*4 v1h(nx+2,3*nx+2), v2h(nx+2,3*nx+2)
      real*4 v3h(nx+2,nx+2)
      real*4 v4h(3*nx+2,nx+2), v5h(3*nx+2,nx+2)

c -----------------
      call convert2gcmfaces(ainX, u1,u2,u3,u4,u5)
      call convert2gcmfaces(ainY, v1,v2,v3,v4,v5)
      call exch_uv_llc(u1,u2,u3,u4,u5, v1,v2,v3,v4,v5,
     $     u1h,u2h,u3h,u4h,u5h, v1h,v2h,v3h,v4h,v5h)

c interpolate W to C 
      do j=1,3*nx
         do i=1,nx
            u1(i,j) = 0.5*(u1h(i+1,j+1)+u1h(i+2,j+1))
            u2(i,j) = 0.5*(u2h(i+1,j+1)+u2h(i+2,j+1))
         enddo
      enddo

      do j=1,nx
         do i=1,nx
            u3(i,j) = 0.5*(u3h(i+1,j+1)+u3h(i+2,j+1))
         enddo
      enddo

      do j=1,nx
         do i=1,3*nx
            u4(i,j) = 0.5*(u4h(i+1,j+1)+u4h(i+2,j+1))
            u5(i,j) = 0.5*(u5h(i+1,j+1)+u5h(i+2,j+1))
         enddo
      enddo

c     interpolate S TO C
      do i=1,nx
         do j=1,3*nx
            v1(i,j) = 0.5*(v1h(i+1,j+1)+v1h(i+1,j+2))
            v2(i,j) = 0.5*(v2h(i+1,j+1)+v2h(i+1,j+2))
         enddo
      enddo

      do i=1,nx
         do j=1,nx
            v3(i,j) = 0.5*(v3h(i+1,j+1)+v3h(i+1,j+2))
         enddo
      enddo

      do i=1,3*nx
         do j=1,nx
            v4(i,j) = 0.5*(v4h(i+1,j+1)+v4h(i+1,j+2))
            v5(i,j) = 0.5*(v5h(i+1,j+1)+v5h(i+1,j+2))
         enddo
      enddo

      call convert4gcmfaces(aoutX, u1,u2,u3,u4,u5)
      call convert4gcmfaces(aoutY, v1,v2,v3,v4,v5)

      end subroutine grid_interp_2d
c 
c ============================================================
c 
      subroutine arc_mask(mask, x1, y1, x2, y2, xg, yg)
c -----------------------------------------------------
c Modeled after routine in ecco_v4_py 
c (calc_section_along_full_arc_mask). 
c 
c Identify the arc of the great circle between point 1 and point 2 
c from a 2D mask representing this circle along with rotated 
c Cartesian coordinates that places the circle on the equator (z=0).
c
c Input 
c   ----------
c    mask : 2D mask representing the great circle 
c    x1,y1,x2,y2 : Rotated Cartesian coordinates of point 1 and 
c                  point 2. Note that z1 = z2 = 0 on the equator. 
c    xg, yg : Rotated Cartesian coordinates of the model's 
c             horizontal grid (2D array) 
c
c Ouptut
c   -------
c    mask : 2D mask retaining values from point 1 to point 2.
c 
c -----------------------------------------------------

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

      real*4 mask(nx,ny)
      real*4 x1,y1,x2,y2
      real*4 xg(nx,ny), yg(nx,ny)

      real*4 theta_1, theta_2
      real*4 theta_g(nx,ny)

      real*4 pi

c -----------------

      pi = 3.1415926

      theta_1 = atan2(y1,x1)
      theta_2 = atan2(y2,x2)

      do i=1,nx
         do j=1,ny
            theta_g(i,j) = atan2(yg(i,j),xg(i,j))
         enddo
      enddo

      if (theta_2 .lt. 0) then 
         do i=1,nx
            do j=1,ny
               if (theta_g(i,j) .le. theta_2)
     $              theta_g(i,j) = theta_g(i,j) + 2*pi
            enddo
         enddo
         theta_2 = theta_2 + 2*pi
      endif

      if (theta_2 - theta_1 .le. pi) then 
         do i=1,nx
            do j=1,ny
               if (theta_g(i,j).gt.theta_2 .or.
     $              theta_g(i,j).lt.theta_1) mask(i,j)=0.
            enddo
         enddo
      else
         do i=1,nx
            do j=1,ny
               if (theta_g(i,j).le.theta_2 .and.
     $              theta_g(i,j).ge.theta_1) mask(i,j)=0.
            enddo
         enddo
      endif

      end subroutine arc_mask
      




