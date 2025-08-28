c 
c ============================================================
c 
      subroutine objf_time(floc_time)

c Specifiy OBJF in time; Output temporal mask (weight) and set model
c integration time accordingly in files data and pbs_adj.sh.  Returns
c string for naming output directory.
c
c For this version of the ECCO Modeling Utility, OBJF will be
c restricted to being a function of monthly averages; i.e., 
c      gencost_avgperiod(*)='month'
c

c Argument  
      character*256 floc_time   ! time information for output naming

c emu_input_dir 
      character*256 inputdir   ! directory where tool input files are 
      common /tool/inputdir

      character*256 f_emuref   ! full path to emu_ref
      parameter(max_files=1000)
      integer pkuphrs(max_files), n_pkuphrs

c V4r4 specific 
      integer nsteps, nyears, nmonths, hour26yr
      parameter(nsteps=227904) ! max time-step of V4r4
      parameter(nyears=26)  ! max number of years of V4r4
      parameter(nmonths=312) ! max number of months of V4r4
      
      integer nproc, hour26yr_trc, hour26yr_fwd, hour26yr_adj
      namelist /mitgcm_timing/ nproc, hour26yr_trc,
     $     hour26yr_fwd, hour26yr_adj

      integer mdays(12)
      data mdays/31,28,31,30,31,30,31,31,30,31,30,31/
      integer adays(nmonths) ! # of days of each of the 312 months 
      integer adays2(12,nyears)
      equivalence (adays, adays2)

      real*4 tmask(nmonths), tdum 
      real*4 tmask2(nmonths)
      character*256 fmask
      logical f_exist

c Other variables 
      character*1   atime
      character*128 atime_desc

      integer itarget1, ndays
      integer itarget2, i
      integer maxlag, istart

      integer nTimesteps, nHours
      character*24 fstep

      character*256 f_command

c --------------
c Read MITgcm timing information 
      open (50, file='mitgcm_timing.nml', status='old')
      read(50, nml=mitgcm_timing)
      close (50)
      hour26yr = hour26yr_adj

c ---------
c Assign number of days in each month
      do i=1,nyears
         adays2(:,i) = mdays(:)
      enddo
      
      do i=1,nyears,4   ! leap year starting from first (1992)
         adays2(2,i) = 29
      enddo      

c ---------
c Select OBJF time period 
      write(6,"(/,3x,a)") 'V4r4 can integrate from ' //
     $     '1/1/1992 12Z to 12/31/2017 12Z'
      write(6,"(7x,a)") 'which is 26-years (312-months).'

      write(6,"(/,3x,a)")
     $   'Select FIRST and LAST month of OBJF averaging period.'

      itarget1 = 0
      itarget2 = 0
      do while (itarget1.lt.1 .or. itarget1.gt.312 .or. 
     $     itarget2.lt.1 .or. itarget2.gt.312 .or.
     $     itarget2.lt.itarget1) 
         write(6,"(3x,a)") 'Enter FIRST month of OBJF period '//
     $        '(t_start in Eq 6 of Guide) ... (1-312)?'
         read(5,*) itarget1 
         write(6,"(3x,a)") 'Enter LAST month of OBJF period '//
     $        '(t_g in Eq 6 of Guide) ... (1-312)?'
         read(5,*) itarget2
      enddo

      write(6,"(3x,a,i0,1x,i0)") 'PERIOD start & end months = ',
     $     itarget1,itarget2
      write(51,'("itarget1, itarget2 = ",i0,1x,i0)')
     $     itarget1,itarget2
      write(51,"(a,/)")
     $     ' --> OBJF start & end months (1-312).'

c Set floc_time
      write(floc_time,"(i3,'_',i3)") itarget1, itarget2
      call StripSpaces(floc_time)

c Set mask 
      tmask = 0.
      tmask(itarget1:itarget2) = 1.

c Convert tmask to weight
      tmask = tmask * adays
      tdum = sum(tmask) 
      tmask = tmask/tdum

c ---------
c Select maximum lag from itarget2 to compute gradient 
      write(6,"(/,3x,a,i0,a,i0,a)")
     $  'Enter maximum lag (months) from ' //
     $  'LAST month of OBJF period to compute gradients ... (',
     $     itarget2-itarget1, '-', itarget2-1,')?'
      read (5,*) maxlag

      istart = itarget2 - maxlag
      if (istart .lt. 1) then istart=1
      if (istart .gt. itarget1) then istart=itarget1
      maxlag = itarget2 - istart

      write(6,"(3x,a,i0)")
     $     'Maximum lag (months) for computed gradients = ',
     $     maxlag 
      write(51,'("maxlag = ",i0)') maxlag 
      write(51,"(a,/)")
     $     ' --> maximum computed lag for gradients (months).'

c Identify day to start forward integration 
      if (istart.eq.1) then
         niter0 = 1       ! time-step 1 is 13Z 1/1/1992
         niter0_yr = 1
         niter0_mn = 1
      else
         ndays = sum(adays(1:istart-1))*24 - 13 ! start 0Z of 1st day of month

c Create full pathname to emu_ref directory 
c (where pickup files are)
         f_emuref = trim(inputdir) // '/emu_ref'

c Get time-stamp for all pickup files
         call get_pkup_hours(f_emuref, pkuphrs, n_pkuphrs) 

c Find latest pickup file before ndays
         niter0 = 1
         niter0_yr = 1
         toff = 7*24    ! assure entire 7-day control could be within domain
         do i=1,n_pkuphrs
            if (pkuphrs(i).gt.ndays-toff) exit 
            niter0 = pkuphrs(i)
            niter0_yr = i+1     ! 1 is 1992
         enddo

         idum = 1992+(niter0_yr-1)
         write(6,'(/,a,i0)') 'Control at max lag is in year ',
     $        idum 
         write(6,'(a,i0,a)') 'Enter year to begin forward ' //
     $        '(end adjoint)integration ... (1992-',idum,')?'
         read (5,*) idum
         niter0_yr = idum - 1992  + 1
         if (niter0_yr.eq.1) then
            niter0 = 1
         else
            niter0 = pkuphrs(niter0_yr-1)
         endif      

         niter0_mn = 12*(niter0_yr-1) + 1
      endif

