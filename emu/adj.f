      program adj
c -----------------------------------------------------
c Program for Adjoint Tool (V4r4)
c
c Define objective function for Adjoint Tool.
c Modify data and data.ecco and create masks.
c 
c 21 September 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces
c files
      character*256 tooldir   ! directory where tool files are 
      character*130 file_in, file_out  ! file names 

      logical f_exist

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny)
      common /grid/xc, yc, rc, bathy

c Objective function 
      integer nvar    ! number of OBJF variables 
      parameter (nvar=5)    
      character*72 f_var(nvar), f_unit(nvar)

c
      character*256 f_command
      character*6 f0, f1  ! For different OBJF variables 

c Strings for naming output directory
      character*256 floc_time ! OBJF time-period
      character*256 floc_var  ! first variable defined as OBJF 
      character*256 floc_loc  ! location (mask) of first OBJF variable

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
c Variable name
      f_var(1) = 'SSH'
      f_var(2) = 'OBP'   
      f_var(3) = 'THETA'    
      f_var(4) = 'SALT'     
      f_var(5) = 'UV'   

      f_unit(1) = '(m)'
      f_unit(2) = '(equivalent sea level m)'   
      f_unit(3) = '(deg C)'    
      f_unit(4) = '(PSU)'     
      f_unit(5) = '(m/s)'   

c --------------
c Interactive specification of perturbation 

      write (6,"(/,a)") 'Define objective function (OBJF) ... '

c --------------
c Save OBJF information for reference. 
      file_out = 'adj.info'
      open (51, file=file_out, action='write')
      write(51,"(a)") '***********************'
      write(51,"(a)") 'Output of adj.f'
      write(51,"(a)")
     $     'Adjoint Tool objective function (OBJF) specification'
      write(51,"(a,/)") '***********************'

c --------------
c Set up data.ecco with OBJF specification

      f_command = 'cp -f data.ecco_adj data.ecco'
      call execute_command_line(f_command, wait=.true.)

c --------------
c Define OBJF's time-period (common to all variables defining OBJF)

      write(6,"(/,a,/)") 'First define OBJF time-period ... '
      
      f_command = 'sed -i -e '//
     $     '"s|OBJF_PRD|month|g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

      call objf_time(floc_time)

c --------------
c Define OBJF's VARIABLE(s) 

      write(6,"(/,a,/)") 'Next define OBJF variable(s) ... '

      write (6,"(3x,a)") 'Available VARIABLES are ... '
      do i=1,nvar
         write (6,"(3x,i2,') ',a,1x,a)")
     $        i,trim(f_var(i)),trim(f_unit(i))
      enddo

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

         if (iobjf.ne.0 .and. iobjf.le.nvar) then 
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

         endif ! iobjf.ne.0

      end do 

      close (51)

c Create concatenated string for naming run directory

      write(f_command,1001) trim(floc_time),
     $     trim(floc_var), trim(floc_loc), nobjf
 1001 format(a,"_",a,"_",a,"_",i2)
      call StripSpaces(f_command)

      file_out = 'emu_adj_' // trim(f_command)
      write(6,"(/,a,a,/)")
     $     'Adjoint Tool output will be in : ',trim(file_out)

      inquire (FILE=trim(file_out), EXIST=f_exist)
      if (f_exist) then
         write (6,*) '**** OUTPUT DIRECTORY ALREADY EXISTS **** '
         write (6,*) '**** RENAME EXISTING DIRECTORY ********** '
         write (6,*) '**** PBS JOB WILL FAIL OTHERWISE ******** '
      endif

      file_out = 'adj.str'
      open (50, file=file_out, action='write')
      write(50,'(a)') trim(f_command)
      close(50)

      write(6,"(/,a,a,/)") 'Wrote ',trim(file_out)

      stop
      end
