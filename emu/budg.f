      program budg
c -----------------------------------------------------
c Program for Budget Tool (V4r4)
c Set up data.ecco for budget analysis by do_budg.f. 
c     
c 02 August 2023, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces
c files
      character*256 setup   ! directory where tool files are 
      character*256 f_inputdir   ! where external tool files exist
      common /tool/f_inputdir
      character*130 file_in, file_out  ! file names 
c
      character*256 f_command
      logical f_exist
      character*6 f0, f1  ! For different OBJF variables 

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny)
      common /grid/xc, yc, rc, bathy

c Objective function 
      integer nvar    ! possible number of OBJF variables 
      parameter (nvar=5)    
      character*72 f_var(nvar), f_unit(nvar)
      common /objfvar/f_var, f_unit

c Strings for naming output directory
      character*256 floc_time ! OBJF time-period
      character*256 floc_var  ! first variable defined as OBJF 
      character*256 floc_loc  ! location (mask) of first OBJF variable
      character*256 dir_out   ! output directory
      common /floc/floc_time, floc_var, floc_loc, dir_out

      character*256 dir_run   ! run directory
      character*256 fcwd      ! current working directory

      integer date_time(8)  ! arrrays for date 
      character*10 bb(3)
      character*256 fdate 
c 
      character*1 fmd ! Monthly or Daily time-series 

c OBJF 
      parameter(ndays=9497)
      real*4 objf(ndays)
      real*4 mobjf
      integer nrec

      parameter(nmonths=312) ! max number of months of V4r4
      real*4 tmask(nmonths)
      character*256 fmask

c --------------
c Set directory where external tool files exist
      call getarg(1,f_inputdir)
      write(6,*) 'inputdir read : ',trim(f_inputdir)

c --------------
c Set directory where tool files exist
      open (50, file='tool_setup_dir')
      read (50,'(a)') setup
      close (50)
      write(6,*) 'tool files read : ',trim(setup)

c --------------
c Read model grid from EMU tool directory (XC, YC is fully
c specified. Those used in the model have blank regions.)
c 
c      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/XC.data'
      file_in = trim(setup) // '/emu/emu_input/XC.data'
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

c      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/YC.data'
      file_in = trim(setup) // '/emu/emu_input/YC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) yc
      close (50)

c      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/RC.data'
      file_in = trim(setup) // '/emu/emu_input/RC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) rc
      close (50)

c      file_in = trim(f_inputdir) // '/emu_pert_ref_budg/Depth.data'
      file_in = trim(setup) // '/emu/emu_input/Depth.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) bathy
      close (50)
      
c --------------
c Variable name
      f_var(1) = 'Volume'
      f_var(2) = 'Heat (theta)'
      f_var(3) = 'Salt'   
      f_var(4) = 'Salinity'   
      f_var(5) = 'Momentum'

      f_unit(1) = '(m^3)'
      f_unit(2) = '(degC)'   
      f_unit(3) = '(PSU)'    
      f_unit(4) = '(PSU)'    
      f_unit(5) = '(m/s)'     

c --------------
c Interactive specification of budget variable 
      write (6,"(/,a,/)") 'Extracting budget time-series ... '
      write (6,*) 'Define budget variable ... '

c --------------
c Save OBJF information for reference. 
      file_out = 'budg.info'
      open (51, file=file_out, action='write')
      write(51,"(a)") '***********************'
      write(51,"(a)") 'Output of budg.f'
      write(51,"(a)")
     $     'Budget Tool variable specification'
      write(51,"(a,/)") '***********************'

c --------------
c Set up data.ecco with OBJF specification

      f_command = 'cp -f data.ecco_adj data.ecco'
      call execute_command_line(f_command, wait=.true.)

c --------------
c Define OBJF's VARIABLE 
      write (6,*) 'Available VARIABLES are ... '
cif      do i=1,nvar
      do i=1,4   ! exclude momentum until implemented 
         write (6,"(3x,i2,') ',a,1x,a)")
     $        i,trim(f_var(i)),trim(f_unit(i))
      enddo

c --------------
c Only Monthly mean 
      write(6,"(3x,a)") '==> Budget is MONTHLY ... '
      write(51,"(3x,a)") '==> Budget is MONTHLY ... '
      mvar = nvar
      floc_time = 'm'
      f_command = 'sed -i -e '//
     $     '"s|OBJF_PRD|month|g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

c Create dummy temporal mask
      fmask='budg_mask_T'
      INQUIRE(FILE=trim(fmask), EXIST=f_exist)
      if (f_exist) then
         f_command = 'rm -f ' // trim(fmask)
         call execute_command_line(f_command, wait=.true.)
      endif
      open(60,file=fmask,form='unformatted',access='stream')
      write(60) tmask
      close(60)