c 
      write(6,'(a,i10,a)') 'Model will be integrated from ',
     $     niter0,' (1992 hours - 12)'
      write(6,'(a,i4,/)') 'i.e., 01 January ',1992+(niter0_yr-1)
      
      write(51,'(a,i10,a)') 'Model will be integrated from ',
     $     niter0,' (1992 hours - 12)'
      write(51,'(a,i4,/)') 'i.e., 01 January ',1992+(niter0_yr-1)

c ----------------
c Truncate tmask (exclude period before niter0_mn)
      tmask2 = 0.
      tmask2(1:nmonths-niter0_mn+1) = tmask(niter0_mn:nmonths)

c Output temporal mask (weight)
      fmask='objf_mask_T'
      INQUIRE(FILE=trim(fmask), EXIST=f_exist)
      if (f_exist) then
         f_command = 'rm -f ' // trim(fmask)
         call execute_command_line(f_command, wait=.true.)
      endif
      open(60,file=fmask,form='unformatted',access='stream')
      write(60) tmask2
      close(60)

c ----------------
c Set integration time/period in data and pbs_adj.sh 
c (data.ecco to be set in main routine.) 

c File data 
      f_command = 'cp -f data_emu data'
      call execute_command_line(f_command, wait=.true.)

      write(fstep,'(i24)') niter0
      call StripSpaces(fstep)
      f_command = 'sed -i -e "s|NITER0_EMU|'//
     $     trim(fstep) //'|g" data'
      call execute_command_line(f_command, wait=.true.)

c
      ndays = sum(adays(niter0_mn:itarget2)) + 7  ! extend 7-days beyond end 
      nTimesteps = ndays*24
      if (nTimesteps+niter0 .gt. nsteps) nTimesteps=nsteps-niter0

      write(fstep,'(i24)') nTimesteps
      call StripSpaces(fstep)
      f_command = 'sed -i -e "s|NSTEP_EMU|'//
     $     trim(fstep) //'|g" data'
      call execute_command_line(f_command, wait=.true.)

c File pbs_adj.sh
      f_command = 'cp -f pbs_adj.sh_orig pbs_adj.sh'
      call execute_command_line(f_command, wait=.true.)

      nHours = ceiling(float(nTimesteps)/float(nsteps-1)
     $     *float(hour26yr))
      write(fstep,'(i24)') nHours
      call StripSpaces(fstep)
      f_command = 'sed -i -e "s|WHOURS_EMU|'//
     $     trim(fstep) //'|g" pbs_adj.sh'
      call execute_command_line(f_command, wait=.true.)

      if (nHours .le. 2) then 
         f_command = 'sed -i -e "s|CHOOSE_DEVEL|'//
     $        'PBS -q devel|g" pbs_adj.sh'
         call execute_command_line(f_command, wait=.true.)
      endif

c 
      write(6,"(/,3x,a)") '... Program has set computation periods '
     $    // 'in files data and pbs_adj.sh accordingly.'
      write(6,"(3x,a,i4)") '... Estimated wallclock hours is '
     $     ,nHours

      return
      end subroutine objf_time
c 
c ============================================================
c 
      subroutine objf_var(f1,iobjf,floc_loc)
c Specifiy OBJF variable(s)  

c Argument 
      character*6 f1 ! OBJF variable order (counter)
      integer iobjf  ! OBJF variable index 
      character*256 floc_loc  ! location (mask) of first OBJF variable

c local variables
      character*256 f_command
      character*256 fmask
      logical f_exist

c ------------
c Specify spatial mask (weight) according to variable
      if (iobjf .eq. 1 .or. iobjf .eq. 2) then 
         call objf_var_2d(f1, iobjf,floc_loc)
      else if (iobjf .eq. 3 .or. iobjf .eq. 4) then
         call objf_var_3d(f1, iobjf,floc_loc)
      else 
         call objf_var_uv(f1, iobjf,floc_loc)
      endif

c Create time mask for variable (link common time mask) 
      fmask = 'objf_' // trim(f1) // '_mask_T' 
      INQUIRE(FILE=trim(fmask), EXIST=f_exist)
      if (f_exist) then
         f_command = 'rm -f ' // trim(fmask)
         call execute_command_line(f_command, wait=.true.)
      endif
      f_command = 'ln -sf objf_mask_T ' // trim(fmask)
      call execute_command_line(f_command, wait=.true.)

c Edit data.ecco mask field  
      f_command = 'sed -i -e ' //
     $     '"s/mask(' // trim(f1) //
     $     ').*/mask(' // trim(f1) //
     $     ')=''objf_' // trim(f1) // '_mask_''/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

      return
      end subroutine objf_var
c 
c ============================================================
c 
      subroutine objf_var_2d(f1, iobjf, floc_loc)

c Update data.ecco OBJF for either SSH or OBP
      character*6 f1
      integer iobjf
      character*256 floc_loc  ! location (mask) of first OBJF variable
      integer ip1,ip2

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
      character*1 pert_2, c1, c2
      integer pert_i, pert_j
      real*4 dum2d(nx,ny), adum 
      character*256 f_command
      character*256 fmask  ! name of mask file 
      character*256 fdum
      logical f_exist
      character*24 fmult
      real*4 amult 

c ------
c Identify OBJF variable among the two available 
      if (iobjf.eq.1) then
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''m_boxmean_eta_dyn''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.2) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''m_boxmean_obp''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else
         write(6,*) 'iobjf is NG for objf_var_2d ... ', iobjf
         write(6,*) 'This should not happen. Aborting ...'
         stop
      endif

c ------
c Select type of spatial mask 
      ifunc = 0
      do while (ifunc.ne.1 .and. ifunc.ne.2) 
         write (6,"(3x,a,a)")
     $        'Choose either VARIABLE at a point (1) or ',
     $        'VARIABLE weighted in space (2) ... (1/2)?'
         read (5,*) ifunc
      end do

      write(51,"(3x,'ifunc = ',i2)") ifunc

      if (ifunc .eq. 1) then 
