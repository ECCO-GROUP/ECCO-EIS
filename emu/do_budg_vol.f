c Program to compute budget. (OBSOLETE)
c 
c This version (do_budg_vol.f) computes the budget (the right-hand-side)
c by evaluating convergence of fluxes at each model grid point and then
c summing them up througout the target volume. This computation
c corresponds to the volume integral in Gauss's theorem.
c 
c The preferred alternate version (do_budg.f) computes the budget by
c summing converging fluxes along the target volume's boundary. In
c addition to the individual global sum of these terms, this version
c also outputs these boundary fluxes themselves. This version of the
c budget is preferred as it allows analyses of where fluxes dictating
c the budget enter the target volume, disregarding redistribution within
c the volume. This computation corresponds to the surface integral in
c Gauss's theorem.
c
c
      program do_budg
c -----------------------------------------------------
c Program for Budget Tool (V4r4)
c Collect model output based on data.ecco set up by budg.f. 
c Modeled after f17_e_2.pro 
c     
c 02 August 2023, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces
c files
      character*256 f_inputdir   ! directory where tool files are 
      common /tool/f_inputdir
      character*256 file_in, file_out, file_dum, fvar  ! file names 
c
      character*256 f_command

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c model arrays
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr), hfacc(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, kmt, dxg, dyg, dvol3d, rac

c Strings for naming output directory
      character*256 dir_out   ! output directory

c Common variables for all budgets
      parameter(nmonths=312, nyrs=26, yr1=1992, d2s=86400.)
     $                          ! max number of months of V4r4

      real*4 dum2d(nx,ny)
      real*4 etan(nx,ny,nmonths)
      real*4 dt(nmonths)
      common /budg_1/dt, etan

c --------------
c Set directory where external tool files exist
      call getarg(1,f_inputdir)
      write(6,*) 'inputdir read : ',trim(f_inputdir)

c --------------
c Get model grid info
      call grid_info

c --------------
c Set time (length of each month in seconds.)
      idum = 0
      do iyr=1,nyrs 
         iy = yr1 + iyr - 1
         do im=1,12
            if (im .ne. 12) then 
               nday = julian(1,im+1,iy)-julian(1,im,iy)
            else
               nday = julian(1,1,iy+1)-julian(1,im,iy)
            endif
            idum = idum + 1
            dt(idum) = nday*d2s
         enddo
      enddo

c --------------
c Read ETAN (snapshot sea level ETAN) 
      fvar = 'ETAN_mon_inst'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'

      call file_search(file_in, file_out, nfiles)
      if (nfiles+1 .ne. nmonths) then
         write(6,*) 'nfiles+1 ne nmonths: ',nfiles,nmonths
         stop
      endif
      
      open (52, file=file_out, action='read')

      do i=2,nfiles+1
         read(52,"(a)") file_dum
         open (53, file=file_dum, action='read', access='stream')
         read (53) dum2d
         etan(:,:,i) = dum2d
         close(53)
      enddo

      close(52)
      etan(:,:,1) = etan(:,:,2)
         
c --------------
c Collect model fluxes 
      call budg_objf

      stop
      end
c 
c ============================================================
c 
      function julian(nj, nm, na)
c Count julian day starting from 1/1/1950
      integer(8) m(12)
      integer(8) iy, ia
      integer nj, nm, na

      m(:) = [-1,31,28,31,30,31,30,31,31,30,31,30] 

      iy = na - 1948
      ia = (iy-1)/4
      julian = ia + 365*iy-730
      do n=1,nm
         julian = julian + m(n)
      enddo

      if (nm.le.2) then
         julian = julian + nj
         return
      endif

      jy = na/4
      ix = na-jy*4
      if (ix.ne.0) then
         julian = julian + nj
         return
      endif
      julian = julian + 1
      julian = julian + nj

      return
      end

c 
c ============================================================
c 
      subroutine grid_info
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

      real*4 rf(nr), drf(nr), hfacc(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, kmt, dxg, dyg, dvol3d, rac

c --------------
c Read model grid

cc Directory where tool files exist
c      open (50, file='tool_setup_dir')
c      read (50,'(a)') f_setup
c      close (50)

c
c      file_in = trim(f_setup) // '/emu/emu_input/XC.data'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/XC.data'
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
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/YC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) yc
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/RC.data'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/RC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) rc
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/Depth.data'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/Depth.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) bathy
      close (50)
      
c      file_in = trim(f_setup) // '/emu/emu_input/RF.data'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/RF.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) rf   ! depth of layer boundary
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/hFacC.data'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/hFacC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) hfacc
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/RAC.data'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/RAC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) rac 
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/DRF.data'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/DRF.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) drf
      close (50)

      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/DXG.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) dxg
      close (50)

      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/DYG.data'
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
      end
c 
c ============================================================
c 
      subroutine budg_objf
c Compute OBJF budget per data.ecco by budg.f

      character*256 f_inputdir   ! directory where tool files are 
      common /tool/f_inputdir

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c     Number of Generic Cost terms:
c     =============================
      INTEGER NGENCOST
      PARAMETER ( NGENCOST=40 )


      INTEGER MAX_LEN_FNAM
      PARAMETER ( MAX_LEN_FNAM = 512 )

      character*(MAX_LEN_FNAM) gencost_name(NGENCOST)
      character*(MAX_LEN_FNAM) gencost_barfile(NGENCOST)
      character*(5)            gencost_avgperiod(NGENCOST)
      character*(MAX_LEN_FNAM) gencost_mask(NGENCOST)
      real*4                   mult_gencost(NGENCOST)
      LOGICAL gencost_msk_is3d(NGENCOST)

      namelist /ecco_gencost_nml/
     &         gencost_barfile,
     &         gencost_name,
     &         gencost_mask,      
     &         gencost_avgperiod,
     &         gencost_msk_is3d,
     &         mult_gencost

c 
      integer nobjf, iobjf
      character*256 fmask

      real*4 wgt3d(nx,ny,nr)

c ------------------
c Read in OBJF definition from data.ecco

c Set ecco_gencost_nml default
      do i=1,NGENCOST
         gencost_name(i) = 'gencost'
         gencost_barfile(i) = ' '
         gencost_avgperiod(i) = ' '
         gencost_mask(i) = ' '
         gencost_msk_is3d(i) = .FALSE. 
         mult_gencost(i) = 0.
      enddo
         
      open(70,file='data.ecco')
      read(70,nml=ecco_gencost_nml)
      close(70)

      nobjf = 0
      do i=1,NGENCOST
         if (gencost_name(i) .eq. 'boxmean') nobjf = nobjf + 1
      enddo

      if (nobjf .ne. 1) then
         write(6,*) 'data.ecco does not conform to budget tool.'
         write(6,*) 'Aborting do_budg.f ... '
         stop
      endif

c ------------------
c Read in model output 

c Monthly state 
      if (trim(gencost_avgperiod(1)).eq.'month') then 

      write(6,"(a,/)") 'Budget MONTHLY means ... '

c read mask 
      iobjf = 1
      fmask = trim(gencost_mask(iobjf)) // 'C'
      call chk_mask3d(fmask,nx,ny,nr,wgt3d)

c do particular budget       
      if (gencost_barfile(iobjf).eq.'m_boxmean_VOLUME') then 
         call budg_vol(wgt3d)

      else if (gencost_barfile(iobjf).eq.'m_boxmean_HEAT') then 
         call budg_heat(wgt3d)

      else if (gencost_barfile(iobjf).eq.'m_boxmean_SALT') then 
         call budg_salt(wgt3d)

      else if (gencost_barfile(iobjf).eq.'m_boxmean_SALINITY') then 
         call budg_salinity(wgt3d)
         
      else if (gencost_barfile(iobjf).eq.'m_boxmean_MOMENTUM') then 
         write(6,*) 'Momentum budget not yet implemented ... '
         
      else
         write(6,*) 'This should not happen ... '
         stop
      endif
            