c Loop among OBJF variables 
      write(f1,"(i1)") 1 
      call StripSpaces(f1)

c     Define OBJF variable
      write (6,"(/,a)") '------------------'
      write (6,"(3x,a,a,i1,a)")
     $     'Choose budget variable (v in Eq 1 of Guide) ',
     $        ' ... (1-',mvar,')?'

      read (5,*) iobjf

      if (iobjf.ge.1 .and. iobjf.le.mvar) then 
c Process budget variable 
         write(6,"(3x,a,1x,a,a)") 'Budget variable ',
     $        'is ',trim(f_var(iobjf))

         write(51,"(/,a)") '------------------'
         write(51,"(a,a,a)") 'Budget variable '
         write(51,"(3x,'iobjf = ',i2)") iobjf
         write(51,"(3x,a,a,1x,a/)") ' --> budget variable : ',
     $        trim(f_var(iobjf)),trim(f_unit(iobjf))

c Create data.ecco entry for OBJF variable
         write(floc_var,"(i2)") iobjf
         call StripSpaces(floc_var)

c Define Budget variable 
         call budg_var(f1,iobjf,floc_loc)

      else 
         write(6,*) 'Invalid selection ... Terminating.'
         stop
      endif 

      close (51)

c Create output directory before extracting budget 
      write(f_command,1001) trim(floc_time),
     $     trim(floc_var), trim(floc_loc)
 1001 format(a,"_",a,"_",a)
      call StripSpaces(f_command)

      dir_out = 'emu_budg_' // trim(f_command)
      write(6,"(/,a,a,/)")
     $     'Budget Tool output will be in : ',trim(dir_out)

      inquire (file=trim(dir_out), EXIST=f_exist)
      if (f_exist) then
         write (6,*) '**** WARNING: Directory exists already : ',
     $        trim(dir_out) 
         call date_and_time(bb(1), bb(2), bb(3), date_time)
         write(fdate,"('_',i4.4,2i2.2,'_',3i2.2)")
     $     date_time(1:3),date_time(5:7)
         dir_out = trim(dir_out) // trim(fdate)
         write(6,"(/,a,a,/)")
     $        '**** Renaming output directory to : ',trim(dir_out)
      endif

      f_command = 'mkdir ' // dir_out
      call execute_command_line(f_command, wait=.true.)
      call getcwd(fcwd)
      dir_run = trim(fcwd) // '/' // trim(dir_out) // '/temp'
      f_command = 'mkdir ' // dir_run
      call execute_command_line(f_command, wait=.true.)

      file_out = 'budg.dir_out'
      open (52, file=file_out, action='write')
      write(52,"(a)") trim(dir_out)
      write(52,"(a)") trim(dir_run)
      write(52,"(a)") trim(dir_out) // '/output'
      close(52)

      write(6,"(a,/)") '... Done budg setup of data.ecco'

c Move all needed files into run directory
cif      f_command = 'sed -i -e "s|YOURDIR|'//
cif     $     trim(dir_run) //'|g" do_budg.csh'
cif      call execute_command_line(f_command, wait=.true.)

      f_command = 'mv budg.info ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

      f_command = 'mv data.ecco ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

      f_command = 'cp -p budg.dir_out ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

      f_command = 'cp -p tool_setup_dir ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

      f_command = 'cp -p budg_*_mask* ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

c Wrapup 
cif      write(6,"(/,a)") '*********************************'
cif      f_command = 'do_budg.csh'
cif      write(6,"(4x,a)") 'Run "' // trim(f_command) //
cif     $     '" to conduct budget.'
cif      write(6,"(a,/)") '*********************************'

      stop
      end
c 
c ============================================================
c 
      subroutine budg_var(f1,iobjf,floc_loc)
c Specifiy Budget variable

c Argument 
      character*6 f1 ! OBJF variable order (counter)
      integer iobjf  ! OBJF variable index 
      character*256 floc_loc  ! location (mask) of OBJF variable

c local variables
      character*256 f_command
      character*256 fmask
      logical f_exist

c ------------
c Specify spatial mask (weight)
      call budg_var_3d(f1, iobjf,floc_loc)

c Create time mask for variable (link common time mask) 
      fmask = 'budg_' // trim(f1) // '_mask_T' 
      INQUIRE(FILE=trim(fmask), EXIST=f_exist)
      if (f_exist) then
         f_command = 'rm -f ' // trim(fmask)
         call execute_command_line(f_command, wait=.true.)
      endif
      f_command = 'ln -s budg_mask_T ' // trim(fmask)
      call execute_command_line(f_command, wait=.true.)

