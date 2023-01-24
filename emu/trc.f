      program trc
c -----------------------------------------------------
c Program for Passive Tracer Tool (V4r4)
c Set up data file for passive tracer integration by pbs_trc.csh. 
c     
c 30 November 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces
c files
      character*256 tooldir   ! directory where tool files are 
      common /tool/tooldir
      character*130 file_in, file_out  ! file names 
c
      character*256 f_command 
      logical f_exist

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny)
      common /grid/xc, yc, rc, bathy

      real*4 dum3d(nx,ny,nr) 
      character*256 fmask, fdum
      integer pert_i, pert_j, pert_k

c Strings for naming output directory
      character*256 floc_time ! TRC time-period
      character*256 floc_loc  ! starting TRC location/value
      character*256 dir_out   ! output directory
      character*256 dir_run   ! run directory
      character*256 fcwd      ! current working directory
      integer istart, iend 
      integer nIter0
      character*256 fIter0

      integer date_time(8)  ! arrrays for date 
      character*10 bb(3)
      character*256 fdate 

c Integration time 
      integer nsteps
c      parameter(nsteps=227903) ! max steps of V4r4
      parameter(nsteps=227808, nhweek=84) ! max steps 
      integer nTimesteps, nHours, hour26yr, nTmax 
      parameter(hour26yr=3) ! wallclock hours for nsteps 
      character*256 fstep 
      character*256 f_ref, f_pup, f_dum 

c --------------
c Set directory where tool files exist
      open (50, file='tool_setup_dir')
      read (50,'(a)') tooldir
      close (50)

c --------------
c Read model grid
      file_in = trim(tooldir) // '/emu_pert_ref/XC.data'
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

      file_in = trim(tooldir) // '/emu_pert_ref/YC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) yc
      close (50)

      file_in = trim(tooldir) // '/emu_pert_ref/RC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) rc
      close (50)
      rc = -rc  ! switch sign 

      file_in = trim(tooldir) // '/emu_pert_ref/Depth.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) bathy
      close (50)
      
c --------------
c Interactive specification of Tracer
      write (6,"(/,a,/)") 'Passive Tracer Tool ... '
      write (6,*) 'Define passive tracer distribution ... '

c --------------
c Save OBJF information for reference. 
      file_out = 'trc.info'
      open (51, file=file_out, action='write')
      write(51,"(a)") '***********************'
      write(51,"(a)") 'Output of trc.f'
      write(51,"(a)")
     $     'Passive Tracer specification'
      write(51,"(a,/)") '***********************'

c --------------
c time (day) 
      write (6,"(/,a)") '------------------'
      write (6,"(a)") 'Enter START and END days of integration ... '
      write (6,"(a)")
     $     '(days since 01 January 1992, between 1 and 9495)' 
      write (6,"(/,3x,a)")
     $     'Tool computes forward tracer when START lt END and '
      write (6,"(3x,a,/)") 'adjoint tracer when START gt END.'

      istart = -1
      iend = -1
      do while (istart.lt.0 .or. istart.gt.9495) 
         write (6,"(a)") 'Enter start day ... (1-9495)?'
         read (5,*) istart
      enddo
      do while (iend.lt.0 .or. iend.gt.9495) 
         write (6,"(a)") 'Enter end day ... (1-9495)?'
         read (5,*) iend 
      enddo

      write (6,"(/,a,1x,i0,1x,i0)") 'Start and End days = ',
     $     istart,iend

      write(51,2001) istart,iend
 2001 format(3x,'istart, iend = ',i4,2x,i4)
      write(51,"(3x,a,/)") ' --> Start and End days of TRC integration.'

      write(floc_time,'(i9,"_",i9)') istart,iend
      call StripSpaces(floc_time)

      tmode = 1  ! default for foward
      if (istart .gt. iend) tmode = 2

c Modify data and pbs_trc.csh files for istart/iend 
      f_command = 'cp -f data_trc data'
      call execute_command_line(f_command, wait=.true.)
      f_command = 'cp -f pbs_trc.csh_orig pbs_trc.csh_tmp'
      call execute_command_line(f_command, wait=.true.)

      if (tmode.eq.1) then ! forward tracer
         write(6,"(/,a)") '---------------------------------'
         write(6,"(3x,a)") 'Forward tracer computation '          
         write(6,"(a,/)") '---------------------------------'

         write(51,"(3x,a,/)") ' --> Forward tracer computation '          

         nIter0 = istart*24
         nTimesteps = (iend-istart)*24 
         if (nIter0 + nTimesteps .gt. nsteps-nhweek) then
            nTimesteps = (nsteps-nhweek) - nIter0 - 1 
         endif