c Incorrect average specified
      else
         write(6,*) 'This should not happen ... Aborting'
         write(6,*) 'avgperiod = ',trim(gencost_avgperiod(1))
         stop
      endif

      return 
      end subroutine 
c 
c ============================================================
c 
      subroutine budg_vol(wgt3d)
      integer nx, ny, nr
      parameter(nx=90, ny=1170, nr=50)
      parameter(nmonths=312, nyrs=26, yr1=1992, d2s=86400.)
     $                          ! max number of months of V4r4

c Mask  
      real*4 wgt3d(nx,ny,nr)

c model arrays
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr), hfacc(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, kmt, dxg, dyg, dvol3d, rac

c Common variables for all budgets
      real*4 etan(nx,ny,nmonths)
      real*4 dt(nmonths)
      common /budg_1/dt, etan

c Temporarly variables 
      real*4 dum2d(nx,ny), dum3d(nx,ny,nr)
      real*4 conv2d(nx,ny), dum3dy(nx,ny,nr)
      real*4 theta(nx,ny,nr,2)
      integer iold, inew 

      real*4 s0(nx,ny), s1(nx,ny)
      real*4 qfac(2,nr)
      character*256 f_file 
      character*256 f_command 

c Budget arrays 
      real*4 lhs(nmonths)
      real*4 advh(nmonths), advv(nmonths)
      real*4 mixh(nmonths), mixv(nmonths)
      real*4 mixv_i(nmonths), mixv_e(nmonths)
      real*4 vfrc(nmonths), geo(nmonths)

c Time-integrated budget arrays
      real*4 lhs2(nmonths)
      real*4 advh2(nmonths), advv2(nmonths)
      real*4 mixh2(nmonths), mixv2(nmonths)
      real*4 vfrc2(nmonths), geo2(nmonths)

c files
      character*256 f_inputdir   ! directory where tool files are 
      common /tool/f_inputdir
      character*256 file_in, file_out, file_dum, fvar  ! file names 

c ------------------------------------
c Constants
      rho0 = 1029.   ! reference density 

c ------------------------------------
c Compute LHS (volume tendency)

      lhs(:) = 0.
      do im=1,nmonths-1
         dum2d(:,:) = (etan(:,:,im+1)-etan(:,:,im))/dt(im)*ibathy(:,:)
         do i=1,nx
            do j=1,ny
               do k=1,nr
                  lhs(im) = lhs(im) +
     $                 dum2d(i,j)*wgt3d(i,j,k)*dvol3d(i,j,k)
               enddo
            enddo
         enddo
      enddo

c ------------------------------------
c Compute RHS tendencies 

c ------------------------------------
c Horizontal Advection 

c ID horizontal advection files 
      fvar = 'UVELMASS_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar)
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')

      fvar = 'VVELMASS_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files_y'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (52, file=trim(file_out), action='read')

      advh(:) = 0.
      do im=1,nmonths
c Read horizontal advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)
         do k=1,nr
            dum3d(:,:,k) = dum3d(:,:,k)*dyg(:,:)
         enddo

         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3dy
         close(53)
         do k=1,nr
            dum3dy(:,:,k) = dum3dy(:,:,k)*dxg(:,:)
         enddo

c Compute convergence of horizontal advection 
         dum2d(:,:) = 0.
         do k=1,nr
            call native_uv_conv_smpl(dum3d(:,:,k),dum3dy(:,:,k), 
     $           conv2d)
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*conv2d(:,:)*drf(k)
         enddo

         do i=1,nx
            do j=1,ny
               advh(im) = advh(im) + dum2d(i,j)
            enddo
         enddo

      enddo

      close(51)
      close(52)

c ------------------------------------
c Vertical Advection 

c ID vertical advection files
      fvar = 'WVELMASS_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif

      open (51, file=trim(file_out), action='read')

      advv(:) = 0.
      do im=1,nmonths
c Read vertical advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

c Compute convergence of vertical advection 
         dum2d(:,:) = 0.
         k=1
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*dum3d(:,:,k+1)
         do k=2,nr-1
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*(dum3d(:,:,k+1)-dum3d(:,:,k))
         enddo
         k=nr
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*(-dum3d(:,:,k))

         dum2d(:,:) = dum2d(:,:)*rac(:,:)

         do i=1,nx
            do j=1,ny
               advv(im) = advv(im) + dum2d(i,j)
            enddo
         enddo

      enddo

      close(51)
            
c ------------------------------------
c Forcing 

c ------------------------------------
c oceFWflx files 

      fvar = 'oceFWflx_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')
      
c Loop over time 

      vfrc(:) = 0.
      do im=1,nmonths
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum2d   ! oceFWflx read into dum2d
         close(53)

c Distribute
         k=1
         do i=1,nx
            do j=1,ny
               vfrc(im) = vfrc(im) +
     $              dum2d(i,j)*wgt3d(i,j,k)*rac(i,j)
            enddo
         enddo
      enddo

      close(51)

c 
      vfrc(:) = vfrc(:) / rho0

c ------------------------------------
c Convert to value per volume (1/s)

c total volume 
      totv = 0.
      dum2d(:,:) = 0.
      do k=1,nr
         dum2d(:,:) = dum2d(:,:) + wgt3d(:,:,k)*dvol3d(:,:,k)
      enddo
      do i=1,nx
         do j=1,ny
            totv = totv + dum2d(i,j)
         enddo
      enddo

c convert 
      dum1 = totv
      lhs(:)  = lhs(:)  / dum1
      advh(:) = advh(:) / dum1
      advv(:) = advv(:) / dum1
      vfrc(:) = vfrc(:) / dum1

c ------------------------------------
c Output 
      ibud = 1   ! indicates volume budget 
      file_out = './emu_budg.tnd'
      open (51, file=trim(file_out), action='write', access='stream')
      write(51) ibud
      write(51) nmonths
      write(51) 5
      write(51) dt
      write(51) lhs     
      write(51) advh    
      write(51) advv
      write(51) vfrc 
      close(51)

c ------------------------------------
c Time integrate tendency 
c Convert to volume mean temperature anomaly time-series 

c convert 
      lhs2(1)  = lhs(1) *dt(1)
      advh2(1) = advh(1)*dt(1)
      advv2(1) = advv(1)*dt(1)
      vfrc2(1) = vfrc(1)*dt(1)

      do im=2,nmonths
         lhs2(im)  = lhs2(im-1)  + lhs(im)*dt(im)
         advh2(im) = advh2(im-1) + advh(im)*dt(im)
         advv2(im) = advv2(im-1) + advv(im)*dt(im)
         vfrc2(im) = vfrc2(im-1) + vfrc(im)*dt(im)
      enddo
      
c ------------------------------------
c Output 
      file_out = './emu_budg.int'
      open (51, file=trim(file_out), action='write', access='stream')
      write(51) ibud
      write(51) nmonths
      write(51) 5
      write(51) dt
      write(51) lhs2    
      write(51) advh2    
      write(51) advv2
      write(51) vfrc2 
      close(51)

      return
      end
c 
c ============================================================
c 
      subroutine budg_heat(wgt3d)
      integer nx, ny, nr
      parameter(nx=90, ny=1170, nr=50)
      parameter(nmonths=312, nyrs=26, yr1=1992, d2s=86400.)
     $                          ! max number of months of V4r4

c Mask  
      real*4 wgt3d(nx,ny,nr)