c When OBJF is at a point

         write(6,"(3x,a,/)")
     $        '... OBJF will be a scaled VARIABLE at a point'
         write(6,"(4x,a)")
     $        'i.e., MULT * VARIABLE '

         write(51,"(3x,a,/)")
     $        '... OBJF will be a scaled VARIABLE at a point'
         write(51,"(3x,a,/)")
     $        'i.e., MULT * VARIABLE '

         call slct_2d_pt(pert_i,pert_j)

         write(51,2002) pert_i,pert_j
 2002    format(3x,'pert_i, pert_j = ',i2,2x,i4)
         write(51,"(3x,a,/)") ' --> OBJF model grid location (i,j).'

         write(51,2003) xc(pert_i,pert_j), yc(pert_i,pert_j)
 2003    format(3x,'long(E), lat(N) = ',f8.1,2x,f7.1,/)

c Create 2d mask for the point 
         dum2d = 0.

c Option to define OBJF relative to global mean
         write(6,"(3x,a,a)")
     $        'Should value at point be relative to global mean ',
     $        '... (enter 1 for yes)?'
         read(5,*) iref

         if (iref .eq. 1) then
            write(6,"(3x,a,/)")
     $           '... OBJF will be relative to global mean'
            write(51,"(3x,a,/)")
     $           '... OBJF will be relative to global mean'

            adum = 0.
            do i=1,nx
               do j=1,ny
                  if (kmt(i,j).ne.0) then
                     dum2d(i,j) = -rac(i,j)
                     adum = adum + rac(i,j)
                  endif
               enddo
            enddo
            dum2d = dum2d / adum
         endif 
c
         dum2d(pert_i,pert_j) = dum2d(pert_i,pert_j) + 1.
            
c output 2d mask 
         fmask = 'objf_' // trim(f1) // '_mask_C'
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) dum2d
         close(60)

c Save location for naming run directory
         write(floc_loc,'(i9,"_",i9)') pert_i,pert_j
         call StripSpaces(floc_loc)

      else
c When OBJF is VARIABLE weighted in space 

         write(6,"(3x,a)")
     $    '... OBJF will be a linear function of selected variable'
         write(6,"(4x,a)")
     $        'i.e., MULT * SUM( MASK * VARIABLE )'
         write(51,"(3x,a)")
     $   ' --> OBJF is a linear function of selected variable(s)'
         write(51,"(3x,a,/)")
     $     ' --> i.e., MULT * SUM( MASK * VARIABLE )'

c Choose mask 
         write (6,"(/,3x,a,a)")
     $        'Interactively specify MASK (1) or ',
     $        'read from user file (2) ... (1/2)?'
         read (5,*) ifunc2 
         
         if (ifunc2 .eq. 2) then 
            write(6,"(/,4x,a)") 'Reading MASK from user file.'
            write(51,"(3x,a,/)")
     $           ' --> Reading MASK from user file.'

            write(6,"(/,4x,a,/)") '!!!!! MASK file must exist' //
     $           ' (binary native format) before proceeding ... '
c Get mask file name 
            write(6,*)
     $           '   Enter MASK filename (T in Eq 1 of Guide) ... ?'  
            read(5,'(a)') fmask

            write(51,'(/,3x,"fmask = ",a)') trim(fmask)
            write(51,"(3x,a,/)") ' --> MASK file. '

c Check mask 
cif            call chk_mask2d(fmask,nx,ny,dum2d,1)
         else
c Create mask interactively
            write(6,"(/,4x,a,/)")
     $           'Interactively creating MASK for area mean.'
            write(51,"(3x,a,/)")
     $           ' --> Interactively creating MASK for area mean.'
            
            call cr8_mask2d(fmask,x1,x2,y1,y2,iref)

            write(51,"(4x,a)") 'Are defined as ...'
            write(51,"(7x,a26,2x,2f7.1)")
     $           'west/east longitude(E):',x1,x2
            write(51,"(7x,a26,2x,2f7.1)")
     $           'south/north latitude(N):',y1,y2
            if (iref .eq. 1) then
               write(51,"(4x,a,/)") 'Relative to global mean.'
            endif

         endif

c Save mask file name for naming run directory
         ip1 = index(fmask,'/',.TRUE.)
         ip2 = len(fmask)
         floc_loc = trim(fmask(ip1+1:ip2))
         call StripSpaces(floc_loc)

c Link input mask to what model expects 
         fdum = 'objf_' // trim(f1) // '_mask_C' 
         INQUIRE(FILE=trim(fdum), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fdum)
            call execute_command_line(f_command, wait=.true.)
         endif

         f_command = 'ln -sf ' // trim(fmask) // ' ' //
     $        trim(fdum)
         call execute_command_line(f_command, wait=.true.)

      endif

c Enter scaling factor
      write(6,"(/,3x,a)") 'Enter scaling factor ' //
     $     '(alpha in Eq 1 of Guide)... ?'
      read(5,*) amult

      write(6,'(3x,"amult = ",1pe12.4)') amult 
      write(51,'(3x,"amult = ",1pe12.4)') amult
      write(51,"(3x,a,/)") ' --> OBJF Scaling factor. '

      write(fmult,"(1pe12.4)") amult 
      f_command = 'sed -i -e ' //
     $  '"s/gencost(' // trim(f1) //
     $ ').*/gencost(' // trim(f1) //
     $ ')= ' // fmult // ',/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

c Specify variable being NOT 3D      
      f_command = 'sed -i -e ' //
     $     '"s/is3d(' // trim(f1) //
     $     ').*/is3d(' // trim(f1) //
     $     ')=.FALSE.,/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

      return
      end subroutine objf_var_2d
c 
c ============================================================
c 
      subroutine objf_var_3d(f1, iobjf, floc_loc)

c Update data.ecco OBJF for either THETA or SALT
      character*6 f1
      integer iobjf
      character*256 floc_loc  ! location (mask) of first OBJF variable
      integer ip1,ip2

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy
c 
      character*1 pert_2, c1, c2
      integer pert_i, pert_j, pert_k
      real*4 dum3d(nx,ny,nr)
      character*256 f_command
      character*256 fmask  ! name of mask file 
      character*256 fdum
      logical f_exist
      character*24 fmult
      real*4 amult 
      real*4 x1,x2,y1,y2,z1,z2

