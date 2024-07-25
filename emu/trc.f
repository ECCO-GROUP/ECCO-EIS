      program trc
c -----------------------------------------------------
c Program for Passive Tracer Tool (V4r4)
c Set up data file for passive tracer integration by pbs_trc.sh. 
c     
c 30 November 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces
c files
      character*256 tooldir    ! directory where tool files are 
      character*256 inputdir   ! directory where tool input files are 
      common /tool/inputdir
      character*130 file_in, file_out  ! file names 
c
      character*256 f_command 
      logical f_exist

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

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
c      parameter(nsteps=227808, nhweek=84) ! max steps
      parameter(nsteps=227639, nhweek=84) ! max steps 
      integer nTimesteps, nHours, hour26yr, nTmax 

      integer nproc, hour26yr_trc, hour26yr_fwd, hour26yr_adj
      namelist /mitgcm_timing/ nproc, hour26yr_trc,
     $     hour26yr_fwd, hour26yr_adj

      character*256 fstep 
      character*256 f_ref, f_pup, f_dum 

c --------------
c Read MITgcm timing information 
      open (50, file='mitgcm_timing.nml', status='old')
      read(50, nml=mitgcm_timing)
      close (50)
      hour26yr = hour26yr_trc 

c --------------
c Set directory where tool files exist
      open (50, file='input_setup_dir')
      read (50,'(a)') inputdir
      close (50)

cc --------------
cc Set directory where tool files exist
c      open (50, file='tool_setup_dir')
c      read (50,'(a)') tooldir
c      close (50)

c --------------
c Read model grid
      call grid_info
      
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
c     $     '(days since 01 January 1992, between 1 and 9496)'
     $     '(days between 1 and 9485)'
      write (6,"(a)") '(   1 being 02 January  1992)'
      write (6,"(a)") '(9485 being 20 December 2017)' 
      write (6,"(/,3x,a)")
     $     'Tool computes forward tracer when START lt END and '
      write (6,"(3x,a,/)") 'adjoint tracer when START gt END.'

      istart = -1
      iend = -1
      do while (istart.lt.0 .or. istart.gt.9485) 
         write (6,"(a)") 'Enter start day ... (1-9485)?'
         read (5,*) istart
      enddo
      do while (iend.lt.0 .or. iend.gt.9485) 
         write (6,"(a)") 'Enter end day ... (1-9485)?'
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

c Modify data and pbs_trc.sh files for istart/iend 
      f_command = 'cp -f data_trc data'
      call execute_command_line(f_command, wait=.true.)
cif      f_command = 'cp -f pbs_trc.sh_orig pbs_trc.sh_tmp'
cif      call execute_command_line(f_command, wait=.true.)

      if (tmode.eq.1) then ! forward tracer
         write(6,"(/,a)") '---------------------------------'
         write(6,"(3x,a)") 'Forward tracer computation '          
         write(6,"(a,/)") '---------------------------------'

         write(51,"(3x,a,/)") ' --> Forward tracer computation '          

         nIter0 = (istart-1)*24 + 12   ! 0Z of a day 
         nTimesteps = (iend-istart)*24
c         if (nIter0 + nTimesteps .gt. nsteps-nhweek) then
c            nTimesteps = (nsteps-nhweek) - nIter0 - 1 
c         endif
         if (nIter0 + nTimesteps .gt. nsteps) then
            nTimesteps = nsteps - nIter0
         endif
c
         write(fstep,'(a)') 'trc.x'
         call StripSpaces(fstep)
         f_command = 'sed -i -e "s|FRW_OR_ADJ|'//
     $        trim(fstep) //'|g" pbs_trc.sh'
cif     $        trim(fstep) //'|g" pbs_trc.sh_tmp'
         call execute_command_line(f_command, wait=.true.)

         write(fstep,'(a)') 'state_weekly'
         call StripSpaces(fstep)
         f_command = 'sed -i -e "s|STATE_DIR|'//
     $        trim(fstep) //'|g" pbs_trc.sh'
cif     $        trim(fstep) //'|g" pbs_trc.sh_tmp'
         call execute_command_line(f_command, wait=.true.)

      else  ! adjoint tracer
         write(6,"(/,a)") '---------------------------------'
         write(6,"(3x,a)") 'Adjoint tracer computation ' 
         write(6,"(a,/)") '---------------------------------'

         write(51,"(3x,a,/)") ' --> Adjoint tracer computation '          

