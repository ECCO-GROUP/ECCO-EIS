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
      integer pert_v, pert_i, pert_j, pert_t
      real*4 pert_a, pert_x, pert_y
      namelist /PERT_SPEC/ pert_v, pert_i, pert_j, pert_t, pert_a

      integer check_v, check_i, check_j, check_t, check_a, check_d

c 
      integer nctrl                    ! number of controls 
      parameter (nctrl=8) 
      character*130 file_in, file_out  ! file names 
      logical file_exists
      character*72 f_xx(nctrl), f_xx_unit(nctrl)
      character*256 f_command
      
      integer nx, ny, nwk 
      parameter (nx=90, ny=1170, nr=50, nwk=1358)
      real*4 scale(nx,ny)              ! default perturbation

      real*4 xc(nx,ny), yc(nx,ny), bathy(nx,ny)
      integer iloc

      integer i
      character*256 setup

c Integration time 
      integer iend, nsteps
      parameter(nsteps=227903) ! max steps of V4r4
      integer nTimesteps, nHours, hour26yr
      character*24 fstep 

      integer nproc, hour26yr_trc, hour26yr_fwd, hour26yr_adj
      namelist /mitgcm_timing/ nproc, hour26yr_trc,
     $     hour26yr_fwd, hour26yr_adj

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

c --------------
c Set directory where tool files exist (setup directory)
      open (50, file='tool_setup_dir')
      read (50,'(a)') setup
      close (50)
      
c --------------
c Read model grid
      file_in = trim(setup) // '/emu/emu_input/XC.data'
      inquire (file=trim(file_in), EXIST=file_exists)
      if (.not. file_exists) then
         write (6,*) ' **** Error: model grid file = ',
     $        trim(file_in) 
         write (6,*) '**** does not exist'
         stop
      endif
      open (50, file=file_in, action='read', access='stream')
      read (50) xc
      close (50)

      file_in = trim(setup) // '/emu/emu_input/YC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) yc
      close (50)

      file_in = trim(setup) // '/emu/emu_input/Depth.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) bathy
      close (50)
      
c --------------
c Interactive specification of Gradient Denominator (Perturbation) 
      write (6,"(/,a,/)") 'Forward Gradient Tool ... '
      write (6,*) 'Define control perturbation ' //
     $     '(denominator in Eq 2 of Guide) ... '

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
c xx variable name, unit and description
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

c --------------
c Interactive specification of perturbation 

c control variable 
      check_v = 0

      write (6,*) 'Available control variables to perturb ... '
      do i=1,nctrl
         write (6,"('   ',i2,') ',a)") i,trim(f_xx(i))
      enddo
      do while (check_v .eq. 0) 
         write (6,"(3x,a,i2,a)")
     $     'Enter control (phi in Eq 2 of Guide) ... (1-',nctrl,') ?'
         read (5,*) pert_v
         if (pert_v .ge. 1 .and. pert_v .le. nctrl) check_v = 1
      end do
      write (6,*) ' ..... perturbing ',trim(f_xx(pert_v))
      write (6,*) 

      write (51,*) ' ..... perturbing ',trim(f_xx(pert_v))

c Select spatial location (native or lat/lon)
      write (6,*) 'Choose location for perturbation ' //
     $     '(r in Eq 2 of Guide) ... '
      write (6,*) '   Enter 1 to choose native grid location (i,j),  '
      write (6,*)
     $     '         9 to select by longitude/latitude ... (1 or 9)? '
      read (5,*) iloc

      write(51,"(3x,'iloc = ',i2)") iloc 

      if (iloc .ne. 9) then 

c spatial location (native grid point)
         check_i = 0
         check_j = 0
         check_d = 0

c         do while (check_d .eq. 0) 
            write (6,*) '   Enter native (i,j) grid to perturb ... '
            do while (check_i .eq. 0) 
               write (6,"('   i ... (1-',i2,') ?')") nx
               read (5,*) pert_i
               if (pert_i .ge. 1 .and. pert_i .le. nx) check_i = 1
            end do
            do while (check_j .eq. 0) 
               write (6,"('   j ... (1-',i4,') ?')") ny
               read (5,*) pert_j
               if (pert_j .ge. 1 .and. pert_j .le. ny) check_j = 1
            end do