c model arrays
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr), hfacc(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, kmt, dxg, dyg, dvol3d, rac

c Common variables for all budgets
      real*4 etan(nx,ny,nmonths)
      real*4 dt(nmonths)
      common /budg_1/dt, etan

c Temporarly variables 
      real*4 dum2d(nx,ny), dum3d(nx,ny,nr)
      real*4 conv2d(nx,ny), dum3dy(nx,ny,nr)
      real*4 theta(nx,ny,nr,2)
      integer iold, inew 

      real*4 s0(nx,ny), s1(nx,ny)
      real*4 qfac(2,nr)
      character*256 f_file 
      character*256 f_command 

c Budget arrays 
      real*4 lhs(nmonths)
      real*4 advh(nmonths), advv(nmonths)
      real*4 mixh(nmonths), mixv(nmonths)
      real*4 mixv_i(nmonths), mixv_e(nmonths)
      real*4 tfrc(nmonths), geo(nmonths)

c Time-integrated budget arrays
      real*4 lhs2(nmonths)
      real*4 advh2(nmonths), advv2(nmonths)
      real*4 mixh2(nmonths), mixv2(nmonths)
      real*4 tfrc2(nmonths), geo2(nmonths)

c files
      character*256 f_inputdir   ! directory where tool files are 
      common /tool/f_inputdir
      character*256 file_in, file_out, file_dum, fvar  ! file names 

c ------------------------------------
c Constants
      rho0 = 1029.   ! reference density 
      cp = 3994.     ! heat capacity 
      t2q = rho0 * cp ! degC to J conversion 

c ------------------------------------
c Compute LHS (heat tendency)
      fvar = 'THETA_mon_inst'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles+1 .ne. nmonths) then
         write(6,*) 'nfiles+1 ne nmonths: ',nfiles,nmonths
         stop
      endif

      open (52, file=file_out, action='read')

      read(52,"(a)") file_dum
      open (53, file=trim(file_dum), action='read', access='stream')
      read (53) dum3d
      close(53)
      theta(:,:,:,1) = dum3d
      theta(:,:,:,2) = dum3d
      iold = 1
      inew = 3-iold

      lhs(:) = 0.
      do im=1,nmonths-2
         s0(:,:) = 1. + etan(:,:,im)*ibathy(:,:)
         s1(:,:) = 1. + etan(:,:,im+1)*ibathy(:,:)
         dum2d(:,:) = 0.
         do k=1,nr
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k) * (theta(:,:,k,inew)*s1(:,:) -
     $           theta(:,:,k,iold)*s0(:,:))/dt(im) * dvol3d(:,:,k)
         enddo
         do i=1,nx
            do j=1,ny
               lhs(im) = lhs(im) + dum2d(i,j)
            enddo
         enddo
c Read next THETA
         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)
         iold = inew
         inew = 3-iold
         theta(:,:,:,inew) = dum3d         
      enddo

      im = nmonths-1
         s0(:,:) = 1. + etan(:,:,im)*ibathy(:,:)
         s1(:,:) = 1. + etan(:,:,im+1)*ibathy(:,:)
         dum2d(:,:) = 0.
         do k=1,nr
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k) * (theta(:,:,k,inew)*s1(:,:) -
     $           theta(:,:,k,iold)*s0(:,:))/dt(im) * dvol3d(:,:,k)
         enddo
         do i=1,nx
            do j=1,ny
               lhs(im) = lhs(im) + dum2d(i,j)
            enddo
         enddo

c ------------------------------------
c Compute RHS tendencies 

c ------------------------------------
c Horizontal Advection 

c ID horizontal advection files 
      fvar = 'ADVx_TH_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar)
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')

      fvar = 'ADVy_TH_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files_y'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (52, file=trim(file_out), action='read')

      advh(:) = 0.
      do im=1,nmonths
c Read horizontal advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3dy
         close(53)

c Compute convergence of horizontal advection 
         dum2d(:,:) = 0.
         do k=1,nr
            call native_uv_conv_smpl(dum3d(:,:,k),dum3dy(:,:,k), 
     $           conv2d)
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*conv2d(:,:)
         enddo

         do i=1,nx
            do j=1,ny
               advh(im) = advh(im) + dum2d(i,j)
            enddo
         enddo

      enddo

      close(51)
      close(52)

c ------------------------------------
c Horizontal Mixing 

c ID horizontal mixing files 
      fvar = 'DFxE_TH_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')

      fvar = 'DFyE_TH_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files_y'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (52, file=trim(file_out), action='read')

      mixh(:) = 0.
      do im=1,nmonths
c Read horizontal mixing 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3dy
         close(53)

c Compute convergence of horizontal mixing 
         dum2d(:,:) = 0.
         do k=1,nr
            call native_uv_conv_smpl(dum3d(:,:,k),dum3dy(:,:,k),
     $           conv2d)
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*conv2d(:,:)
         enddo

         do i=1,nx
            do j=1,ny
               mixh(im) = mixh(im) + dum2d(i,j)
            enddo
         enddo

      enddo

      close(51)
      close(52)
            
c ------------------------------------
c Vertical Advection 

c ID vertical advection files
      fvar = 'ADVr_TH_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif

      open (51, file=trim(file_out), action='read')

      advv(:) = 0.
      do im=1,nmonths
c Read vertical advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

c Compute convergence of vertical advection 
         dum2d(:,:) = 0.
         do k=1,nr-1
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*(dum3d(:,:,k+1)-dum3d(:,:,k))
         enddo
         dum2d(:,:) = dum2d(:,:) +
     $        wgt3d(:,:,nr)*(-dum3d(:,:,nr))

         do i=1,nx
            do j=1,ny
               advv(im) = advv(im) + dum2d(i,j)
            enddo
         enddo

      enddo

      close(51)
            
c ------------------------------------
c Vertical Implicit Mixing 

c ID vertical implicit mixing files
      fvar = 'DFrI_TH_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif

      open (51, file=trim(file_out), action='read')

      mixv_i(:) = 0.
      do im=1,nmonths
c Read vertical advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

c Compute convergence of vertical advection 
         dum2d(:,:) = 0.
         do k=1,nr-1
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*(dum3d(:,:,k+1)-dum3d(:,:,k))
         enddo
         dum2d(:,:) = dum2d(:,:) +
     $        wgt3d(:,:,nr)*(-dum3d(:,:,nr))

         do i=1,nx
            do j=1,ny
               mixv_i(im) = mixv_i(im) + dum2d(i,j)
            enddo
         enddo

      enddo

      close(51)
            
c ------------------------------------
c Vertical Explicit Mixing 

c ID vertical explicit mixing files
      fvar = 'DFrE_TH_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif

      open (51, file=trim(file_out), action='read')

      mixv_e(:) = 0.
      do im=1,nmonths
c Read vertical advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

c Compute convergence of vertical advection 
         dum2d(:,:) = 0.
         do k=1,nr-1
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*(dum3d(:,:,k+1)-dum3d(:,:,k))
         enddo
         dum2d(:,:) = dum2d(:,:) +
     $        wgt3d(:,:,nr)*(-dum3d(:,:,nr))

         do i=1,nx
            do j=1,ny
               mixv_e(im) = mixv_e(im) + dum2d(i,j)
            enddo
         enddo

      enddo

      close(51)

c Net vertical mixing
      mixv(:) = mixv_i(:) + mixv_e(:)

c ------------------------------------
c Forcing 

c ------------------------------------
c Geothermal flux 
      file_in = trim(f_inputdir) //
     $     '/forcing/input_init/geothermalFlux.bin' 
      open (51, file=trim(file_in), action='read', access='stream')
      read (51) conv2d  ! geothermal read into conv2d
      close (51)