c Tracer runs from 13Z 1/1/1992 (time-step 1) to
c 11Z 12/20/2017 (time-step 227639).
         nIter0 = (nsteps-(istart-1)*24-12)  
         nTimesteps = (istart-iend)*24 
         if (nIter0 + nTimesteps .gt. nsteps) then
            nTimesteps = nsteps - nIter0
         endif
c 
         write(fstep,'(a)') 'trc_ad.x'
         call StripSpaces(fstep)
         f_command = 'sed -i -e "s|FRW_OR_ADJ|'//
     $        trim(fstep) //'|g" pbs_trc.sh'
cif     $        trim(fstep) //'|g" pbs_trc.sh_tmp'
         call execute_command_line(f_command, wait=.true.)

         write(fstep,'(a)') 'state_weekly_rev_time_227808'
         call StripSpaces(fstep)
         f_command = 'sed -i -e "s|STATE_DIR|'//
     $        trim(fstep) //'|g" pbs_trc.sh'
cif     $        trim(fstep) //'|g" pbs_trc.sh_tmp'
         call execute_command_line(f_command, wait=.true.)

         write(fstep,'(a)') 'bash'
         call StripSpaces(fstep)
         f_command = 'sed -i -e "s|#REORDER_PTRACER|'//
     $        trim(fstep) //'|g" pbs_trc.sh'
         call execute_command_line(f_command, wait=.true.)

      endif

c Set integration time (in data and pbs_trc.sh_tmp)         
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
     $     trim(fstep) //'|g" pbs_trc.sh'
      call execute_command_line(f_command, wait=.true.)
         
      if (nHours .le. 2) then 
         f_command = 'sed -i -e "s|CHOOSE_DEVEL|'//
     $        'PBS -q devel|g" pbs_trc.sh'
         call execute_command_line(f_command, wait=.true.)
      endif

cc ---------------------
cc Set nproc 
c      write(fstep,'(i24)') nproc
c      call StripSpaces(fstep)
c      f_command = 'sed -i -e "s|EMU_NPROC|'//
c     $     trim(fstep) //'|g" pbs_trc.sh'
c      call execute_command_line(f_command, wait=.true.)
c
c      file_in=trim(tooldir) // '/emu/emu_input/nproc/'
c     $     // trim(fstep) // 'PBS_nodes'
c      open(50, file=trim(file_in), status='old')
c      read(50,'(a)') fstep 
c      close(50) 
c      f_command = 'sed -i -e "s|CHOOSE_NODES|'//
c     $     trim(fstep) //'|g" pbs_trc.sh'
c      call execute_command_line(f_command, wait=.true.)

c ---------------------
c bandaid pickup 
      f_pup = 'pickup_ggl90.' ! bandaid 
      write(fstep,"(i10.10)") 1
      f_ref = trim(f_pup) // trim(fstep) // '.data'
      write(fIter0,"(i10.10)") nIter0
      f_dum = trim(f_pup) // trim(fIter0) // '.data'
      f_command = 'ln -sf ' // trim(f_ref) // ' ' // trim(f_dum)
      f_dum = 'sed -i -e "s|BANDAID_PICKUP|'//
     $     trim(f_command) //'|g" pbs_trc.sh'
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
         write (6,"(a)")
     $        'Choose either a unit tracer at a point (1) or '
         write (6,"(a)") 'one with 3d distribution (2)' //
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
c Initial Tracer with 3d distribution 
         write(6,"(3x,a)")
     $    '... Initial tracer has 3d distribution' 
         write(51,"(3x,a)")
     $    '... Initial tracer has 3d distribution' 

c Choose how to specify 3d distribution
         write (6,"(3x,a,a)")
     $        'Interactively specify initial tracer (1) or ',
     $        'read from user file (2) ... (1/2)?'
         read (5,*) ifunc2 
         
         if (ifunc2 .eq. 2) then 
            write(6,"(/,4x,a)") 'Reading TRC from user file.'
            write(51,"(/,4x,a)") 'Reading TRC from user file.'