c ------
c Identify OBJF variable among the two available 
      if (iobjf.eq.3) then
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''m_boxmean_theta''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.4) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''m_boxmean_salt''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else
         write(6,*) 'iobjf is NG for objf_var_3d ... ', iobjf
         write(6,*) 'This should not happen. Aborting ...'
         stop
      endif

c ------
c Select type of spatial mask 
      ifunc = 0
      do while (ifunc.ne.1 .and. ifunc.ne.2) 
         write (6,*) 'Choose either VARIABLE at a point (1) or ',
     $        ' VARIABLE weighted in space (2) ... (1/2)?'
         read (5,*) ifunc
      end do

      write(51,"(3x,'ifunc = ',i2)") ifunc

      if (ifunc .eq. 1) then 
c When OBJF is at a point

         write(6,"(3x,a,/)")
     $        '... OBJF will be a scaled VARIABLE at a point'
         write(6,"(4x,a)")
     $        'i.e., MULT * VARIABLE '

         write(51,"(3x,a,/)")
     $        '... OBJF will be a scaled VARIABLE at a point'
         write(51,"(3x,a,/)")
     $        'i.e., MULT * VARIABLE '

         call slct_3d_pt(pert_i,pert_j,pert_k)

         write(51,2002) pert_i,pert_j,pert_k
 2002    format(3x,'pert_i, pert_j, pert_k = ',i2,2x,i4,2x,i2)
         write(51,"(3x,a,/)") ' --> OBJF model grid location (i,j,k).'

         write(51,2003) xc(pert_i,pert_j), yc(pert_i,pert_j),
     $        rc(pert_k)
 2003    format(3x,'long(E), lat(N), Dep(m) = ',
     $        f8.1,1x,f7.1,1x,f9.1,/)

c Create 3d mask for the point 
         dum3d = 0.
         dum3d(pert_i,pert_j,pert_k) = 1. 

         f_command = 'sed -i -e ' //
     $  '"s/mask(' // trim(f1) //
     $ ').*/mask(' // trim(f1) //
     $ ')=''objf_' // trim(f1) // '_mask_''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)

         fmask = 'objf_' // trim(f1) // '_mask_C'
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) dum3d
         close(60)

c Save location for naming run directory
         write(floc_loc,'(i9,"_",i9,"_",i9)') pert_i,pert_j,pert_k
         call StripSpaces(floc_loc)

      else
c When OBJF is VARIABLE weighted in space 

         write(6,*)
     $    '... OBJF will be a linear function of selected variable'
         write(6,"(4x,a)")
     $        'i.e., MULT * SUM( MASK * VARIABLE )'
         write(51,"(3x,a)")
     $   ' --> OBJF is a linear function of selected variable(s)'
         write(51,"(3x,a,/)")
     $     ' --> i.e., MULT * SUM( MASK * VARIABLE )'

c Choose mask 
         write (6,"(/,3x,a,a)")
     $        'Interactively specify MASK (1) or ',
     $        'read from user file (2) ... (1/2)?'
         read (5,*) ifunc2 

         write(51,"(3x,'ifunc2 = ',i2)") ifunc2

         if (ifunc2 .eq. 2) then 
            write(6,"(/,4x,a)") 'Reading MASK from user file.'
            write(51,"(3x,a,/)")
     $           ' --> Reading MASK from user file.'

            write(6,"(/,4x,a,/)") '!!!!! MASK file must exist' //
     $           ' (binary native format) before proceeding ... '
c Get mask file name 
            write(6,*)
     $           '   Enter MASK filename (T in Eq 1 of Guide) ... ?'  
            read(5,'(a)') fmask

            write(51,'(3x,"fmask = ",a)') trim(fmask)
            write(51,"(3x,a,/)") ' --> MASK file. '

c Check mask 
cif            call chk_mask3d(fmask,nx,ny,nr,dum3d,1)
         else
c Create mask interactively
            write(6,"(/,4x,a,/)")
     $           'Interactively creating MASK for volume mean.'
            write(51,"(3x,a,/)")
     $           ' --> Interactively creating MASK for volume mean.'
            
            call cr8_mask3d(fmask,x1,x2,y1,y2,z1,z2,iref)

            write(51,"(4x,a)") 'Volume defined as ...'
            write(51,"(7x,a26,2x,2f7.1)")
     $           'west/east longitude(E):',x1,x2
            write(51,"(7x,a26,2x,2f7.1)")
     $           'south/north latitude(N):',y1,y2
            write(51,"(7x,a26,2x,2f7.1,/)")
     $           'max/min depth(m):',z1,z2
            if (iref .eq. 1) then
               write(51,"(4x,a,/)") 'Relative to global mean.'
            endif

        endif

c Save mask file name for naming run directory
         ip1 = index(fmask,'/',.TRUE.)
         ip2 = len(fmask)
         floc_loc = trim(fmask(ip1+1:ip2))
         call StripSpaces(floc_loc)

c Link input mask to what model expects 
         fdum = 'objf_' // trim(f1) // '_mask_C' 
         INQUIRE(FILE=trim(fdum), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fdum)
            call execute_command_line(f_command, wait=.true.)
         endif

         f_command = 'ln -sf ' // trim(fmask) // ' ' //
     $        trim(fdum)
         call execute_command_line(f_command, wait=.true.)

      endif

c Enter scaling factor
      write(6,"(3x,a)") 'Enter scaling factor ' //
     $     '(alpha in Eq 1 of Guide)... ?'
      read(5,*) amult

      write(6,'("amult = ",1pe12.4)') amult 
      write(51,'(3x,"amult = ",1pe12.4)') amult
      write(51,"(3x,a,/)") ' --> OBJF Scaling factor. '

      write(fmult,"(1pe12.4)") amult 
      f_command = 'sed -i -e ' //
     $  '"s/gencost(' // trim(f1) //
     $ ').*/gencost(' // trim(f1) //
     $ ')= ' // fmult // ',/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

c Specify variable is 3D      
      f_command = 'sed -i -e ' //
     $     '"s/is3d(' // trim(f1) //
     $     ').*/is3d(' // trim(f1) //
     $     ')=.TRUE.,/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