c Sum over domain 
      geo_s = 0.   ! scalar sum 
      do i=1,nx
         do j=1,ny
            if (kmt(i,j).ne.0) then 
               geo_s = geo_s +
     $              conv2d(i,j)*wgt3d(i,j,kmt(i,j))*rac(i,j)
            endif
         enddo
      enddo

      geo(:) = geo_s   ! time-invariant

c J to degC 
      geo(:) = geo(:) / t2q

c ------------------------------------
c TFLUX & oceQsw files 

c Shortwave penetration factors
      kmax = 1
      do k=1,nr
         if (rc(k) .lt. 200.) kmax = k
      enddo

      rfac = 0.62
      zeta1 = 0.6
      zeta2 = 20

      do k=1,kmax
         qfac(1,k) = rfac*exp(rf(k)/zeta1)
     $        + (1.-rfac)*exp(rf(k)/zeta2) 
         qfac(2,k) = rfac*exp(rf(k+1)/zeta1)
     $        + (1.-rfac)*exp(rf(k+1)/zeta2) 
      enddo

c TFLUX & oceQsw files 
      fvar = 'TFLUX_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')
      
      fvar = 'oceQsw_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files_y'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (52, file=trim(file_out), action='read')

c Loop over time 

      tfrc(:) = 0.
      do im=1,nmonths
c Read TFLUX & oceQsw
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum2d   ! TFLUX read into dum2d
         close(53)

         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) conv2d  ! oceQsw read into conv2d
         close(53)

c Distribute sw included in TFLUX vertically 
         k=1
         dum2d = dum2d - conv2d
     $        + (qfac(1,k)-qfac(2,k))*conv2d 
         do i=1,nx
            do j=1,ny
               tfrc(im) = tfrc(im) +
     $              dum2d(i,j)*wgt3d(i,j,k)*rac(i,j)
            enddo
         enddo

         do k=2,kmax
            dum2d = (qfac(1,k)-qfac(2,k))*conv2d 
            do i=1,nx
               do j=1,ny
                  tfrc(im) = tfrc(im) +
     $                 dum2d(i,j)*wgt3d(i,j,k)*rac(i,j)
               enddo
            enddo
         enddo
      enddo

      close(51)
      close(52)

c J to degC 
      tfrc(:) = tfrc(:) / t2q

c ------------------------------------
c Convert to value per volume (degC/s)

c total volume 
      totv = 0.
      dum2d(:,:) = 0.
      do k=1,nr
         dum2d(:,:) = dum2d(:,:) + wgt3d(:,:,k)*dvol3d(:,:,k)
      enddo
      do i=1,nx
         do j=1,ny
            totv = totv + dum2d(i,j)
         enddo
      enddo

c convert 
      dum1 = totv
      lhs(:)  = lhs(:)  / dum1
      advh(:) = advh(:) / dum1
      mixh(:) = mixh(:) / dum1
      advv(:) = advv(:) / dum1
      mixv(:) = mixv(:) / dum1
      tfrc(:) = tfrc(:) / dum1
      geo(:)  = geo(:) / dum1

c ------------------------------------
c Output tendency 
      ibud = 2   ! indicates heat (temperature) budget 
      file_out = './emu_budg.tnd'
      open (51, file=trim(file_out), action='write', access='stream')
      write(51) ibud
      write(51) nmonths
      write(51) 8 
      write(51) dt
      write(51) lhs     
      write(51) advh    
      write(51) mixh
      write(51) advv
      write(51) mixv
      write(51) tfrc 
      write(51) geo
      close(51)

c ------------------------------------
c Time integrate tendency 
c Convert to volume mean temperature anomaly time-series 

c convert 
      lhs2(1)  = lhs(1) *dt(1)
      advh2(1) = advh(1)*dt(1)
      mixh2(1) = mixh(1)*dt(1)
      advv2(1) = advv(1)*dt(1)
      mixv2(1) = mixv(1)*dt(1)
      tfrc2(1) = tfrc(1)*dt(1)
      geo2(1)  = geo(1) *dt(1)

      do im=2,nmonths
         lhs2(im)  = lhs2(im-1)  + lhs(im)*dt(im)
         advh2(im) = advh2(im-1) + advh(im)*dt(im)
         mixh2(im) = mixh2(im-1) + mixh(im)*dt(im)
         advv2(im) = advv2(im-1) + advv(im)*dt(im)
         mixv2(im) = mixv2(im-1) + mixv(im)*dt(im)
         tfrc2(im) = tfrc2(im-1) + tfrc(im)*dt(im)
         geo2(im)  = geo2(im-1)  + geo(im)*dt(im)
      enddo
      
c ------------------------------------
c Output 
      file_out = './emu_budg.int'
      open (51, file=trim(file_out), action='write', access='stream')
      write(51) ibud
      write(51) nmonths
      write(51) 8 
      write(51) dt
      write(51) lhs2    
      write(51) advh2    
      write(51) mixh2
      write(51) advv2
      write(51) mixv2
      write(51) tfrc2 
      write(51) geo2
      close(51)

      return
      end
c 
c ============================================================
c 
      subroutine budg_salt(wgt3d)
      integer nx, ny, nr
      parameter(nx=90, ny=1170, nr=50)
      parameter(nmonths=312, nyrs=26, yr1=1992, d2s=86400.)
     $                          ! max number of months of V4r4

c Mask  
      real*4 wgt3d(nx,ny,nr)

c model arrays
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr), hfacc(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, kmt, dxg, dyg, dvol3d, rac

c Common variables for all budgets
      real*4 etan(nx,ny,nmonths)
      real*4 dt(nmonths)
      common /budg_1/dt, etan

c Temporarly variables 
      real*4 dum2d(nx,ny), dum3d(nx,ny,nr)
      real*4 conv2d(nx,ny), dum3dy(nx,ny,nr)
      real*4 salt(nx,ny,nr,2)
      integer iold, inew 

      real*4 s0(nx,ny), s1(nx,ny)
      character*256 f_file 
      character*256 f_command 

c Budget arrays 
      real*4 lhs(nmonths)
      real*4 advh(nmonths), advv(nmonths)
      real*4 mixh(nmonths), mixv(nmonths)
      real*4 mixv_i(nmonths), mixv_e(nmonths)
      real*4 sfrc(nmonths)

c Time-integrated budget arrays
      real*4 lhs2(nmonths)
      real*4 advh2(nmonths), advv2(nmonths)
      real*4 mixh2(nmonths), mixv2(nmonths)
      real*4 sfrc2(nmonths)

c files
      character*256 f_inputdir   ! directory where tool files are 
      common /tool/f_inputdir
      character*256 file_in, file_out, file_dum, fvar  ! file names 

c ------------------------------------
c Constants
      rho0 = 1029.   ! reference density 

c ------------------------------------
c Compute LHS (salt tendency)
      fvar = 'SALT_mon_inst'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles+1 .ne. nmonths) then
         write(6,*) 'nfiles+1 ne nmonths: ',nfiles,nmonths
         stop
      endif

      open (52, file=file_out, action='read')
      read(52,"(a)") file_dum
      open (53, file=trim(file_dum), action='read', access='stream')
      read (53) dum3d
      close(53)
      salt(:,:,:,1) = dum3d
      salt(:,:,:,2) = dum3d
      iold = 1
      inew = 3-iold

      lhs(:) = 0.
      do im=1,nmonths-2
         s0(:,:) = 1. + etan(:,:,im)*ibathy(:,:)
         s1(:,:) = 1. + etan(:,:,im+1)*ibathy(:,:)
         dum2d(:,:) = 0.
         do k=1,nr
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k) * (salt(:,:,k,inew)*s1(:,:) -
     $           salt(:,:,k,iold)*s0(:,:))/dt(im) * dvol3d(:,:,k)
         enddo
         do i=1,nx
            do j=1,ny
               lhs(im) = lhs(im) + dum2d(i,j)
            enddo
         enddo