c Get starting tracer file name 
            write(6,*) '   Enter starting TRC filename (real*8) ... ?'  
            read(5,'(a)') fmask

            write(51,'(3x,"fmask = ",a)') trim(fmask)
            write(51,"(3x,a,/)") ' --> starting TRC file. '

         else
c Create TRC interactively
            write(6,"(/,4x,a)")
     $           'Interactively creating initial TRC.'
            write(51,"(/,4x,a)")
     $           'Interactively creating initial TRC.'
            
            call cr8_trc3d(fmask)
         endif

c Save file name for naming run directory
         floc_loc = trim(fmask)
         call StripSpaces(floc_loc)

      endif

c Check user file 
c      call chk_mask3d(fmask,nx,ny,nr,dum3d,1)  ptracer is real*8

c Link input mask to what model expects 
      write(fIter0,"(i10.10)") nIter0
      fdum = 'pickup_ptracers.' // trim(fIter0) // '.data'
      INQUIRE(FILE=trim(fdum), EXIST=f_exist)
      if (f_exist) then
         f_command = 'rm -f ' // trim(fdum)
         call execute_command_line(f_command, wait=.true.)
      endif

      f_command = 'ln -sf ' // trim(fmask) // ' ' //
     $     trim(fdum)
      call execute_command_line(f_command, wait=.true.)

c for meta
      fdum = 'pickup_ptracers.' // trim(fIter0) // '.meta'
      INQUIRE(FILE=trim(fdum), EXIST=f_exist)
      if (f_exist) then
         f_command = 'rm -f ' // trim(fdum)
         call execute_command_line(f_command, wait=.true.)
      endif

      f_command = 'ln -sf pickup_ptracer.meta ' // 
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
cif      f_command = 'sed -i -e "s|YOURDIR|'//
cif     $     trim(dir_run) //'|g" pbs_trc.sh'
cifcif     $     trim(dir_run) //'|g" pbs_trc.sh_tmp'
cif      call execute_command_line(f_command, wait=.true.)

cif      f_command = 'mv pbs_trc.sh_tmp pbs_trc.sh'  
cif      call execute_command_line(f_command, wait=.true.)

      f_command = 'cp -f pbs_trc.sh ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)
      
cif      f_command = 'ln -sf ' // trim(dir_run) // '/pbs_trc.sh .'
cif      call execute_command_line(f_command, wait=.true.)
      
      f_command = 'mv data ' // trim(dir_run) // '/data_trc'
      call execute_command_line(f_command, wait=.true.)
      
      f_command = 'cp -f pickup_ptracers.00*.* ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)
      
      f_command = '/bin/rm -f pickup_ptracers.00*.* ' 
      call execute_command_line(f_command, wait=.true.)
      
      f_command = 'mv trc.info ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

c Wrapup 
      write(6,"(a)") '... Done trc setup'

cif      write(6,"(/,a)") '*********************************'
cif      f_command = 'do_trc.sh'
cif      write(6,"(4x,a)") 'Run "' // trim(f_command) //
cif     $     '" to compute tracer evolution.'
cif      write(6,"(a,/)") '*********************************'
      
      stop
      end
c 
c ============================================================
c 
      subroutine cr8_trc3d(fmask)
c -----------------------------------------------------
c Subroutine to create a unit tracer distribution at points on the
c C-grid over a rectilinear volume. 
c     
c 19 June 2024, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c Mask 
      integer iref
      real*4 x1,x2,y1,y2,z1,z2
      real*4 dum3d(nx,ny,nr)

      character*256 floc_loc  ! location (mask) 
      character*256 fmask

c --------------
c Get 0/1 mask 
      call mask01_3d(dum3d,x1,x2,y1,y2,z1,z2)

c Save area for naming mask file 
      write(floc_loc,'(5(f6.1,"_"),f6.1,a4)')
     $     x1,x2,y1,y2,z1,z2,'-gmn'

      call StripSpaces(floc_loc)
      fmask = 'trc3d.' // trim(floc_loc)

      write(6,"(3x,a,/)")
     $     '3d tracer output: ',trim(fmask)

      open(60,file=trim(fmask),form='unformatted',access='stream')
      write(60) dble(dum3d)
      close(60)

      return
      end subroutine cr8_trc3d
      