c
         write(fstep,'(a)') 'build_trc'
         call StripSpaces(fstep)
         f_command = 'sed -i -e "s|FRW_OR_ADJ|'//
     $        trim(fstep) //'|g" pbs_trc.csh_tmp'
         call execute_command_line(f_command, wait=.true.)

         write(fstep,'(a)') 'state_weekly'
         call StripSpaces(fstep)
         f_command = 'sed -i -e "s|STATE_DIR|'//
     $        trim(fstep) //'|g" pbs_trc.csh_tmp'
         call execute_command_line(f_command, wait=.true.)

      else  ! adjoint tracer
         write(6,"(/,a)") '---------------------------------'
         write(6,"(3x,a)") 'Adjoint tracer computation ' 
         write(6,"(a,/)") '---------------------------------'

         write(51,"(3x,a,/)") ' --> Adjoint tracer computation '          

         nIter0 = (nsteps-istart*24)
         nTimesteps = abs(iend-istart)*24 
         if (nIter0 + nTimesteps .gt. nsteps-nhweek) then
            nTimesteps = (nsteps-nhweek) - nIter0 - 1 
         endif
c 
         write(fstep,'(a)') 'build_trc_adj'
         call StripSpaces(fstep)
         f_command = 'sed -i -e "s|FRW_OR_ADJ|'//
     $        trim(fstep) //'|g" pbs_trc.csh_tmp'
         call execute_command_line(f_command, wait=.true.)

         write(fstep,'(a)') 'state_weekly_rev_time_227808'
         call StripSpaces(fstep)
         f_command = 'sed -i -e "s|STATE_DIR|'//
     $        trim(fstep) //'|g" pbs_trc.csh_tmp'
         call execute_command_line(f_command, wait=.true.)

      endif

c Set integration time (in data and pbs_trc.csh_tmp)         
      write(fstep,'(i24)') nIter0
      call StripSpaces(fstep)
      f_command = 'sed -i -e "s|nIter0_EMU|'//
     $     trim(fstep) //'|g" data'
      call execute_command_line(f_command, wait=.true.)

      write(fstep,'(i24)') nTimesteps
      call StripSpaces(fstep)
      f_command = 'sed -i -e "s|NSTEP_EMU|'//
     $     trim(fstep) //'|g" data'
      call execute_command_line(f_command, wait=.true.)

c wall clock (~8 min per year integration)
      nHours = ceiling(float(nTimesteps)/float(nsteps)
     $     *float(hour26yr))
      write(fstep,'(i24)') nHours
      call StripSpaces(fstep)
      f_command = 'sed -i -e "s|WHOURS_EMU|'//
     $     trim(fstep) //'|g" pbs_trc.csh_tmp'
      call execute_command_line(f_command, wait=.true.)
         
      if (nHours .le. 2) then 
         f_command = 'sed -i -e "s|CHOOSE_DEVEL|'//
     $        'PBS -q devel|g" pbs_trc.csh_tmp'
         call execute_command_line(f_command, wait=.true.)
      endif

c ---------------------
c bandaid pickup 
      f_pup = 'pickup_ggl90.' ! bandaid 
      write(fstep,"(i10.10)") 1
      f_ref = trim(f_pup) // trim(fstep) // '.data'
      write(fIter0,"(i10.10)") nIter0
      f_dum = trim(f_pup) // trim(fIter0) // '.data'
      f_command = 'ln -s ' // trim(f_ref) // ' ' // trim(f_dum)
      f_dum = 'sed -i -e "s|# BANDAID_PICKUP|'//
     $     trim(f_command) //'|g" pbs_trc.csh_tmp'
      call execute_command_line(f_dum, wait=.true.)

      f_command = 'cp -f pickup_ptracer.meta_orig pickup_ptracer.meta'
      call execute_command_line(f_command, wait=.true.)

      write(fIter0,"(1P E18.12)") float(nIter0)*3600.
      f_dum = 'sed -i -e "s|nIter0_SEC|'//
     $     trim(fIter0) //'|g" pickup_ptracer.meta'
      call execute_command_line(f_dum, wait=.true.)

      write(fstep,"(i24)") nIter0
      f_dum = 'sed -i -e "s|nIter0|'//
     $     trim(fstep) //'|g" pickup_ptracer.meta'
      call execute_command_line(f_dum, wait=.true.)

         
c --------------
c Set tracer distribution at start time 
c 
c      write (6,"(/,a)") '------------------'
      write (6,"(a)") 'Enter tracer at start time ... '

c Select tracer at point with unit value or user-provided distribution
      ifunc = 0
      do while (ifunc.ne.1 .and. ifunc.ne.2) 
         write (6,"(a)") 'Choose either unit tracer at a point (1) or '
         write (6,"(a)") 'user-provided distribution in a file (2) ' //
     $      ' ... (1/2)?'
         read (5,*) ifunc
      end do

      write(51,"(3x,'ifunc = ',i2)") ifunc

      if (ifunc .eq. 1) then 