c --------------------
c Output zero mask for W & S grid
      dum3d = 0.
      fdum = 'objf_' // trim(f1) // '_mask_W' 
      INQUIRE(FILE=trim(fdum), EXIST=f_exist)
      if (f_exist) then
         f_command = 'rm -f ' // trim(fdum)
         call execute_command_line(f_command, wait=.true.)
      endif
      open(60,file=trim(fdum),form='unformatted',access='stream')
      write(60) dum3d
      close(60)

      fdum = 'objf_' // trim(f1) // '_mask_S' 
      INQUIRE(FILE=trim(fdum), EXIST=f_exist)
      if (f_exist) then
         f_command = 'rm -f ' // trim(fdum)
         call execute_command_line(f_command, wait=.true.)
      endif
      open(60,file=trim(fdum),form='unformatted',access='stream')
      write(60) dum3d
      close(60)

      return
      end subroutine objf_var_3d
c 
c ============================================================
c 
      subroutine objf_var_uv(f1, iobjf, floc_loc)

c Update data.ecco OBJF for UV
      character*6 f1
      integer iobjf
      character*256 floc_loc  ! location (mask) of first OBJF variable
      integer ip1,ip2

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

c 
      character*1 pert_2, c1, c2
      integer pert_i, pert_j, pert_k
      real*4 dum3d(nx,ny,nr)
      character*256 f_command
      character*256 fmask  ! name of mask file 
      character*256 fmask_w, fmask_s  ! name of mask file 
      character*1 ov, m1, m0
      character*256 fdum
      logical f_exist
      character*24 fmult
      real*4 amult 

c ------
c Identify OBJF variable among the two available 
      if (iobjf.eq.5) then
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''m_horflux_vol''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else
         write(6,*) 'iobjf is NG for objf_var_uv ... ', iobjf
         write(6,*) 'This should not happen. Aborting ...'
         stop
      endif

c ------
c Select type of spatial mask 
      ifunc = 0
      do while (ifunc.ne.1 .and. ifunc.ne.2) 
         write (6,*) 'Choose either VARIABLE at a point (1) or ',
     $        ' VARIABLE weighted in space (2) ... (1/2)?'
         read (5,*) ifunc
      end do

      write(51,"(3x,'ifunc = ',i2)") ifunc

      if (ifunc .eq. 1) then 
c When OBJF is at a point

         write(6,"(3x,a,/)") 
     $        '... OBJF will be a scaled VARIABLE at a point'
         write(6,"(4x,a)")
     $        'i.e., MULT * VARIABLE '

         write(51,"(3x,a,/)") 
     $        '... OBJF will be a scaled VARIABLE at a point'
         write(51,"(3x,a,/)")
     $        'i.e., MULT * VARIABLE '

         call slct_3d_pt(pert_i,pert_j,pert_k)

         write(51,2002) pert_i,pert_j,pert_k
 2002    format(3x,'pert_i, pert_j, pert_k = ',i2,2x,i4,2x,i2)
         write(51,"(3x,a,/)") ' --> OBJF model grid location (i,j,k).'

         write(51,2003) xc(pert_i,pert_j), yc(pert_i,pert_j),
     $        rc(pert_k)
 2003    format(3x,'long(E), lat(N), Dep(m) = ',
     $        f8.1,1x,f7.1,1x,f9.1,/)
         
c Select either UVEL or VVEL
         iuv = 0
         do while (iuv.ne.1 .and. iuv.ne.2) 
            write(6,*) 'Choose either U (1) or V (2) ... (1/2)?'
            read(5,*) iuv 
         end do

         write(51,'(3x,"iuv = ",i0)') iuv

         if (iuv .eq. 1) then   ! UVEL
            ov = 'U'
            m1 = 'W'
            m0 = 'S'
         else
            ov = 'V'
            m1 = 'S'
            m0 = 'W'
         endif

         write(6,*) ' ... OBJF will be ' // ov // 'VEL'
         write(51,"(3x,a,/)") ' --> OBJF will be ' // ov // 'VEL.'

c Create 3d mask 
         dum3d = 0.

         fmask='objf_' // trim(f1) // '_mask_' // m0
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) dum3d
         close(60)

         dum3d(pert_i,pert_j,pert_k) = 1. 

         fmask='objf_' // trim(f1) // '_mask_' // m1
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) dum3d
         close(60)

c Save location for naming run directory
         write(floc_loc,'(a1,"_",i9,"_",i9,"_",i9)')
     $        ov,pert_i,pert_j,pert_k
         call StripSpaces(floc_loc)

      else
c When OBJF is VARIABLE weighted in space 

         write(6,*)
     $     '... OBJF will be a linear function of selected variable'
         write(6,"(4x,a)")
     $        'i.e., MULT * SUM( MASK_W*UVEL + MASK_S*VVEL )'
         write(51,"(3x,a)")
     $   ' --> OBJF is a linear function of selected variable(s)'
         write(51,"(3x,a,/)")
     $     ' --> i.e., MULT * SUM( MASK_W*UVEL + MASK_S*VVEL )'

c Choose mask 
         write (6,"(/,3x,a,a)")
     $     'Interactively create MASKs for section tranport (1) or ',
     $     'read MASKs from user files (2) ... (1/2)?'
         read (5,*) ifunc2 

         write(51,"(3x,'ifunc2 = ',i2)") ifunc2

         if (ifunc2 .eq. 2) then ! use USER-SPECIFIED mask 

            write(6,"(/,4x,a)")
     $           'Reading MASK_W & MASK_S from user files.'
            write(51,"(3x,a,/)")
     $           ' --> Reading MASK_W & MASK_S from user files.'

            write(6,"(4x,a,/)")
     $           '!!!!! MASK_W & MASK_S files must exist' //
     $           ' (binary native format) before proceeding ... '

c --------------------
c UVEL

c Get mask file name 
            write(6,"(3x,a)") 'Enter MASK_W filename for UVEL '
     $           // '(T in Eq 1 of Guide) ... ?'  
            read(5,'(a)') fmask

            write(6,'("fmask_W = ",a)') trim(fmask)
            write(51,'(3x,"fmask_W = ",a)') trim(fmask)
            write(51,"(3x,a,/)") ' --> MASK_W file for UVEL. '