c Read next SALT
         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)
         iold = inew
         inew = 3-iold
         salt(:,:,:,inew) = dum3d         
      enddo

      im = nmonths-1
         s0(:,:) = 1. + etan(:,:,im)*ibathy(:,:)
         s1(:,:) = 1. + etan(:,:,im+1)*ibathy(:,:)
         dum2d(:,:) = 0.
         do k=1,nr
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k) * (salt(:,:,k,inew)*s1(:,:) -
     $           salt(:,:,k,iold)*s0(:,:))/dt(im) * dvol3d(:,:,k)
         enddo
         do i=1,nx
            do j=1,ny
               lhs(im) = lhs(im) + dum2d(i,j)
            enddo
         enddo

c ------------------------------------
c Compute RHS tendencies 

c ------------------------------------
c Horizontal Advection 

c ID horizontal advection files 
      fvar = 'ADVx_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar)
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')

      fvar = 'ADVy_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files_y'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (52, file=trim(file_out), action='read')

      advh(:) = 0.
      do im=1,nmonths
c Read horizontal advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3dy
         close(53)

c Compute convergence of horizontal advection 
         dum2d(:,:) = 0.
         do k=1,nr
            call native_uv_conv_smpl(dum3d(:,:,k),dum3dy(:,:,k), 
     $           conv2d)
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*conv2d(:,:)
         enddo

         do i=1,nx
            do j=1,ny
               advh(im) = advh(im) + dum2d(i,j)
            enddo
         enddo

      enddo

      close(51)
      close(52)

c ------------------------------------
c Horizontal Mixing 

c ID horizontal mixing files 
      fvar = 'DFxE_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')

      fvar = 'DFyE_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files_y'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (52, file=trim(file_out), action='read')

      mixh(:) = 0.
      do im=1,nmonths
c Read horizontal mixing 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3dy
         close(53)

c Compute convergence of horizontal mixing 
         dum2d(:,:) = 0.
         do k=1,nr
            call native_uv_conv_smpl(dum3d(:,:,k),dum3dy(:,:,k),
     $           conv2d)
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*conv2d(:,:)
         enddo

         do i=1,nx
            do j=1,ny
               mixh(im) = mixh(im) + dum2d(i,j)
            enddo
         enddo

      enddo

      close(51)
      close(52)
            
c ------------------------------------
c Vertical Advection 

c ID vertical advection files
      fvar = 'ADVr_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')

      advv(:) = 0.
      do im=1,nmonths
c Read vertical advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

c Compute convergence of vertical advection 
         dum2d(:,:) = 0.
         do k=1,nr-1
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*(dum3d(:,:,k+1)-dum3d(:,:,k))
         enddo
         dum2d(:,:) = dum2d(:,:) +
     $        wgt3d(:,:,nr)*(-dum3d(:,:,nr))

         do i=1,nx
            do j=1,ny
               advv(im) = advv(im) + dum2d(i,j)
            enddo
         enddo

      enddo

      close(51)
            
c ------------------------------------
c Vertical Implicit Mixing 

c ID vertical implicit mixing files
      fvar = 'DFrI_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')

      mixv_i(:) = 0.
      do im=1,nmonths
c Read vertical advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

c Compute convergence of vertical advection 
         dum2d(:,:) = 0.
         do k=1,nr-1
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*(dum3d(:,:,k+1)-dum3d(:,:,k))
         enddo
         dum2d(:,:) = dum2d(:,:) +
     $        wgt3d(:,:,nr)*(-dum3d(:,:,nr))

         do i=1,nx
            do j=1,ny
               mixv_i(im) = mixv_i(im) + dum2d(i,j)
            enddo
         enddo

      enddo

      close(51)
            
c ------------------------------------
c Vertical Explicit Mixing 

c ID vertical explicit mixing files
      fvar = 'DFrE_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif

      open (51, file=trim(file_out), action='read')

      mixv_e(:) = 0.
      do im=1,nmonths
c Read vertical advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

c Compute convergence of vertical advection 
         dum2d(:,:) = 0.
         do k=1,nr-1
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*(dum3d(:,:,k+1)-dum3d(:,:,k))
         enddo
         dum2d(:,:) = dum2d(:,:) +
     $        wgt3d(:,:,nr)*(-dum3d(:,:,nr))

         do i=1,nx
            do j=1,ny
               mixv_e(im) = mixv_e(im) + dum2d(i,j)
            enddo
         enddo

      enddo

      close(51)

c Net vertical mixing
      mixv(:) = mixv_i(:) + mixv_e(:)

c ------------------------------------
c Forcing 

c ------------------------------------
c SFLUX & oceSPtnd files 

      fvar = 'SFLUX_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')
      
      fvar = 'oceSPtnd_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files_y'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (52, file=trim(file_out), action='read')

c Loop over time 

      sfrc(:) = 0.
      do im=1,nmonths
c Read SFLUX & oceSPtnd
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum2d   ! SFLUX read into dum2d 
         close(53)

         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d   ! oceSPtnd read into dum3d
         close(53)

c Distribute 
         k=1
         dum2d = dum2d + dum3d(:,:,k)
         do i=1,nx
            do j=1,ny
               sfrc(im) = sfrc(im) +
     $              dum2d(i,j)*wgt3d(i,j,k)*rac(i,j)
            enddo
         enddo

         do k=2,nr 
            do i=1,nx
               do j=1,ny
                  sfrc(im) = sfrc(im) +
     $                 dum3d(i,j,k)*wgt3d(i,j,k)*rac(i,j)
               enddo
            enddo
         enddo
      enddo

      close(51)
      close(52)

c Convert to psu 
      sfrc(:) = sfrc(:) / rho0 

c ------------------------------------
c Convert to value per volume (1/s)

c total volume 
      totv = 0.
      dum2d(:,:) = 0.
      do k=1,nr
         dum2d(:,:) = dum2d(:,:) + wgt3d(:,:,k)*dvol3d(:,:,k)
      enddo
      do i=1,nx
         do j=1,ny
            totv = totv + dum2d(i,j)
         enddo
      enddo

c convert 
      dum1 = totv
      lhs(:)  = lhs(:)  / dum1
      advh(:) = advh(:) / dum1
      mixh(:) = mixh(:) / dum1
      advv(:) = advv(:) / dum1
      mixv(:) = mixv(:) / dum1
      sfrc(:) = sfrc(:) / dum1

c ------------------------------------
c Output tendency 
      ibud = 3   ! indicates salt budget 
      file_out = './emu_budg.tnd'
      open (51, file=trim(file_out), action='write', access='stream')
      write(51) ibud
      write(51) nmonths
      write(51) 7
      write(51) dt
      write(51) lhs     
      write(51) advh    
      write(51) mixh
      write(51) advv
      write(51) mixv
      write(51) sfrc 
      close(51)

c ------------------------------------
c Time integrate tendency 
c Convert to volume mean salt anomaly time-series 

c convert 
      lhs2(1)  = lhs(1) *dt(1)
      advh2(1) = advh(1)*dt(1)
      mixh2(1) = mixh(1)*dt(1)
      advv2(1) = advv(1)*dt(1)
      mixv2(1) = mixv(1)*dt(1)
      sfrc2(1) = sfrc(1)*dt(1)

      do im=2,nmonths
         lhs2(im)  = lhs2(im-1)  + lhs(im)*dt(im)
         advh2(im) = advh2(im-1) + advh(im)*dt(im)
         mixh2(im) = mixh2(im-1) + mixh(im)*dt(im)
         advv2(im) = advv2(im-1) + advv(im)*dt(im)
         mixv2(im) = mixv2(im-1) + mixv(im)*dt(im)
         sfrc2(im) = sfrc2(im-1) + sfrc(im)*dt(im)
      enddo
      
