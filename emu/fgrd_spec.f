      program fgrd_spec
c -----------------------------------------------------
c Program for Forward Gradient Tool (V4r4)
c
c Create namelist (fgrd_pert.nml) for fgrd_pert.f
c 
c Example input: 
c     Perturb EMPMR at (85,601) at week 5
c     using default perturbation magnitude. 
c 
c     1
c     1 
c     85
c     601
c     5
c     1
c
c 28 June 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces

c Perturbation (perturbation variable, location, time, amplitude)
      integer pert_v, pert_i, pert_j, pert_k, pert_t
      real*4 pert_a, pert_x, pert_y
      namelist /PERT_SPEC/ pert_v, pert_i, pert_j, pert_k,
     $     pert_t, pert_a
      integer pert_v2, ipert

      integer pert_h

      integer check_v, check_i, check_j, check_t, check_a, check_d

c 
      integer nctrl, nctrl2                ! number of controls 
      parameter (nctrl=16, nctrl2=8) 
      character*130 file_in, file_out  ! file names 
      logical file_exists
      character*72 f_xx(nctrl), f_xx_unit(nctrl)
      real*4 scale(nctrl)              ! default perturbation
      character*256 f_command

c       
      character*256 f_inputdir  ! directory where tool input files are 
      common /tool/f_inputdir

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr)
      real*4 hfacc(nx,ny,nr), hfacw(nx,ny,nr), hfacs(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, hfacw, hfacs,
     $     kmt, dxg, dyg, dvol3d, rac
      
c
      integer nwk 
      parameter (nwk=1358)

      integer i
      character*256 setup
      character*256 f_input   ! full path to emu_input_dir
      character*256 f_emuref  ! full path to emu_ref

c Integration time 
      parameter(max_files=1000)
      integer pkuphrs(max_files), n_pkuphrs

      integer niter0, iend, nsteps, nyears, nmonths
      parameter(nsteps=227904) ! max time-step of V4r4
      parameter(nyears=26)  ! max number of years of V4r4
      parameter(nmonths=312) ! max number of months of V4r4
      integer nTimesteps, nHours, hour26yr
      character*24 fstep 

      integer nproc, hour26yr_trc, hour26yr_fwd, hour26yr_adj
      namelist /mitgcm_timing/ nproc, hour26yr_trc,
     $     hour26yr_fwd, hour26yr_adj

      integer mdays(12)
      data mdays/31,28,31,30,31,30,31,31,30,31,30,31/
      integer adays(nmonths) ! # of days of each of the 312 months 
      integer adays2(12,nyears)
      equivalence (adays, adays2)

c directories
      logical f_exist
      character*256 dir_out   ! output directory
      character*256 dir_run   ! run directory
      character*256 fcwd      ! current working directory

      integer date_time(8)  ! arrrays for date 
      character*10 bb(3)
      character*256 fdate 

c --------------
c Read MITgcm timing information 
      open (50, file='mitgcm_timing.nml', status='old')
      read(50, nml=mitgcm_timing)
      close (50)
      hour26yr = hour26yr_fwd

c ---------
c Assign number of days in each month
      do i=1,nyears
         adays2(:,i) = mdays(:)
      enddo
      
      do i=1,nyears,4   ! leap year starting from first (1992)
         adays2(2,i) = 29
      enddo      

c --------------
c Set directory where tool files exist (setup directory)
      open (50, file='tool_setup_dir')
      read (50,'(a)') setup
      close (50)
      
c --------------
c Set directory where tool files exist
      open (50, file='input_setup_dir')
      read (50,'(a)') f_inputdir
      close (50)

c --------------
c Get model grid info
      call grid_info
      
c --------------
c Interactive specification of Gradient Denominator (Perturbation) 
      write (6,"(/,a,/)") 'Forward Gradient Tool ... '
      write (6,*) 'Define control perturbation ' //
     $     '(denominator in Eq 2 of Guide) ... '

c --------------
c xx variable name, unit and description

c Atmospheric forcing controls 
      f_xx(1) = 'empmr'
      f_xx(2) = 'pload'   
      f_xx(3) = 'qnet'    
      f_xx(4) = 'qsw'     
      f_xx(5) = 'saltflux'
      f_xx(6) = 'spflx'   
      f_xx(7) = 'tauu'    
      f_xx(8) = 'tauv'    

      f_xx_unit(1) = 'kg/m2/s (upward freshwater flux)'
      f_xx_unit(2) = 'N/m2 (downward surface pressure loading)'
      f_xx_unit(3) = 'W/m2 (net upward heat flux)'
      f_xx_unit(4) = 'W/m2 (net upward shortwave radiation)'     
      f_xx_unit(5) = 'g/m2/s (net upward salt flux)'
      f_xx_unit(6) = 'g/m2/s (net downward salt plume flux)'
      f_xx_unit(7) = 'N/m2 (westward wind stress)'     
      f_xx_unit(8) = 'N/m2 (southward wind stress)'     

      scale(1) = -0.001
      scale(2) =  100.
      scale(3) = -10.
      scale(4) = -10. 
      scale(5) = -0.0001
      scale(6) =  0.0001
      scale(7) = -0.1
      scale(8) = -0.1

c Initial Condition (IC) and Mixing Parameters
      f_xx(9)  = 'etan'
      f_xx(10) = 'theta'
      f_xx(11) = 'salt'
      f_xx(12) = 'uvel'
      f_xx(13) = 'vvel'
      f_xx(14) = 'diffkr'
      f_xx(15) = 'kapgm'  
      f_xx(16) = 'kapredi'   

      f_xx_unit(9)  = 'm (initial sea level)'
      f_xx_unit(10) = 'degC (initial temperature)'
      f_xx_unit(11) = 'PSU (initial salinity)'
      f_xx_unit(12) = 'm/s (initial uvel)'
      f_xx_unit(13) = 'm/s (initial vvel)'
      f_xx_unit(14) = 'm2/s (vertical diffusivity)'
      f_xx_unit(15) = 'm2/s (GM diffusivity)'
      f_xx_unit(16) = 'm2/s (Redi along isopycnal diffusivity)'

      scale(9)  =  0.1
      scale(10) =  1.
      scale(11) = -1.
      scale(12) =  0.05
      scale(13) =  0.05
      scale(14) =  1.e-6
      scale(15) =  100.
      scale(16) =  100.

c --------------
c Save OBJF information for reference. 
      file_out = 'fgrd_spec.info'
      open (51, file=file_out, action='write')
      write(51,"(a)") '***********************'
      write(51,"(a)") 'Output of fgrd_spec.f'
      write(51,"(a)")
     $     'Perturbation specification'
      write(51,"(a,/)") '***********************'

c --------------
c Select to perturb forcing or IC/parameters
      write(6,'(a)') 'Enter 1 to perturb atmospheric forcing, '
      write(6,'(a)')
     $     '      2 to perturb IC or mixing parameters ... (1/2)?'
      read(5,*) ipert
      if (ipert .eq. 2) goto 2000
      
      write(6,'(/,a,/)') 'Perturbing atmospheric forcing ... '

c --------------
c Interactive specification of perturbation 

c control variable 
      check_v = 0

      write (6,*) 'Available control variables to perturb ... '
      do i=1,nctrl2
         write (6,"('   ',i2,') ',a)") i,trim(f_xx(i))
      enddo
      do while (check_v .eq. 0) 
         write (6,"(3x,a,i2,a)")
     $     'Enter control (phi in Eq 2 of Guide) ... (1-',nctrl2,') ?'
         read (5,*) pert_v
         if (pert_v .ge. 1 .and. pert_v .le. nctrl2) check_v = 1
      end do
      write (6,*) ' ..... perturbing ',trim(f_xx(pert_v))
      write (6,*) 

      write (51,*) ' ..... perturbing ',trim(f_xx(pert_v))

c Select spatial location (native or lat/lon)
      call slct_2d_pt(pert_i, pert_j)
      pert_k = 1 

c
      write(6,*) ' ...... perturbation at (i,j) = ',pert_i,pert_j
      write(6,1004) 
     $           '        C-grid is (long E, lat N) = ',
     $     xc(pert_i,pert_j),yc(pert_i,pert_j)
 1004 format(a,1x,f6.1,1x,f5.1)
      write(6,1005) 
     $           '        Depth (m) = ',
     $     bathy(pert_i,pert_j)
 1005 format(a,1x,f7.1)
      write (6,*) 

      write(51,*) ' ...... perturbation at (i,j) = ',pert_i,pert_j
      write(51,1004) 
     $           '        C-grid is (long E, lat N) = ',
     $     xc(pert_i,pert_j),yc(pert_i,pert_j)
      write(51,1005) 
     $           '        Depth (m) = ',
     $     bathy(pert_i,pert_j)

c time (week)
      check_t = 0
      do while (check_t .eq. 0) 
         write (6,"(a,i4,a)")
     $    'Enter week to perturb (s in Eq 2) ... (1-',nwk,') ?'
cif         write (6,"(a)") '(Week 1 centered 12Z 1/1/1992.)'
         read (5,*) pert_t
         if (pert_t .ge. 1 .and. pert_t .le. nwk) check_t = 1
      end do
      write(6,*) ' ...... perturbing week = ',pert_t
      write (6,*) 

      write(51,*) ' ...... perturbing week = ',pert_t

c amplitude
      pert_a = scale(pert_v)

      write(6,"(a,1x,e12.4)")
     $     'Default perturbation (delta_phi in Eq 4 of Guide) : '
      write(6,"(8x,e12.4,1x,'in unit ',a)") pert_a, f_xx_unit(pert_v)

      write (6,*) 'Enter 1 to keep, 9 to change ... ?'
      read (5,*) check_a
      if (check_a .eq. 9) then 
         write (6,*) '   Enter perturbation magnitude ... ?'
         read (5,*) pert_a
      endif

      write(6,"(a,1x,e12.4)") 'Perturbation amplitude = ',pert_a
      write(6,"(8x,'in unit ',a,/)") f_xx_unit(pert_v)

      write(51,"(a,1x,e12.4)") 'Perturbation amplitude = ',pert_a
      write(51,"(8x,'in unit ',a,/)") f_xx_unit(pert_v)

c --------------
c Set integration time 
      write(6,*) 'V4r4 can integrate 312-months from ' //
     $     '1/1/1992 12Z to 12/31/2017 12Z'
      write(6,"(a,i0,a,/)") 'which requires ', hour26yr,
     $     ' hours wallclock time.'

c ......................................
c Allow integration start time other than 1/1/1992 13Z
c First ID year of perturbation
      pert_h = (pert_t-1)*24*7 - 24*7/2   ! First time-step affected by pert_t 
      if (pert_h .lt. 1) then pert_h=1

c Read full pathname to emu_ref directory
      call getarg(1,f_input)

c Create full pathname to emu_ref directory 
c (where pickup files are)
      f_emuref = trim(f_input) // '/emu_ref'

c Get time-stamp for all pickup files
      call get_pkup_hours(f_emuref, pkuphrs, n_pkuphrs) 

c Find latest pickup file before perturbation. 
      niter0 = 1
      niter0_yr = 1
      do i=1,n_pkuphrs
         if (pkuphrs(i).gt.pert_h) exit 
         niter0 = pkuphrs(i)
         niter0_yr = i+1  ! 1 is 1992
      enddo

      idum = 1992+(niter0_yr-1)
      idum_day = INT( (pert_h-niter0)/24 ) 
      write(6,'(/,a,i0,a,i0)')
     $     'Chosen perturbation affects state from year day ',
     $     idum_day,' of year ', idum 
      write(6,'(a,i0,a)')
     $     'Enter year to begin integration ... (1992-',idum,')?'
      read (5,*) idum
      niter0_yr = idum - 1992  + 1
      niter0_mn = 12*(niter0_yr-1) + 1
      if (niter0_yr.eq.1) then
         niter0 = 1
      else
         niter0 = pkuphrs(niter0_yr-1)
      endif      

      write(6,'(a,i10,a)') 'Model will be integrated from ',
     $     niter0,' (1992 hours)'
      write(6,'(a,i4,/)') 'i.e., 01 January ',1992+(niter0_yr-1)

      write(51,'(a,i10,a)') 'Model will be integrated from ',
     $     niter0,' (1992 hours)'
      write(51,'(a,i4,/)') 'i.e., 01 January ',1992+(niter0_yr-1)

      goto 3000
c ......................................
 2000 continue
      write(6,'(/,a,/)') 'Perturbing IC or mixing parameters ... '

c --------------
c Interactive specification of perturbation 

c control variable 
      check_v = 0

      write (6,*) 'Available control variables to perturb ... '
      do i=nctrl2+1,nctrl
         write (6,"('   ',i2,') ',a)") i,trim(f_xx(i))
      enddo
      do while (check_v .eq. 0) 
         write (6,"(3x,a,i2,a,i2,a)")
     $     'Enter control (phi in Eq 2 of Guide) ... (',
     $        nctrl2+1,'-',nctrl,') ?'
         read (5,*) pert_v
         if (pert_v .ge. nctrl2+1 .and. pert_v .le. nctrl) check_v = 1
      end do

      write (6,*) ' ..... perturbing ',trim(f_xx(pert_v))
      write (6,*) 

      write (51,*) ' ..... perturbing ',trim(f_xx(pert_v))

c Select spatial location 
      if (pert_v .eq. nctrl2+1) then 
         call slct_2d_pt(pert_i, pert_j)
         pert_k = 1
      else
         call slct_3d_pt(pert_i, pert_j, pert_k)
      endif

c Select week to perturb 
      pert_t = 1

c amplitude
      pert_a = scale(pert_v)

      write(6,"(a,1x,e12.4)")
     $     'Default perturbation (delta_phi in Eq 4 of Guide) : '
      write(6,"(8x,e12.4,1x,'in unit ',a)")
     $     pert_a, f_xx_unit(pert_v)

      write (6,*) 'Enter 1 to keep, 9 to change ... ?'
      read (5,*) check_a
      if (check_a .eq. 9) then 
         write (6,*) '   Enter perturbation magnitude ... ?'
         read (5,*) pert_a
      endif

      write(6,"(a,1x,e12.4)") 'Perturbation amplitude = ',pert_a
      write(6,"(8x,'in unit ',a,/)") f_xx_unit(pert_v)

      write(51,"(a,1x,e12.4)") 'Perturbation amplitude = ',pert_a
      write(51,"(8x,'in unit ',a,/)") f_xx_unit(pert_v)

c --------------
c Set integration time 
      write(6,*) 'V4r4 can integrate 312-months from ' //
     $     '1/1/1992 12Z to 12/31/2017 12Z'
      write(6,"(a,i0,a,/)") 'which requires ', hour26yr,
     $     ' hours wallclock time.'

c ......................................
c Allow integration start time other than 1/1/1992 13Z

c Read full pathname to emu_ref directory
      call getarg(1,f_input)

c Create full pathname to emu_ref directory 
c (where pickup files are)
      f_emuref = trim(f_input) // '/emu_ref'

c Get time-stamp for all pickup files
      call get_pkup_hours(f_emuref, pkuphrs, n_pkuphrs) 

c Find last pickup file
      niter0 = pkuphrs(n_pkuphrs)
      niter0_yr = n_pkuphrs+1       ! 1 is 1992

c Choose year to begin integration 
      idum = 1992+(niter0_yr-1)
      idum_day = INT( (pert_h-niter0)/24 ) 
      write(6,'(a,i0,a)')
     $     'Enter year to begin integration ... (1992-',idum,')?'
      read (5,*) idum
      niter0_yr = idum - 1992  + 1
      niter0_mn = 12*(niter0_yr-1) + 1
      if (niter0_yr.eq.1) then
         niter0 = 1
      else
         niter0 = pkuphrs(niter0_yr-1)
      endif      

      write(6,'(a,i10,a)') 'Model will be integrated from ',
     $     niter0,' (1992 hours)'
      write(6,'(a,i4,/)') 'i.e., 01 January ',1992+(niter0_yr-1)

      write(51,'(a,i10,a)') 'Model will be integrated from ',
     $     niter0,' (1992 hours)'
      write(51,'(a,i4,/)') 'i.e., 01 January ',1992+(niter0_yr-1)

c ......................................
 3000 continue

c ......................................
c Set integration end time
      nmon_left = 312 - (niter0_yr-1)*12
      write(6,"(a,i0,a)")
     $     'Enter number of months to integrate (Max t in Eq 2)'
     $     //'... (1-', nmon_left, ')?'
      read(5,*) iend
      if (iend .gt. nmon_left) then 
         iend = nmon_left
      else if (iend .lt. 1) then 
         iend = 1
      endif
      write(6,'(a,i3,a,/)') 'Will integrate model over ',
     $     iend,' months'

      write(51,'(a,i3,a,/)') 'Will integrate model over ',
     $     iend,' months'

c set nTimesteps in data 
      ndays = sum(adays(niter0_mn:niter0_mn+iend-1)) 
      nTimesteps = ndays*24 
      if (nTimesteps+niter0 .gt. nsteps) nTimesteps=nsteps-niter0

      f_command = 'cp -f data_emu data'
      call execute_command_line(f_command, wait=.true.)

      write(fstep,'(i24)') niter0
      call StripSpaces(fstep)
      f_command = 'sed -i -e "s|NITER0_EMU|'//
     $     trim(fstep) //'|g" data'
      call execute_command_line(f_command, wait=.true.)

      write(fstep,'(i24)') nTimesteps
      call StripSpaces(fstep)
      f_command = 'sed -i -e "s|NSTEP_EMU|'//
     $     trim(fstep) //'|g" data'
      call execute_command_line(f_command, wait=.true.)

c set walltime for computation 
      f_command = 'cp -f pbs_fgrd.sh_orig pbs_fgrd.sh'
      call execute_command_line(f_command, wait=.true.)

      nHours = ceiling(float(nTimesteps)/float(nsteps-1)
     $     *float(hour26yr))
      write(fstep,'(i24)') nHours
      call StripSpaces(fstep)
      f_command = 'sed -i -e "s|WHOURS_EMU|'//
     $     trim(fstep) //'|g" pbs_fgrd.sh'
      call execute_command_line(f_command, wait=.true.)

      if (nHours .le. 2) then 
         f_command = 'sed -i -e "s|CHOOSE_DEVEL|'//
     $        'PBS -q devel|g" pbs_fgrd.sh'
         call execute_command_line(f_command, wait=.true.)
      endif

c 
      write(6,"(3x,a)") '... Program has set computation periods '
     $    // 'in files data and pbs_fgrd.sh accordingly.'
      write(6,"(3x,a,i4,/)") '... Estimated wallclock hours is '
     $     ,nHours

c --------------
c Output Perturbation specification to namelist file

      file_out = 'fgrd_pert.nml'

c      inquire (file=trim(file_out), EXIST=file_exists)
c      if (file_exists) then
c         write (6,*) ' **** Error: namelist file = ',
c     $        trim(file_out) 
c         write (6,*) '**** already exists'
c         stop
c      endif

      open (50, file=file_out, action='write')
      write(50, nml=PERT_SPEC) 
      close (50)

      write (6,*) 'Wrote ',trim(file_out)

c Also create concatenated string for creating run director
      if (pert_a .ne. 0.) then 
         write(f_command,1001) pert_v, pert_i, pert_j, pert_k,
     $        pert_t, pert_a
 1001    format(i9,"_",i9,"_",i9,"_",i9,"_",i9,"_",1p e12.2)
      else 
         write(f_command,'(a)') 'ref'
      endif
      call StripSpaces(f_command)

      file_out = 'fgrd_pert.str'
      open (50, file=file_out, action='write')
      write(50,'(a)') trim(f_command)
      close(50)

      write (6,*) 'Wrote ',trim(file_out)

      close (51)

c Setup run directory
      dir_out = 'emu_fgrd_' // trim(f_command)
      write(6,"(/,a,a,/)")
     $     'Forward Gradient Tool output will be in : ',trim(dir_out)

      inquire (file=trim(dir_out), EXIST=f_exist)
      if (f_exist) then
         write (6,*) '**** WARNING: Directory exists already : ',
     $        trim(dir_out) 
         call date_and_time(bb(1), bb(2), bb(3), date_time)
         write(fdate,"('_',i4.4,2i2.2,'_',3i2.2)")
     $     date_time(1:3),date_time(5:7)
         dir_out = trim(dir_out) // trim(fdate)
         write(6,"(/,a,a,/)")
     $        '**** Renaming output directory to :',trim(dir_out)
      endif

      f_command = 'mkdir ' // trim(dir_out)
      call execute_command_line(f_command, wait=.true.)
      call getcwd(fcwd)
      dir_run = trim(fcwd) // '/' // trim(dir_out) // '/temp'
      f_command = 'mkdir ' // dir_run
      call execute_command_line(f_command, wait=.true.)
      
      file_out = 'fgrd.dir_out'
      open (52, file=file_out, action='write')
      write(52,"(a)") trim(dir_out)
      write(52,"(a)") trim(dir_run)
      write(52,"(a)") trim(dir_out) // '/output'
      close(52)

c Move all needed files into run directory
      f_command = 'mv data ' // trim(dir_run) // '/data_fgrd'
      call execute_command_line(f_command, wait=.true.)
      
      f_command = 'mv fgrd_spec.info ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

      f_command = 'mv fgrd_pert.nml ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

      f_command = 'mv fgrd_pert.str ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

      stop
      end