c Save mask file name for naming run directory
            ip1 = index(fmask,'/',.TRUE.)
            ip2 = len(fmask)
            floc_loc = trim(fmask(ip1+1:ip2))
            call StripSpaces(floc_loc)

c Check mask 
cif         call chk_mask3d(fmask,nx,ny,nr,dum3d,1)

c Link input mask to what model expects 
            fdum = 'objf_' // trim(f1) // '_mask_W' 
            INQUIRE(FILE=trim(fdum), EXIST=f_exist)
            if (f_exist) then
               f_command = 'rm -f ' // trim(fdum)
               call execute_command_line(f_command, wait=.true.)
            endif

            f_command = 'ln -sf ' // trim(fmask) // ' ' //
     $           trim(fdum)
            call execute_command_line(f_command, wait=.true.)

c --------------------
c VVEL

c Get mask file name 
            write(6,"(3x,a)") 'Enter MASK_W filename for VVEL '
     $           // '(T in Eq 1 of Guide) ... ?'  
            read(5,'(a)') fmask

            write(6,'("fmask_S = ",a)') trim(fmask)
            write(51,'(3x,"fmask_S = ",a)') trim(fmask)
            write(51,"(3x,a,/)") ' --> MASK_S file for VVEL. '

c Check mask 
cif         call chk_mask3d(fmask,nx,ny,nr,dum3d,1)

c Link input mask to what model expects 
            fdum = 'objf_' // trim(f1) // '_mask_S' 
            INQUIRE(FILE=trim(fdum), EXIST=f_exist)
            if (f_exist) then
               f_command = 'rm -f ' // trim(fdum)
               call execute_command_line(f_command, wait=.true.)
            endif

            f_command = 'ln -sf ' // trim(fmask) // ' ' //
     $           trim(fdum)
            call execute_command_line(f_command, wait=.true.)

         else
c Create mask interactively for section transport
            write(6,"(/,4x,a,/)")
     $        'Interactively creating MASKs for section transport.'
            write(51,"(3x,a,/)")
     $        ' --> Interactively creating MASKs for section transport.'
            
            call cr8_mask_section(fmask_w,fmask_s,x1,x2,y1,y2,z1,z2)

            write(51,"(4x,a)") 'Section defined from ' 
            write(51,"(7x,a32,2x,2f7.1)")
     $           'point 1 (longitude, latitude): ',x1,y1
            write(51,"(4x,a)") 'to '
            write(51,"(7x,a32,2x,2f7.1)")
     $           'point 2 (longitude, latitude): ',x2,y2
            write(51,"(7x,a26,2x,2f7.1,/)")
     $           'min/max depth(m):',z1,z2

c Extract location for naming run directory
            ipos = INDEX(fmask_w, '.')  ! Find the position of the first period
            IF (ipos > 0 .AND. ipos < LEN(fmask_w)) THEN
               floc_loc = fmask_w(ipos+1:) ! Extract substring from pos+1 to end
            ELSE
               floc_loc = ""        ! Handle case where no period exists
            ENDIF
            call StripSpaces(floc_loc)

c Link masks to what model expects 
c For mask_w
            fdum = 'objf_' // trim(f1) // '_mask_W' 
            INQUIRE(FILE=trim(fdum), EXIST=f_exist)
            if (f_exist) then
               f_command = 'rm -f ' // trim(fdum)
               call execute_command_line(f_command, wait=.true.)
            endif

            f_command = 'ln -sf ' // trim(fmask_w) // ' ' //
     $           trim(fdum)
            call execute_command_line(f_command, wait=.true.)
c For mask_s
            fdum = 'objf_' // trim(f1) // '_mask_S' 
            INQUIRE(FILE=trim(fdum), EXIST=f_exist)
            if (f_exist) then
               f_command = 'rm -f ' // trim(fdum)
               call execute_command_line(f_command, wait=.true.)
            endif

            f_command = 'ln -sf ' // trim(fmask_s) // ' ' //
     $           trim(fdum)
            call execute_command_line(f_command, wait=.true.)

         endif ! end VARIABLE weighted in space
      endif ! end mask creation 

c --------------------
c Enter scaling factor
      write(6,"(3x,a)") 'Enter scaling factor ' //
     $     '(alpha in Eq 1 of Guide)... ?'
      read(5,*) amult

      write(6,'("amult = ",1pe12.4)') amult 
      write(51,'(3x,"amult = ",1pe12.4)') amult
      write(51,"(3x,a,/)") ' --> OBJF Scaling factor. '

      write(fmult,"(1pe12.4)") amult 
      f_command = 'sed -i -e ' //
     $  '"s/gencost(' // trim(f1) //
     $ ').*/gencost(' // trim(f1) //
     $ ')= ' // fmult // ',/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

c --------------------
c Specify variable is 3D      
      f_command = 'sed -i -e ' //
     $     '"s/is3d(' // trim(f1) //
     $     ').*/is3d(' // trim(f1) //
     $     ')=.TRUE.,/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

c --------------------
c Output zero mask for C grid
      dum3d = 0.
      fdum = 'objf_' // trim(f1) // '_mask_C' 
      INQUIRE(FILE=trim(fdum), EXIST=f_exist)
      if (f_exist) then
         f_command = 'rm -f ' // trim(fdum)
         call execute_command_line(f_command, wait=.true.)
      endif
      open(60,file=trim(fdum),form='unformatted',access='stream')
      write(60) dum3d
      close(60)

      return
      end subroutine objf_var_uv
c 
c ============================================================
c 
      subroutine objf_ctrl(f1,iobjf,floc_loc)
c Specifiy OBJF variable(s) for Controls 

c Argument 
      character*6 f1 ! OBJF variable order (counter)
      integer iobjf  ! OBJF variable index 
      character*256 floc_loc  ! location (mask) of first OBJF variable

c local variables
      character*256 f_command
      character*256 fmask
      logical f_exist

c ------------
c Specify spatial mask (weight) 
      call objf_ctrl_2d(f1, iobjf,floc_loc)

c Create time mask for variable (link common time mask) 
      fmask = 'objf_' // trim(f1) // '_mask_T' 
      INQUIRE(FILE=trim(fmask), EXIST=f_exist)
      if (f_exist) then
         f_command = 'rm -f ' // trim(fmask)
         call execute_command_line(f_command, wait=.true.)
      endif
      f_command = 'ln -sf objf_mask_T ' // trim(fmask)
      call execute_command_line(f_command, wait=.true.)