cc make sure point is wet      
c            if (bathy(pert_i,pert_j) .le. 0.) then
c               write (6,1016) '   C-grid point is dry. Depth (m)= ',
c     $              bathy(pert_i,pert_j)
c 1016          format(a,f7.1,' Try again.')
c               check_i = 0
c               check_j = 0
c            else
c               check_d = 1
c            endif
c         enddo

      else 
c choosing by long/lat 
         check_d = 0
         write (6,*) '   Enter lon/lat (x,y) grid to perturb ... '
         do while (check_d .eq. 0) 
            write (6,*) '   longitude ... (E)?'
            read (5,*) pert_x

            write (6,*) '   latitude ... (N)?'
            read (5,*) pert_y

            call ijloc(pert_x,pert_y,pert_i,pert_j,xc,yc,nx,ny)
c make sure point is wet      
            if (bathy(pert_i,pert_j) .le. 0.) then
               write (6,1007) pert_i,pert_j
 1007          format('   Closest (i,j) is (',i2,1x,i4,')')
               write (6,1006) '   C-grid point is dry. Depth (m)= ',
     $              bathy(pert_i,pert_j)
 1006          format(a,f7.1,' Try again.')
            else
               check_d = 1
            endif
         end do
      endif

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
         read (5,*) pert_t
         if (pert_t .ge. 1 .and. pert_t .le. nwk) check_t = 1
      end do
      write(6,*) ' ...... perturbing week = ',pert_t
      write (6,*) 

      write(51,*) ' ...... perturbing week = ',pert_t

c amplitude
      file_in = trim(setup) // '/emu/emu_input/fgrd_pert.scale'
      inquire (file=trim(file_in), EXIST=file_exists)
      if (.not. file_exists) then
         write (6,*) ' **** Error: default perturbation scale file = ',
     $        trim(file_in) 
         write (6,*) '**** does not exist'
         stop
      endif
      
      open (50, file=file_in, action='read', access='direct',
     $     recl=nx*ny*4, form='unformatted')
      read (50,rec=pert_v) scale
      close (50)

      pert_a = scale(pert_i,pert_j)
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
      write(6,*) 'V4r4 integrates 312-months from ' //
     $     '1/1/1992 12Z to 12/31/2017 12Z'
      write(6,"(a,i0,a)") 'which requires ', hour26yr,
     $     ' hours wallclock time.'
      write(6,*) 'Enter number of months to integrate (Max t in Eq 2)'
     $     //'... (1-312)?'
      read(5,*) iend
      if (iend .gt. 312) then 
         iend = 312
      else if (iend .lt. 1) then 
         iend = 1
      endif
      write(6,'(a,i3,a,/)') 'Will integrate model over ',
     $     iend,' months'

      write(51,'(a,i3,a,/)') 'Will integrate model over ',
     $     iend,' months'

c set nTimesteps in data to 1-month beyond iend
c     to make sure computation is complete,.
      nTimesteps = (iend/12)*365*24 +
     $     mod(iend,12)*30*24 + 30*24*1
      if (nTimesteps .gt. nsteps) nTimesteps=nsteps

      f_command = 'cp -f data_emu data'
      call execute_command_line(f_command, wait=.true.)

      write(fstep,'(i24)') nTimesteps
      call StripSpaces(fstep)
      f_command = 'sed -i -e "s|NSTEP_EMU|'//
     $     trim(fstep) //'|g" data'
      call execute_command_line(f_command, wait=.true.)

c set walltime for computation 
      f_command = 'cp -f pbs_fgrd.sh_orig pbs_fgrd.sh'
      call execute_command_line(f_command, wait=.true.)

      nHours = ceiling(float(nTimesteps)/float(nsteps)
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
         write(f_command,1001) pert_v, pert_i, pert_j, pert_t, pert_a
 1001    format(i9,"_",i9,"_",i9,"_",i9,"_",1p e12.2)
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
