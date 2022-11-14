c 
c ============================================================
c 
      subroutine samp_mon(objf, mobjf, nrec)
c Sample monthly mean state

c
      real*4 objf(*)
      real*4 mobjf
      integer nrec

      external StripSpaces

c Objective function 
      integer nvar    ! number of OBJF variables 
      parameter (nvar=5)    
      character*72 f_var(nvar), f_unit(nvar)
      common /objfvar/f_var, f_unit

c Strings for naming output directory
      character*256 floc_time ! OBJF time-period
      character*256 floc_var  ! first variable defined as OBJF 
      character*256 floc_loc  ! location (mask) of first OBJF variable
      character*256 dir_out   ! output directory
      common /floc/floc_time, floc_var, floc_loc, dir_out

c
      character*256 f_command
      logical f_exist
      character*6 f0, f1  ! For different OBJF variables 

c --------------
c Define OBJF's VARIABLE 

      write(6,"(3x,a)") '==> Sampling MONTHLY means ... '
      write(51,"(3x,a)") '==> Sampling MONTHLY means ... '
      
      nobjf = 0 ! number of OBJF variables 
      iobjf = 1
      write(f1,"(i1)") 1 
      call StripSpaces(f1)

      do while (iobjf .ge. 1 .and. iobjf .le. nvar) 

         write (6,"(/,a)") '------------------'
         write (6,"(3x,a,i1,a,i1,a)")
     $     'Choose OBFJ variable # ',nobjf+1,' ... (1-',nvar,')?'
         write(6,"(3x,a)") '(Enter 0 to end variable selection)'

         read (5,*) iobjf

         if (iobjf.ge.1 .and. iobjf.le.nvar) then 
c Process OBJF variable 
         nobjf = nobjf + 1

         write(6,"(3x,a,i2,1x,a,a)") 'OBJF variable ',
     $        nobjf, 'is ',trim(f_var(iobjf))

         write(51,"(/,a)") '------------------'
         write(51,"(a,i2,a,a)") 'OBJF variable # ',nobjf
         write(51,"(3x,'iobjf = ',i2)") iobjf
         write(51,"(3x,a,a,/)")
     $        ' --> OBJF variable : ', trim(f_var(iobjf))

c Create data.ecco entries for new variable, if not the first
         if (nobjf .ne. 1) then 
            write(f0,"(i2)") nobjf-1
            write(f1,"(i2)") nobjf

            call StripSpaces(f0)
            call StripSpaces(f1)

c Duplicate entries for new variable in data.ecco 
c e.g., sed -e '/(1)/{p;s|(1)|(2)|}' data.ecco 
            f_command = 'sed -i -e '//
     $        '"/(' // trim(f0) // ')/{p;s|(' // trim(f0) //
     $         ')|(' // trim(f1) // ')|}" data.ecco'
            call execute_command_line(f_command, wait=.true.)
         else
            write(floc_var,"(i2)") iobjf
            call StripSpaces(floc_var)
         endif

c Define new OBJF variable 
         call objf_var(f1,iobjf,floc_loc)

         else if (nobjf .eq. 0) then
            write(6,*) 'Invalid selection ... Terminating.'
            stop
         endif 

      end do 

c Create output directory before sampling 
      write(f_command,1001) trim(floc_time),
     $     trim(floc_var), trim(floc_loc), nobjf
 1001 format(a,"_",a,"_",a,"_",i2)
      call StripSpaces(f_command)

      dir_out = 'emu_samp_' // trim(f_command)
      write(6,"(/,a,a,/)")
     $     'Sampling Tool output will be in : ',trim(dir_out)

      inquire (file=trim(dir_out), EXIST=f_exist)
      if (f_exist) then
         write (6,*) '**** Error: Directory exists already : ',
     $        trim(dir_out) 
         write (6,*) '**** Rename existing directory and try again. '
         stop
      endif

      f_command = 'mkdir ' // dir_out
      call execute_command_line(f_command, wait=.true.)

c Extract OBJF  
      call samp_mon_objf(objf, mobjf, nrec)

      return 
      end subroutine 
c 
c ============================================================
c 
      subroutine samp_day(objf, mobjf, nrec)
c Sample daily mean state

c
      real*4 objf(*)
      real*4 mobjf
      integer nrec

      external StripSpaces

c Objective function 
      integer nvar    ! number of OBJF variables 
      parameter (nvar=5)    
      character*72 f_var(nvar), f_unit(nvar)
      common /objfvar/f_var, f_unit