c ------------------------------------
c Output 
      file_out = './emu_budg.int'
      open (51, file=trim(file_out), action='write', access='stream')
      write(51) ibud
      write(51) nmonths
      write(51) 7
      write(51) dt
      write(51) lhs2    
      write(51) advh2    
      write(51) mixh2
      write(51) advv2
      write(51) mixv2
      write(51) sfrc2 
      close(51)

      return
      end
c 
c ============================================================
c 
      subroutine budg_salinity(wgt3d)
      integer nx, ny, nr
      parameter(nx=90, ny=1170, nr=50)
      parameter(nmonths=312, nyrs=26, yr1=1992, d2s=86400.)
     $                          ! max number of months of V4r4

c Mask  
      real*4 wgt3d(nx,ny,nr)

c model arrays
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr), hfacc(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, kmt, dxg, dyg, dvol3d, rac

c Common variables for all budgets
      real*4 etan(nx,ny,nmonths)  ! ETAN snapshot 
      real*4 dt(nmonths)
      common /budg_1/dt, etan

c Temporarly variables 
      real*4 dum2d(nx,ny), dum3d(nx,ny,nr)
      real*4 conv2d(nx,ny), dum3dy(nx,ny,nr)
      real*4 salt(nx,ny,nr,2)
      integer iold, inew 

      real*4 s0(nx,ny), s1(nx,ny)
      character*256 f_file 
      character*256 f_command 

c Budget arrays 
      real*4 metan(nx,ny,nmonths) ! monthly mean ETAN
      real*4 msalt(nx,ny,nr)  ! monthly mean salinity

      real*4 lhs(nmonths)
      real*4 advh(nmonths), advv(nmonths)
      real*4 mixh(nmonths), mixv(nmonths)
      real*4 mixv_i(nmonths), mixv_e(nmonths)
      real*4 sfrc(nmonths)

c Time-integrated budget arrays
      real*4 lhs2(nmonths)
      real*4 advh2(nmonths), advv2(nmonths)
      real*4 mixh2(nmonths), mixv2(nmonths)
      real*4 sfrc2(nmonths)

c files
      character*256 f_inputdir   ! directory where tool files are 
      common /tool/f_inputdir
      character*256 file_in, file_out, file_dum, fvar  ! file names 

c ------------------------------------
c Constants
      rho0 = 1029.   ! reference density 

c ------------------------------------
c Compute LHS (salinity tendency)
      fvar = 'SALT_mon_inst'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles+1 .ne. nmonths) then
         write(6,*) 'nfiles+1 ne nmonths: ',nfiles,nmonths
         stop
      endif

      open (52, file=file_out, action='read')
      read(52,"(a)") file_dum
      open (53, file=trim(file_dum), action='read', access='stream')
      read (53) dum3d
      close(53)
      salt(:,:,:,1) = dum3d
      salt(:,:,:,2) = dum3d
      iold = 1
      inew = 3-iold

      lhs(:) = 0.
      do im=1,nmonths-2
         dum2d(:,:) = 0.
         do k=1,nr
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k) * (salt(:,:,k,inew) -
     $           salt(:,:,k,iold))/dt(im) * dvol3d(:,:,k)
         enddo
         do i=1,nx
            do j=1,ny
               lhs(im) = lhs(im) + dum2d(i,j)
            enddo
         enddo
c Read next SALT
         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)
         iold = inew
         inew = 3-iold
         salt(:,:,:,inew) = dum3d         
      enddo

      im = nmonths-1
         dum2d(:,:) = 0.
         do k=1,nr
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k) * (salt(:,:,k,inew) -
     $           salt(:,:,k,iold))/dt(im) * dvol3d(:,:,k)
         enddo
         do i=1,nx
            do j=1,ny
               lhs(im) = lhs(im) + dum2d(i,j)
            enddo
         enddo

c ------------------------------------
c Compute RHS tendencies 

c monthly mean SALINITY 
      fvar = 'state_3d_set1_mon'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/' //
     $     'diags/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files_SALT'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar)
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (58, file=trim(file_out), action='read')

c monthly mean ETAN
      fvar = 'ETAN_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar)
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (59, file=trim(file_out), action='read')
      do i=1,nfiles
         read(59,"(a)") file_dum
         open (53, file=file_dum, action='read', access='stream')
         read (53) dum2d
         metan(:,:,i) = dum2d
         close(53)
      enddo
      close(59)
      

c ------------------------------------
c Horizontal Advection 

c ID horizontal advection files (SALT)
      fvar = 'ADVx_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar)
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')

      fvar = 'ADVy_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files_y'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (52, file=trim(file_out), action='read')

      advh(:) = 0.
      do im=1,nmonths
c
         s0(:,:) = 1. + metan(:,:,im)*ibathy(:,:)

c Read horizontal advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3dy
         close(53)

c Compute convergence of horizontal advection 
         dum2d(:,:) = 0.
         do k=1,nr
            call native_uv_conv_smpl(dum3d(:,:,k),dum3dy(:,:,k), 
     $           conv2d)
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*conv2d(:,:)
         enddo

         do i=1,nx
            do j=1,ny
               advh(im) = advh(im) + dum2d(i,j)/s0(i,j)
            enddo
         enddo

      enddo

      close(51)
      close(52)

c ID horizontal advection files (Volume)
      fvar = 'UVELMASS_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar)
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')

      fvar = 'VVELMASS_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files_y'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (52, file=trim(file_out), action='read')

      rewind(58) 
      do im=1,nmonths
c
         s0(:,:) = 1. + metan(:,:,im)*ibathy(:,:)

c Read monthly mean S
         read(58,"(a)") file_dum
         open (53, file=trim(file_dum), access='direct',
     $        form='unformatted', recl=nx*ny*nr*4)
         read(53,rec=2) msalt
         close(53)

c Read horizontal advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)
         do k=1,nr
            dum3d(:,:,k) = dum3d(:,:,k)*dyg(:,:)
         enddo

         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3dy
         close(53)
         do k=1,nr
            dum3dy(:,:,k) = dum3dy(:,:,k)*dxg(:,:)
         enddo

c Compute convergence of horizontal advection 
         dum2d(:,:) = 0.
         do k=1,nr
            call native_uv_conv_smpl(dum3d(:,:,k),dum3dy(:,:,k), 
     $           conv2d)
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*conv2d(:,:)*drf(k)*
     $           msalt(:,:,k)
         enddo

         do i=1,nx
            do j=1,ny
               advh(im) = advh(im) - dum2d(i,j)/s0(i,j)
            enddo
         enddo

      enddo

      close(51)
      close(52)

c ------------------------------------
c Horizontal Mixing 

c ID horizontal mixing files (SALT)
      fvar = 'DFxE_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')

      fvar = 'DFyE_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files_y'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (52, file=trim(file_out), action='read')

      mixh(:) = 0.
      do im=1,nmonths
c
         s0(:,:) = 1. + metan(:,:,im)*ibathy(:,:)

c Read horizontal mixing 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3dy
         close(53)

c Compute convergence of horizontal mixing 
         dum2d(:,:) = 0.
         do k=1,nr
            call native_uv_conv_smpl(dum3d(:,:,k),dum3dy(:,:,k),
     $           conv2d)
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*conv2d(:,:)
         enddo

         do i=1,nx
            do j=1,ny
               mixh(im) = mixh(im) + dum2d(i,j)/s0(i,j)
            enddo
         enddo

      enddo

      close(51)
      close(52)
            
c ------------------------------------
c Vertical Advection 

c ID vertical advection files (SALT)
      fvar = 'ADVr_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')

      advv(:) = 0.
      do im=1,nmonths