c Edit data.ecco mask field  
      f_command = 'sed -i -e ' //
     $     '"s/mask(' // trim(f1) //
     $     ').*/mask(' // trim(f1) //
     $     ')=''budg_' // trim(f1) // '_mask_''/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

      return
      end subroutine
c 
c ============================================================
c 
      subroutine budg_var_3d(f1, iobjf, floc_loc)

c Update data.ecco OBJF for Budget
      character*6 f1
      integer iobjf
      character*256 floc_loc  ! location (mask) of first OBJF variable
      integer ip1,ip2

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny)
      common /grid/xc, yc, rc, bathy
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

c     
      real*4 x1,x2,y1,y2,z1,z2 

c ------
c Identify Budget OBJF variable
      if (iobjf.eq.1) then
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''m_boxmean_VOLUME''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.2) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''m_boxmean_HEAT''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.3) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''m_boxmean_SALT''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.4) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''m_boxmean_SALINITY''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.5) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''m_boxmean_MOMENTUM''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else
         write(6,*) 'iobjf is NG for budg_var_3d ... ', iobjf
         write(6,*) 'This should not happen. Aborting ...'
         stop
      endif

c ------
c Select type of spatial mask 
      ifunc = 0
      write (6,*) 
      do while (ifunc.ne.1 .and. ifunc.ne.2) 
         write (6,*) 'Choose budget for a single model '//
     $        'grid point (1) or '
         write (6,"(10x,a)") 
     $        'over a larger volume (2) ... (1/2)?'
         read (5,*) ifunc
      end do

      write(51,"(3x,'ifunc = ',i2)") ifunc

      if (ifunc .eq. 1) then 
c When OBJF is at a point

         write(6,"(3x,a,/)")
     $        '... Budget will be at a point'

         write(51,"(3x,a,/)")
     $        '... Budget will be at a point'

         call slct_3d_pt(pert_i,pert_j,pert_k)

         write(51,2002) pert_i,pert_j,pert_k
 2002    format(3x,'pert_i, pert_j, pert_k = ',i2,2x,i4,2x,i2)
         write(51,"(3x,a,/)")
     $        ' --> Budget model grid location (i,j,k).'

c Create 3d mask for the point 
         dum3d = 0.
         dum3d(pert_i,pert_j,pert_k) = 1. 

         f_command = 'sed -i -e ' //
     $  '"s/mask(' // trim(f1) //
     $ ').*/mask(' // trim(f1) //
     $ ')=''budg_' // trim(f1) // '_mask_''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)

         fmask = 'budg_' // trim(f1) // '_mask_C'
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

c When OBJF is VARIABLE over a volume

         write(6,*)
     $    '... Budget will be over a volume'
         write(51,"(3x,a)")
     $   ' --> Budget will be over a volume'


c
         ivol = 0
         do while (ivol.ne.1 .and. ivol.ne.2) 

         write(6,"(/,a)")
     $           'Choose either a lat/lon/depth volume (1) or '
         write(6,*)
     $  '   a volume specified in a user-provided file (2) ... (1/2)?'
         write(6,*)
     $  "(user file must be in model's native binary format)"

         read (5,*) ivol

         end do

         write(51,"(3x,'ivol = ',i2)") ivol

         if (ivol.eq.1) then 
c When Volume is over lat/lon/depth
            call cr8_mask3d(dum3d,x1,x2,y1,y2,z1,z2)

            f_command = 'sed -i -e ' //
     $           '"s/mask(' // trim(f1) //
     $           ').*/mask(' // trim(f1) //
     $           ')=''budg_' // trim(f1) // '_mask_''/g" data.ecco'
            call execute_command_line(f_command, wait=.true.)

            fmask = 'budg_' // trim(f1) // '_mask_C'
            INQUIRE(FILE=trim(fmask), EXIST=f_exist)
            if (f_exist) then
               f_command = 'rm -f ' // trim(fmask)
               call execute_command_line(f_command, wait=.true.)
            endif
            open(60,file=fmask,form='unformatted',access='stream')
            write(60) dum3d
            close(60)

c Save location for naming run directory
            write(floc_loc,'(5(f6.1,"_"),f6.1)')
     $           x1,x2,y1,y2,z1,z2
            call StripSpaces(floc_loc)

         else
c When Volume is specified in user-provided file 

c Get mask file name 
         write(6,*) '   Enter MASK filename (T in Eq 1 of Guide) ... ?'  
         read(5,'(a)') fmask

         write(51,'(3x,"fmask = ",a)') trim(fmask)
         write(51,"(3x,a,/)") ' --> MASK file. '

c Save mask file name for naming run directory
         ip1 = index(fmask,'/',.TRUE.)
         ip2 = len(fmask)
         floc_loc = trim(fmask(ip1+1:ip2))
         call StripSpaces(floc_loc)