c Edit data.ecco mask field  
      f_command = 'sed -i -e ' //
     $     '"s/mask(' // trim(f1) //
     $     ').*/mask(' // trim(f1) //
     $     ')=''objf_' // trim(f1) // '_mask_''/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

      return
      end subroutine objf_ctrl
c 
c ============================================================
c 
      subroutine objf_ctrl_2d(f1, iobjf, floc_loc)

c Update data.ecco OBJF for either SSH or OBP
      character*6 f1
      integer iobjf
      character*256 floc_loc  ! location (mask) of first OBJF variable
      integer ip1,ip2

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
      character*1 pert_2, c1, c2
      integer pert_i, pert_j
      real*4 dum2d(nx,ny), adum 
      character*256 f_command
      character*256 fmask  ! name of mask file 
      character*256 fdum
      logical f_exist
      character*24 fmult
      real*4 amult 

c ------
c Identify OBJF variable among the two available 
      if (iobjf.eq.1) then
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''dummy_empmr''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.2) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''dummy_pload''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.3) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''dummy_qnet''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.4) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''dummy_qsw''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.5) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''dummy_saltflux''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.6) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''dummy_spflx''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.7) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''dummy_tauu''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.8) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''dummy_tauv''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else
         write(6,*) 'iobjf is NG for objf_ctrl_2d ... ', iobjf
         write(6,*) 'This should not happen. Aborting ...'
         stop
      endif

c ------
c Select type of spatial mask 
      ifunc = 0
      do while (ifunc.ne.1 .and. ifunc.ne.2) 
         write (6,"(3x,a,a)")
     $        'Choose either VARIABLE at a point (1) or ',
     $        'VARIABLE weighted in space (2) ... (1/2)?'
         read (5,*) ifunc
      end do

      write(51,"(3x,'ifunc = ',i2)") ifunc

      if (ifunc .eq. 1) then 
c When OBJF is at a point

         write(6,"(3x,a,/)")
     $        '... OBJF will be a scaled VARIABLE at a point'
         write(6,"(4x,a)")
     $        'i.e., MULT * VARIABLE '

         write(51,"(3x,a,/)")
     $        '... OBJF will be a scaled VARIABLE at a point'
         write(51,"(3x,a,/)")
     $        'i.e., MULT * VARIABLE '

         call slct_2d_pt(pert_i,pert_j)

         write(51,2002) pert_i,pert_j
 2002    format(3x,'pert_i, pert_j = ',i2,2x,i4)
         write(51,"(3x,a,/)") ' --> OBJF model grid location (i,j).'

         write(51,2003) xc(pert_i,pert_j), yc(pert_i,pert_j)
 2003    format(3x,'long(E), lat(N) = ',f8.1,2x,f7.1,/)

c Create 2d mask for the point 
         dum2d = 0.

c Option to define OBJF relative to global mean
         write(6,"(3x,a,a)")
     $        'Should value at point be relative to global mean ',
     $        '... (enter 1 for yes)?'
         read(5,*) iref

         if (iref .eq. 1) then
            write(6,"(3x,a,/)")
     $           '... OBJF will be relative to global mean'
            write(51,"(3x,a,/)")
     $           '... OBJF will be relative to global mean'

            adum = 0.
            do i=1,nx
               do j=1,ny
                  if (kmt(i,j).ne.0) then
                     dum2d(i,j) = -rac(i,j)
                     adum = adum + rac(i,j)
                  endif
               enddo
            enddo
            dum2d = dum2d / adum
         endif 
c
         dum2d(pert_i,pert_j) = dum2d(pert_i,pert_j) + 1.
            
c output 2d mask 
         fmask = 'objf_' // trim(f1) // '_mask_C'
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) dum2d
         close(60)

c Save location for naming run directory
         write(floc_loc,'(i9,"_",i9)') pert_i,pert_j
         call StripSpaces(floc_loc)

      else
c When OBJF is VARIABLE weighted in space 

         write(6,"(3x,a)")
     $    '... OBJF will be a linear function of selected variable'
         write(6,"(4x,a)")
     $        'i.e., MULT * SUM( MASK * VARIABLE )'
         write(51,"(3x,a)")
     $   ' --> OBJF is a linear function of selected variable(s)'
         write(51,"(3x,a,/)")
     $     ' --> i.e., MULT * SUM( MASK * VARIABLE )'

c Choose mask 
         write (6,"(/,3x,a,a)")
     $        'Interactively specify MASK (1) or ',
     $        'read from user file (2) ... (1/2)?'
         read (5,*) ifunc2 
         
         if (ifunc2 .eq. 2) then 
            write(6,"(/,4x,a)") 'Reading MASK from user file.'
            write(51,"(3x,a,/)")
     $           ' --> Reading MASK from user file.'

            write(6,"(/,4x,a,/)") '!!!!! MASK file must exist' //
     $           ' (binary native format) before proceeding ... '
c Get mask file name 
            write(6,*)
     $           '   Enter MASK filename (T in Eq 1 of Guide) ... ?'  
            read(5,'(a)') fmask

            write(51,'(/,3x,"fmask = ",a)') trim(fmask)
            write(51,"(3x,a,/)") ' --> MASK file. '

c Check mask 
cif            call chk_mask2d(fmask,nx,ny,dum2d,1)
         else
c Create mask interactively
            write(6,"(/,4x,a,/)")
     $           'Interactively creating MASK for area mean.'
            write(51,"(3x,a,/)")
     $           ' --> Interactively creating MASK for area mean.'
            
            call cr8_mask2d(fmask,x1,x2,y1,y2,iref)

            write(51,"(4x,a)") 'Are defined as ...'
            write(51,"(7x,a26,2x,2f7.1)")
     $           'west/east longitude(E):',x1,x2
            write(51,"(7x,a26,2x,2f7.1)")
     $           'south/north latitude(N):',y1,y2
            if (iref .eq. 1) then
               write(51,"(4x,a,/)") 'Relative to global mean.'
            endif

         endif