c
         s0(:,:) = 1. + metan(:,:,im)*ibathy(:,:)

c Read vertical advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

c Compute convergence of vertical advection 
         dum2d(:,:) = 0.
         do k=1,nr-1
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*(dum3d(:,:,k+1)-dum3d(:,:,k))
         enddo
         dum2d(:,:) = dum2d(:,:) +
     $        wgt3d(:,:,nr)*(-dum3d(:,:,nr))

         do i=1,nx
            do j=1,ny
               advv(im) = advv(im) + dum2d(i,j)/s0(i,j)
            enddo
         enddo

      enddo

      close(51)
            
c ID vertical advection files (Volume)
      fvar = 'WVELMASS_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif

      open (51, file=trim(file_out), action='read')

      rewind(58) 
      do im=1,nmonths
c
         s0(:,:) = 1. + metan(:,:,im)*ibathy(:,:)

c Read monthly mean S
         read(58,"(a)") file_dum
         open (53, file=trim(file_dum), access='direct',
     $        form='unformatted', recl=nx*ny*nr*4)
         read(53,rec=2) msalt
         close(53)

c Read vertical advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

c Compute convergence of vertical advection 
         dum2d(:,:) = 0.
         k=1
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*dum3d(:,:,k+1)*msalt(:,:,k)
         do k=2,nr-1
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*(dum3d(:,:,k+1)-dum3d(:,:,k))*
     $           msalt(:,:,k)
         enddo
         k=nr
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*(-dum3d(:,:,k))*msalt(:,:,k)

         dum2d(:,:) = dum2d(:,:)*rac(:,:)

         do i=1,nx
            do j=1,ny
               advv(im) = advv(im) - dum2d(i,j)/s0(i,j)
            enddo
         enddo

      enddo

      close(51)

c ------------------------------------
c Vertical Implicit Mixing 

c ID vertical implicit mixing files (SALT)
      fvar = 'DFrI_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')

      mixv_i(:) = 0.
      do im=1,nmonths
c
         s0(:,:) = 1. + metan(:,:,im)*ibathy(:,:)

c Read vertical advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

c Compute convergence of vertical advection 
         dum2d(:,:) = 0.
         do k=1,nr-1
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*(dum3d(:,:,k+1)-dum3d(:,:,k))
         enddo
         dum2d(:,:) = dum2d(:,:) +
     $        wgt3d(:,:,nr)*(-dum3d(:,:,nr))

         do i=1,nx
            do j=1,ny
               mixv_i(im) = mixv_i(im) + dum2d(i,j)/s0(i,j)
            enddo
         enddo

      enddo

      close(51)
            
c ------------------------------------
c Vertical Explicit Mixing 

c ID vertical explicit mixing files (SALT)
      fvar = 'DFrE_SLT_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif

      open (51, file=trim(file_out), action='read')

      mixv_e(:) = 0.
      do im=1,nmonths
c
         s0(:,:) = 1. + metan(:,:,im)*ibathy(:,:)

c Read vertical advection 
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d
         close(53)

c Compute convergence of vertical advection 
         dum2d(:,:) = 0.
         do k=1,nr-1
            dum2d(:,:) = dum2d(:,:) +
     $           wgt3d(:,:,k)*(dum3d(:,:,k+1)-dum3d(:,:,k))
         enddo
         dum2d(:,:) = dum2d(:,:) +
     $        wgt3d(:,:,nr)*(-dum3d(:,:,nr))

         do i=1,nx
            do j=1,ny
               mixv_e(im) = mixv_e(im) + dum2d(i,j)/s0(i,j)
            enddo
         enddo

      enddo

      close(51)

c Net vertical mixing
      mixv(:) = mixv_i(:) + mixv_e(:)

c ------------------------------------
c Forcing 

c ------------------------------------
c SFLUX & oceSPtnd files (SALT)

      fvar = 'SFLUX_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')
      
      fvar = 'oceSPtnd_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files_y'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (52, file=trim(file_out), action='read')

c Loop over time 

      sfrc(:) = 0.
      do im=1,nmonths
c
         s0(:,:) = 1. + metan(:,:,im)*ibathy(:,:)