c Check mask 
         call chk_mask3d(fmask,nx,ny,nr,dum3d)

c Link input mask to what model expects 
         fdum = 'budg_' // trim(f1) // '_mask_C' 
         INQUIRE(FILE=trim(fdum), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fdum)
            call execute_command_line(f_command, wait=.true.)
         endif

         f_command = 'ln -s ' // trim(fmask) // ' ' //
     $        trim(fdum)
         call execute_command_line(f_command, wait=.true.)

         endif  ! end of volume mask 
      endif  ! end of 3d mask 


c Specify variable is 3D      
      f_command = 'sed -i -e ' //
     $     '"s/is3d(' // trim(f1) //
     $     ').*/is3d(' // trim(f1) //
     $     ')=.TRUE.,/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

      return
      end subroutine
c 
c ============================================================
c 
      subroutine cr8_mask3d(dum3d,x1,x2,y1,y2,z1,z2)

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny)
      common /grid/xc, yc, rc, bathy
c 
      real*4 dum3d(nx,ny,nr)
      real*4 x1,x2,y1,y2,z1,z2 

      real*4 dumx(nx,ny), dumy(nx,ny), dumz(nr), dum 
      real*4 dum2d(nx,ny)
      real*4 vcheck

c ------
c Volume must span at least one model grid pint 
      vcheck = 0.

      do while (vcheck .eq. 0) 

c ------
c Select min/max longitude, latitude, depth 
      x1 = -200.
      do while (x1.lt.-180. .or. x1.gt.180.) 
         write(6,*) 'Enter west most longitude (-180E to 180E)... x1?'
         read(5,*) x1
      end do

      x2 = -200.
      do while (x2.lt.-180. .or. x2.gt.180.) 
         write(6,*) 'Enter east most longitude (-180E to 180E)... x2?'
         write(6,*) '   (choose x2=x1 for zonally global volume) '
         read(5,*) x2
      end do

      y1 = -100.
      do while (y1.lt.-90. .or. y1.gt.90.) 
         write(6,*) 'Enter south most latitude (-90N to 90N)... y1?'
         read(5,*) y1
      end do

      y2 = -100.
      do while (y2.lt.-90. .or. y2.gt.90. .or. y2.lt.y1) 
         write(6,*) 'Enter north most latitude (-90N to 90N)... y2?'
         read(5,*) y2
      end do
      
      z1 = -100.
      do while (z1.lt.0. .or. z1.gt.6000.) 
         write(6,*) 'Enter deepest depth (0-6000m) ... z1?'
         read(5,*) z1
      end do
      
      z2 = -100.
      do while (z2.lt.0. .or. z2.gt.6000. .or. z2.gt.z1) 
         write(6,*) 'Enter shallowest depth (0-6000m)... z2?'
         read(5,*) z2
      end do 

c Find all (i,j,k) locations that is within volume 
      dumx(:,:) = 0.
      dumy(:,:) = 0.
      dumz(:) = 0.

      if (x1.eq.x2) then 
         dumx(:,:) = 1.
      elseif (x1.lt.x2) then 
         do i=1,nx
            do j=1,ny
               if (xc(i,j).ge.x1 .and. xc(i,j).le.x2) dumx(i,j) = 1.
            enddo
         enddo
      else
         do i=1,nx
            do j=1,ny
               if (xc(i,j).ge.x1 .or. xc(i,j).le.x2) dumx(i,j) = 1.
            enddo
         enddo
      endif

      if (y1.eq.-90. .and. y2.eq.90.) then
         dumy(:,:) = 1.
      else
         do i=1,nx
            do j=1,ny
               dum = (yc(i,j)-y1)*(yc(i,j)-y2)
               if (dum.le.0.) dumy(i,j) = 1.
            enddo
         enddo
      endif
         
      if (z1.eq.0. .and. z2.eq.6000.) then
         dumz(:) = 1.
      else
         do k=1,nr
            dum = (rc(k)+z1)*(rc(k)+z2) ! rc is negative 
            if (dum.le.0.) dumz(k) = 1.
         enddo
      endif
         
      do i=1,nx
         do j=1,ny
            do k=1,nr
               dum3d(i,j,k) = dumx(i,j)*dumy(i,j)*dumz(k)
            enddo
         enddo
      enddo

c ------
c Check Volume
      vcheck = 0.
      do i=1,nx
         do j=1,ny
            do k=1,nr
               vcheck = vcheck + dum3d(i,j,k)
            enddo
         enddo
      enddo
      
      if (vcheck.eq.0.) then
         write(6,*) 'NG: Volume is empty.'
         write(6,*) 'Volume must span at least one grid point. '
         write(6,*) 'Re-Enter volume specification ... '
      endif

      end do  ! end while 
c 
      return
      end subroutine

     
      
      