c Strings for naming output directory
      character*256 floc_time ! OBJF time-period
      character*256 floc_var  ! first variable defined as OBJF 
      character*256 floc_loc  ! location (mask) of first OBJF variable
      character*256 dir_out   ! output directory
      common /floc/floc_time, floc_var, floc_loc, dir_out

c
      character*256 f_command
      logical f_exist
      character*6 f0, f1  ! For different OBJF variables 

c --------------
c Define OBJF's VARIABLE 

      write(6,"(3x,a)") '==> Sampling daily means ... '
      write(51,"(3x,a)") '==> Sampling daily means ... '
      
      nobjf = 0 ! number of OBJF variables 
      iobjf = 1
      write(f1,"(i1)") 1 
      call StripSpaces(f1)

      do while (iobjf .ge. 1 .and. iobjf .le. 2) 

         write (6,"(/,a)") '------------------'
         write (6,"(3x,a,i1,a,i1,a)")
     $     'Choose OBFJ variable # ',nobjf+1,' ... (1-2)?'
         write(6,"(3x,a)") '(Enter 0 to end variable selection)'

         read (5,*) iobjf

         if (iobjf.ge.1 .and. iobjf.le.2) then 
c Process OBJF variable 
         nobjf = nobjf + 1

         write(6,"(3x,a,i2,1x,a,a)") 'OBJF variable ',
     $        nobjf, 'is ',trim(f_var(iobjf))

         write(51,"(/,a)") '------------------'
         write(51,"(a,i2,a,a)") 'OBJF variable # ',nobjf
         write(51,"(3x,'iobjf = ',i2)") iobjf
         write(51,"(3x,a,a,/)")
     $        ' --> OBJF variable : ', trim(f_var(iobjf))

c Create data.ecco entries for new variable, if not the first
         if (nobjf .ne. 1) then 
            write(f0,"(i2)") nobjf-1
            write(f1,"(i2)") nobjf

            call StripSpaces(f0)
            call StripSpaces(f1)

c Duplicate entries for new variable in data.ecco 
c e.g., sed -e '/(1)/{p;s|(1)|(2)|}' data.ecco 
            f_command = 'sed -i -e '//
     $        '"/(' // trim(f0) // ')/{p;s|(' // trim(f0) //
     $         ')|(' // trim(f1) // ')|}" data.ecco'
            call execute_command_line(f_command, wait=.true.)
         else
            write(floc_var,"(i2)") iobjf
            call StripSpaces(floc_var)
         endif

c Define new OBJF variable 
         call objf_var(f1,iobjf,floc_loc)

         else if (nobjf .eq. 0) then
            write(6,*) 'Invalid selection ... Terminating.'
            stop
         endif 

      end do 

c Create output directory before sampling 
      write(f_command,1001) trim(floc_time),
     $     trim(floc_var), trim(floc_loc), nobjf
 1001 format(a,"_",a,"_",a,"_",i2)
      call StripSpaces(f_command)

      dir_out = 'emu_samp_' // trim(f_command)
      write(6,"(/,a,a,/)")
     $     'Sampling Tool output will be in : ',trim(dir_out)

      inquire (file=trim(dir_out), EXIST=f_exist)
      if (f_exist) then
         write (6,*) '**** Error: Directory exists already : ',
     $        trim(dir_out) 
         write (6,*) '**** Rename existing directory and try again. '
         stop
      endif

      f_command = 'mkdir ' // dir_out
      call execute_command_line(f_command, wait=.true.)

c Extract OBJF  
      call samp_day_objf(objf, mobjf, nrec)

      return 
      end subroutine 
c 
c ============================================================
c 
      subroutine samp_mon_objf(objf, mobjf, nrec)
c Compute OBJF based on monthly mean state

c
      real*4 objf(*)
      real*4 mobjf
      integer nrec
c
      character*256 tooldir   ! directory where tool files are 
      common /tool/tooldir

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny)
      common /grid/xc, yc, rc, bathy

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
      parameter(nmonths=312) ! max number of months of V4r4
      real*4 objf_1(nmonths), objf_2(nmonths)
      real*4 mobjf_1, mobjf_2
      integer nobjf 
      character*256 ffile, fmask

      real*4 dum2d(nx,ny), dum3d(nx,ny,nr)

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

      write(6,"(a,/)") 'Sampling MONTHLY means ... '
      write(6,*) 'nobjf = ',nobjf