c Read SFLUX & oceSPtnd
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum2d   ! SFLUX read into dum2d 
         close(53)

         read(52,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum3d   ! oceSPtnd read into dum3d
         close(53)

c Distribute 
         k=1
         dum2d = dum2d + dum3d(:,:,k)
         do i=1,nx
            do j=1,ny
               sfrc(im) = sfrc(im) +
     $              dum2d(i,j)*wgt3d(i,j,k)*rac(i,j)/s0(i,j)
            enddo
         enddo

         do k=2,nr
            do i=1,nx
               do j=1,ny
                  sfrc(im) = sfrc(im) +
     $                 dum3d(i,j,k)*wgt3d(i,j,k)*rac(i,j)/s0(i,j)
               enddo
            enddo
         enddo
      enddo

      close(51)
      close(52)

c ------------------------------------
c oceFWflx files 

      fvar = 'oceFWflx_mon_mean'
      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/diags/' //
     $     trim(fvar) // '/' // trim(fvar) // '.*.data'
      file_out = './do_budg.files'
      call file_search(file_in,file_out,nfiles)
      if (nfiles .ne. nmonths) then
         write(6,*) trim(fvar) 
         write(6,*) 'nfiles ne nmonths: ',nfiles,nmonths
         stop
      endif
      open (51, file=trim(file_out), action='read')
      
c Loop over time 

      rewind(58) 
      do im=1,nmonths
c
         s0(:,:) = 1. + metan(:,:,im)*ibathy(:,:)

c Read monthly mean S
         read(58,"(a)") file_dum
         open (53, file=trim(file_dum), access='direct',
     $        form='unformatted', recl=nx*ny*nr*4)
         read(53,rec=2) msalt
         close(53)

c
         read(51,"(a)") file_dum
         open (53, file=trim(file_dum), action='read', access='stream')
         read (53) dum2d   ! oceFWflx read into dum2d
         close(53)

c Distribute 
         k=1
         do i=1,nx
            do j=1,ny
               sfrc(im) = sfrc(im) -
     $              dum2d(i,j)*wgt3d(i,j,k)*rac(i,j)*
     $              msalt(i,j,k)/s0(i,j)
            enddo
         enddo
      enddo

      close(51)

c Convert to psu 
      sfrc(:) = sfrc(:) / rho0 

c ------------------------------------
c Convert to value per volume (1/s)

c total volume 
      totv = 0.
      dum2d(:,:) = 0.
      do k=1,nr
         dum2d(:,:) = dum2d(:,:) + wgt3d(:,:,k)*dvol3d(:,:,k)
      enddo
      do i=1,nx
         do j=1,ny
            totv = totv + dum2d(i,j)
         enddo
      enddo

c convert 
      dum1 = totv
      lhs(:)  = lhs(:)  / dum1
      advh(:) = advh(:) / dum1
      mixh(:) = mixh(:) / dum1
      advv(:) = advv(:) / dum1
      mixv(:) = mixv(:) / dum1
      sfrc(:) = sfrc(:) / dum1

c ------------------------------------
c Output tendency 
      ibud = 4   ! indicates salinity budget 
      file_out = './emu_budg.tnd'
      open (51, file=trim(file_out), action='write', access='stream')
      write(51) ibud
      write(51) nmonths
      write(51) 7
      write(51) dt
      write(51) lhs     
      write(51) advh    
      write(51) mixh
      write(51) advv
      write(51) mixv
      write(51) sfrc 
      close(51)

c ------------------------------------
c Time integrate tendency 
c Convert to volume mean salinity anomaly time-series 

c convert 
      lhs2(1)  = lhs(1) *dt(1)
      advh2(1) = advh(1)*dt(1)
      mixh2(1) = mixh(1)*dt(1)
      advv2(1) = advv(1)*dt(1)
      mixv2(1) = mixv(1)*dt(1)
      sfrc2(1) = sfrc(1)*dt(1)

      do im=2,nmonths
         lhs2(im)  = lhs2(im-1)  + lhs(im)*dt(im)
         advh2(im) = advh2(im-1) + advh(im)*dt(im)
         mixh2(im) = mixh2(im-1) + mixh(im)*dt(im)
         advv2(im) = advv2(im-1) + advv(im)*dt(im)
         mixv2(im) = mixv2(im-1) + mixv(im)*dt(im)
         sfrc2(im) = sfrc2(im-1) + sfrc(im)*dt(im)
      enddo
      
c ------------------------------------
c Output 
      file_out = './emu_budg.int'
      open (51, file=trim(file_out), action='write', access='stream')
      write(51) ibud
      write(51) nmonths
      write(51) 7
      write(51) dt
      write(51) lhs2    
      write(51) advh2    
      write(51) mixh2
      write(51) advv2
      write(51) mixv2
      write(51) sfrc2 
      close(51)

      return
      end
c 
c ============================================================
c 
      subroutine file_search(file_in, file_out, nfiles) 
c Search for files matching file_in (can have wild card) and 
c output there names to file file_out and 
c return the number of files as nfiles.

c Argument 
      character*256 file_in, file_out
      integer nfiles

c
      character*256 f_command

c ------------------------------------
      write(6,*) 'file_search (file_in): ',trim(file_in)
      write(6,*) 'file_search (file_out): ',trim(file_out)

c ------------------------------------
c ID the files 
      call StripSpaces(file_in)
      f_command = 'ls ' // trim(file_in) // ' > ' // trim(file_out)
      call execute_command_line(f_command, wait=.true.)

c ------------------------------------
c Count number of files 
      open (53, file=trim(file_out), action='read')
      nfiles = 0
      do 
         read(53, '(A)', iostat=ios) f_command
         if (ios /= 0) exit     ! Exit the loop at the end of the file
         nfiles = nfiles + 1
      end do

      close(53)

      return
      end
c 
c ============================================================
c 
      subroutine native_uv_conv_smpl(fx, fy, conv)
c Compute simple 2d horizontal convolution (no metric weights applied) 
      
c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

      real*4 fx(nx,ny), fy(nx,ny)

      real*4 conv(nx,ny)

c gcmfaces versions
      real*4 u1(nx,3*nx), u2(nx,3*nx), u3(nx,nx)
      real*4 u4(3*nx,nx), u5(3*nx,nx)

      real*4 v1(nx,3*nx), v2(nx,3*nx), v3(nx,nx)
      real*4 v4(3*nx,nx), v5(3*nx,nx)

      real*4 c1(nx,3*nx), c2(nx,3*nx), c3(nx,nx)
      real*4 c4(3*nx,nx), c5(3*nx,nx)

c ------------------------------------
c Convert fx & fy to gcmfaces 
      call convert2gcmfaces(fx, u1,u2,u3,u4,u5)
      call convert2gcmfaces(fy, v1,v2,v3,v4,v5)

c Compute convergence
      call calc_uv_conv_smpl(u1,u2,u3,u4,u5, v1,v2,v3,v4,v5,
     $     c1,c2,c3,c4,c5)

c Convert to native
      call convert4gcmfaces(conv, c1,c2,c3,c4,c5)

      return
      end
c 
c ============================================================
c 
      subroutine convert2gcmfaces(fx, u1,u2,u3,u4,u5)
c Convert native nx*ny array to gcmfaces array
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
      end
c 
c ============================================================
c 
      subroutine convert4gcmfaces(fx, u1,u2,u3,u4,u5)
c Convert gcmfaces array to native nx*ny array 
c (Reverse of convert2gcmfaces.)
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
      end
c 
c ============================================================
c 
      subroutine calc_uv_conv_smpl(u1,u2,u3,u4,u5, v1,v2,v3,v4,v5,
     $     c1,c2,c3,c4,c5)
c Compute SIMPLE horizontal convergence
c No metric terms applied

      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c gcmfaces version
      real*4 u1(nx,3*nx), u2(nx,3*nx), u3(nx,nx)
      real*4 u4(3*nx,nx), u5(3*nx,nx)

      real*4 v1(nx,3*nx), v2(nx,3*nx), v3(nx,nx)
      real*4 v4(3*nx,nx), v5(3*nx,nx)

      real*4 c1(nx,3*nx), c2(nx,3*nx), c3(nx,nx)
      real*4 c4(3*nx,nx), c5(3*nx,nx)

c gcmfaces with halos 
      real*4 u1h(nx+2,3*nx+2), u2h(nx+2,3*nx+2)
      real*4 u3h(nx+2,nx+2)
      real*4 u4h(3*nx+2,nx+2), u5h(3*nx+2,nx+2)

      real*4 v1h(nx+2,3*nx+2), v2h(nx+2,3*nx+2)
      real*4 v3h(nx+2,nx+2)
      real*4 v4h(3*nx+2,nx+2), v5h(3*nx+2,nx+2)

c ------------------------------------

c Convert uv gcmfaces with halos 
      call exch_uv_llc(u1,u2,u3,u4,u5, v1,v2,v3,v4,v5,
     $     u1h,u2h,u3h,u4h,u5h, v1h,v2h,v3h,v4h,v5h)

c Convergence
      c1(:,:) = u1h(2:nx+1,2:3*nx+1) - u1h(3:nx+2,2:3*nx+1)
     $        + v1h(2:nx+1,2:3*nx+1) - v1h(2:nx+1,3:3*nx+2)

      c2(:,:) = u2h(2:nx+1,2:3*nx+1) - u2h(3:nx+2,2:3*nx+1)
     $        + v2h(2:nx+1,2:3*nx+1) - v2h(2:nx+1,3:3*nx+2)


      c3(:,:) = u3h(2:nx+1,2:nx+1) - u3h(3:nx+2,2:nx+1)
     $        + v3h(2:nx+1,2:nx+1) - v3h(2:nx+1,3:nx+2)


      c4(:,:) = u4h(2:3*nx+1,2:nx+1) - u4h(3:3*nx+2,2:nx+1)
     $        + v4h(2:3*nx+1,2:nx+1) - v4h(2:3*nx+1,3:nx+2)

      c5(:,:) = u5h(2:3*nx+1,2:nx+1) - u5h(3:3*nx+2,2:nx+1)
     $        + v5h(2:3*nx+1,2:nx+1) - v5h(2:3*nx+1,3:nx+2)

      return
      end
c 
c ============================================================
c 
      subroutine exch_uv_llc(u1,u2,u3,u4,u5, v1,v2,v3,v4,v5,
     $     u1h,u2h,u3h,u4h,u5h, v1h,v2h,v3h,v4h,v5h)

c Fill halos of vector field in gcmfaces array

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
      end
c 
c ============================================================
c 
      subroutine exch_t_n_llc(c1,c2,c3,c4,c5, c1h,c2h,c3h,c4h,c5h)

c Fill halos of scalar field in gcmfaces array

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

      do j=1,nx
         c1h(j+1,3*nx+2) = c3(1,nx+1-j)
         c2h(j+1,3*nx+2) = c3(j,1)
         c4h(1,j+1) = c3(nx,j)
         c4h(1,j+1) = c3(nx+1-j,nx)

         c3h(1,j+1) = c1(nx+1-j,3*nx)
         c3h(j+1,1) = c2(j,1)
         c3h(nx+2,j+1) = c4(1,j)
         c3h(j+1,nx+2) = c5(1,nx+1-j)
      enddo

      return
      end