c Save mask file name for naming run directory
         ip1 = index(fmask,'/',.TRUE.)
         ip2 = len(fmask)
         floc_loc = trim(fmask(ip1+1:ip2))
         call StripSpaces(floc_loc)

c Link input mask to what model expects 
         fdum = 'objf_' // trim(f1) // '_mask_C' 
         INQUIRE(FILE=trim(fdum), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fdum)
            call execute_command_line(f_command, wait=.true.)
         endif

         f_command = 'ln -sf ' // trim(fmask) // ' ' //
     $        trim(fdum)
         call execute_command_line(f_command, wait=.true.)

      endif

c Enter scaling factor
      write(6,"(/,3x,a)") 'Enter scaling factor ' //
     $     '(alpha in Eq 1 of Guide)... ?'
      read(5,*) amult

      write(6,'(3x,"amult = ",1pe12.4)') amult 
      write(51,'(3x,"amult = ",1pe12.4)') amult
      write(51,"(3x,a,/)") ' --> OBJF Scaling factor. '

      write(fmult,"(1pe12.4)") amult 
      f_command = 'sed -i -e ' //
     $  '"s/gencost(' // trim(f1) //
     $ ').*/gencost(' // trim(f1) //
     $ ')= ' // fmult // ',/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

c Specify variable being NOT 3D      
      f_command = 'sed -i -e ' //
     $     '"s/is3d(' // trim(f1) //
     $     ').*/is3d(' // trim(f1) //
     $     ')=.FALSE.,/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

      return
      end subroutine objf_ctrl_2d
c 
c ============================================================
c 
      subroutine slct_2d_pt(pert_i,pert_j)
c Pick 3d model grid point 

c argument 
      integer pert_i, pert_j

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

c local variables
      integer iloc, check_d
      real*4 pert_x, pert_y

c -------------
c Choose method of selecting point 
      write (6,"(/,a)") 'Choose horizontal location ... '
      write (6,"(3x,a)")
     $     'Enter 1 to select native grid location (i,j),  '
      write (6,"(6x,a)")
     $     'or 9 to select by longitude/latitude ... (1 or 9)? '
      read (5,*) iloc

      if (iloc .ne. 9) then 

c By native grid point 
         pert_i = 0
         pert_j = 0

         write(6,"(/,3x,a)") 'Identify point in native grid ... '
         do while (pert_i.lt.1 .or. pert_i.gt.nx) 
            write (6,"(3x,'i ... (1-',i2,') ?')") nx
            read (5,*) pert_i
         end do
         do while (pert_j.lt.1 .or. pert_j.gt.ny) 
            write (6,"(3x,'j ... (1-',i4,') ?')") ny
            read (5,*) pert_j
         end do

      else 

c By long/lat 
         check_d = 0
         write (6,"(/,3x,a)")
     $        'Enter location''s lon/lat (x,y) ... '
         do while (check_d .eq. 0) 
            write (6,"(6x,a)") 'longitude ... (E)?'
            read (5,*) pert_x

            write (6,"(6x,a)") 'latitude ... (N)?'
            read (5,*) pert_y

            call ijloc(pert_x,pert_y,pert_i,pert_j,xc,yc,nx,ny)

c Make sure point is wet      
            if (bathy(pert_i,pert_j) .le. 0.) then
               write (6,1007) pert_i,pert_j
 1007          format(/,6x,'Closest C-grid (',i2,1x,i4,') is dry.')
               write (6,"(6x,a,f7.1)") 'Depth (m)= ',
     $            bathy(pert_i,pert_j)
               write (6,"(6x,a)")'Select another point ... '
            else
               check_d = 1
            endif
         end do

      endif

c Confirm location 
      write(6,"(/,a,i2,2x,i4)")
     $     ' ...... Chosen point is (i,j) = ',pert_i,pert_j
      write(6,"(9x,a,f6.1,1x,f5.1)") 
     $    'C-grid is (long E, lat N) = ',
     $     xc(pert_i,pert_j),yc(pert_i,pert_j)
      write (6,"(9x,a,f7.1,/)") 'Depth (m)= ',
     $     bathy(pert_i,pert_j)

      return
      end subroutine slct_2d_pt
c 
c ============================================================
c 
      subroutine slct_3d_pt(pert_i,pert_j,pert_k)
c Pick 3d model grid point 

c argument 
      integer pert_i, pert_j, pert_k

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

c local variables
      integer iloc, k
      real*4 pert_z
      real*4 dum1d(nr), dum0
c -------------

c Choose horizontal location 
      call slct_2d_pt(pert_i,pert_j)

c Choose depth 
      write (6,*) 'Choose depth ... '
      write (6,"(3x,a)")
     $     'Enter 1 to select native vertical level (k),  '
      write (6,"(6x,a)")
     $     'or 9 to select by meters ... (1 or 9)? '
      read (5,*) iloc

      if (iloc .ne. 9) then 

c By native vertical level 
         pert_k = 0

         write(6,"(/,3x,a)")
     $        'Identify point in native vertical level ... '
         do while (pert_k.lt.1 .or. pert_k.gt.nr) 
            write (6,"(3x,'k ... (1-',i2,') ?')") nr
            read (5,*) pert_k
         end do

      else 

c By depth in meters
         write (6,"(/,3x,a)")
     $        'Enter location''s distance from surface ... (m)?'
         read (5,*) pert_z

         pert_k = 0  ! bottom wet point 
         do k=1,nr
            if (bathy(pert_i,pert_j) .gt. abs(rc(k))) pert_k = k
         end do

         dum1d = abs(rc+pert_z)  ! rc is negative 
c         idum = minloc(dum1d)
         dum0 = dum1d(1)
         idum = 1
         do k=2,pert_k
            if (dum1d(k).lt.dum0) then
               dum0=dum1d(k)
               idum = k
            endif
         end do
         if (idum .lt. pert_k) pert_k=idum

      endif

c Confirm location 
      write(6,"(/,a,i2,2x,i4)")
     $     ' ...... closest wet level is (k) = ',pert_k
      write(6,"(9x,a,2x,f7.1)") 
     $    '  at depth (m) = ',rc(pert_k)

      return
      end subroutine slct_3d_pt