c ------------------
c Read in model state

      do i=1,nobjf

         if (gencost_barfile(i).eq.'m_boxmean_eta_dyn') then 
            ffile = 'state_2d_set1_mon'
            fmask = trim(gencost_mask(i)) // 'C'
            call chk_mask2d(fmask,nx,ny,dum2d)
            call samp_2d_r8_wgtd(tooldir,ffile,1,dum2d,
     $           objf_1,nrec,mobjf_1)

         else if (gencost_barfile(i).eq.'m_boxmean_obp') then 
            ffile = 'state_2d_set1_mon'
            fmask = trim(gencost_mask(i)) // 'C'
            call chk_mask2d(fmask,nx,ny,dum2d)
            call samp_2d_r8_wgtd(tooldir,ffile,2,dum2d,
     $           objf_1,nrec,mobjf_1)

         else if (gencost_barfile(i).eq.'m_boxmean_THETA') then 
            ffile = 'state_3d_set1_mon'
            fmask = trim(gencost_mask(i)) // 'C'
            call chk_mask3d(fmask,nx,ny,nr,dum3d)
            call samp_3d_wgtd(tooldir,ffile,1,dum3d,
     $           objf_1,nrec,mobjf_1)

         else if (gencost_barfile(i).eq.'m_boxmean_SALT') then 
            ffile = 'state_3d_set1_mon'
            fmask = trim(gencost_mask(i)) // 'C'
            call chk_mask3d(fmask,nx,ny,nr,dum3d)
            call samp_3d_wgtd(tooldir,ffile,2,dum3d,
     $           objf_1,nrec,mobjf_1)

         else if (gencost_barfile(i).eq.'m_horflux_vol') then 
            ffile = 'state_3d_set1_mon'
            fmask = trim(gencost_mask(i)) // 'W'
            call chk_mask3d(fmask,nx,ny,nr,dum3d)
            call samp_3d_wgtd(tooldir,ffile,3,dum3d,
     $           objf_1,nrec,mobjf_1)

            fmask = trim(gencost_mask(i)) // 'S'
            call chk_mask3d(fmask,nx,ny,nr,dum3d)
            call samp_3d_wgtd(tooldir,ffile,4,dum3d,
     $           objf_2,nrec,mobjf_2)

            objf_1 = objf_1 + objf_2
            mobjf_1 = mobjf_1 + mobjf_2

         else
            write(6,*) 'This should not happen ... '
            stop
         endif
            
         objf_1 = objf_1*mult_gencost(i)
         mobjf_1 = mobjf_1*mult_gencost(i)

         objf(1:nrec) = objf(1:nrec) + objf_1(1:nrec)
         mobjf = mobjf + mobjf_1

      enddo

      return 
      end subroutine 
c 
c ============================================================
c 
      subroutine samp_day_objf(objf, mobjf, nrec)
c Compute OBJF based on daily mean state

c
      real*4 objf(*)
      real*4 mobjf
      integer nrec
c
      character*256 tooldir   ! directory where tool files are 
      common /tool/tooldir

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny)
      common /grid/xc, yc, rc, bathy

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
      parameter(ndays=9497) ! max number of days in V4r4
      real*4 objf_1(ndays), objf_2(ndays)
      real*4 mobjf_1, mobjf_2
      integer nobjf 
      character*256 ffile, fmask

      real*4 dum2d(nx,ny)

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

      write(6,"(a,/)") 'Sampling DAILY means ... '
      write(6,*) 'nobjf = ',nobjf

c ------------------
c Read in model state

      do i=1,nobjf

         if (gencost_barfile(i).eq.'m_boxmean_eta_dyn') then 
            ffile = 'state_2d_set1_day'
            fmask = trim(gencost_mask(i)) // 'C'
            call chk_mask2d(fmask,nx,ny,dum2d)
            call samp_2d_r8_wgtd(tooldir,ffile,1,dum2d,
     $           objf_1,nrec,mobjf_1)

         else if (gencost_barfile(i).eq.'m_boxmean_obp') then 
            ffile = 'state_2d_set1_day'
            fmask = trim(gencost_mask(i)) // 'C'
            call chk_mask2d(fmask,nx,ny,dum2d)
            call samp_2d_r8_wgtd(tooldir,ffile,2,dum2d,
     $           objf_1,nrec,mobjf_1)

         else
            write(6,*) 'This should not happen ... '
            stop
         endif
            
         objf_1 = objf_1*mult_gencost(i)
         mobjf_1 = mobjf_1*mult_gencost(i)

         objf(1:nrec) = objf(1:nrec) + objf_1(1:nrec)
         mobjf = mobjf + mobjf_1

      enddo

      return 
      end subroutine 