c Tracer is at a point

         write(6,"(3x,a)")
     $        '... starting TRC is unit value at a point.' 
         write(51,"(3x,a,/)")
     $        '... starting TRC is unit value at a point.' 

         call slct_3d_pt(pert_i,pert_j,pert_k)

         write(51,2002) pert_i,pert_j,pert_k
 2002    format(3x,'pert_i, pert_j, pert_k = ',i2,2x,i4,2x,i2)
         write(51,"(3x,a,/)") ' --> TRC at model grid location (i,j,k).'
         write(51,"(9x,a,f6.1,1x,f5.1,1x,f9.2)") 
     $        'C-grid is (long E, lat N, depth m) = ',
     $        xc(pert_i,pert_j),yc(pert_i,pert_j),rc(pert_k)
         write(51,"(9x,a,f7.1,/)") 'Ocean depth (m)= ',
     $        bathy(pert_i,pert_j)

c Create 3d mask for the point 
         dum3d = 0.
         dum3d(pert_i,pert_j,pert_k) = 1. 

         fmask = 'trc_ic' 
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) dble(dum3d)
         close(60)

c Save location for naming run directory
         write(floc_loc,'(i9,"_",i9,"_",i9)') pert_i,pert_j,pert_k
         call StripSpaces(floc_loc)

      else
c User-provided start time tracer

         write(6,"(3x,a,/)")
     $        '... starting TRC is user-defined. '
         write(51,"(3x,a,/)")
     $        '... starting TRC is user-defined. '

c Get starting tracer file name 
         write(6,*) '   Enter starting TRC filename (real*8) ... ?'  
         read(5,'(a)') fmask

         write(51,'(3x,"fmask = ",a)') trim(fmask)
         write(51,"(3x,a,/)") ' --> starting TRC file. '

c Save file name for naming run directory
         floc_loc = trim(fmask)
         call StripSpaces(floc_loc)

      endif

c Check user file 
c      call chk_mask3d(fmask,nx,ny,nr,dum3d)  ptracer is real*8

c Link input mask to what model expects 
      write(fIter0,"(i10.10)") nIter0
      fdum = 'pickup_ptracers.' // trim(fIter0) // '.data'
      INQUIRE(FILE=trim(fdum), EXIST=f_exist)
      if (f_exist) then
         f_command = 'rm -f ' // trim(fdum)
         call execute_command_line(f_command, wait=.true.)
      endif

      f_command = 'ln -s ' // trim(fmask) // ' ' //
     $     trim(fdum)
      call execute_command_line(f_command, wait=.true.)

c for meta
      fdum = 'pickup_ptracers.' // trim(fIter0) // '.meta'
      INQUIRE(FILE=trim(fdum), EXIST=f_exist)
      if (f_exist) then
         f_command = 'rm -f ' // trim(fdum)
         call execute_command_line(f_command, wait=.true.)
      endif

      f_command = 'ln -s pickup_ptracer.meta ' // 
     $     trim(fdum)
      call execute_command_line(f_command, wait=.true.)

      close (51)

c Create output directory 
      write(f_command,1001) trim(floc_time),trim(floc_loc)
 1001 format(a,"_",a)
      call StripSpaces(f_command)

      dir_out = 'emu_trc_' // trim(f_command)
      write(6,"(/,a,a,/)")
     $     'Tracer Tool output will be in : ',trim(dir_out)

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

      file_out = 'trc.dir_out'
      open (52, file=file_out, action='write')
      write(52,"(a)") trim(dir_out)
      write(52,"(a)") trim(dir_run)
      write(52,"(a)") trim(dir_out) // '/output'
      close(52)

c Move all needed files into run directory
      f_command = 'sed -i -e "s|YOURDIR|'//
     $     trim(dir_run) //'|g" pbs_trc.csh_tmp'
      call execute_command_line(f_command, wait=.true.)

      f_command = 'mv pbs_trc.csh_tmp pbs_trc.csh'  
      call execute_command_line(f_command, wait=.true.)

      f_command = 'mv pbs_trc.csh ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)
      
      f_command = 'ln -s ' // trim(dir_run) // '/pbs_trc.csh .'
      call execute_command_line(f_command, wait=.true.)
      
      f_command = 'mv data ' // trim(dir_run) // '/data_trc'
      call execute_command_line(f_command, wait=.true.)
      
      f_command = 'cp -p pickup_ptracers.00*.* ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)
      
      f_command = '/bin/rm -f pickup_ptracers.00*.* ' 
      call execute_command_line(f_command, wait=.true.)
      
      f_command = 'mv trc.info ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

c Wrapup 
      write(6,"(a)") '... Done trc setup'

      write(6,"(/,a)") '*********************************'
      f_command = 'do_trc.csh'
      write(6,"(4x,a)") 'Run "' // trim(f_command) //
     $     '" to compute tracer evolution.'
      write(6,"(a,/)") '*********************************'
      
      stop
      end
      
