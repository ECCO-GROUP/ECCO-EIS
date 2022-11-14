      program samp
c -----------------------------------------------------
c Program for Sampling Tool (V4r4)
c Samples model output.  
c     
c 21 September 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
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
      character*1 fmd ! Monthly or Daily time-series 

c OBJF 
      parameter(ndays=9497)
      real*4 objf(ndays)
      real*4 mobjf
      integer nrec

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
      write (6,"(/,a,/)") 'Extracting model time-series ... '
      write (6,*) 'Define objective function (OBJF) ... '

c --------------
c Save OBJF information for reference. 
      file_out = 'samp.info'
      open (51, file=file_out, action='write')
      write(51,"(a)") '***********************'
      write(51,"(a)") 'Output of samp.f'
      write(51,"(a)")
     $     'Sampling Tool objective function (OBJF) specification'
      write(51,"(a,/)") '***********************'

c --------------
c Set up data.ecco with OBJF specification

      f_command = 'cp -f data.ecco_adj data.ecco'
      call execute_command_line(f_command, wait=.true.)

c --------------
c Define OBJF's VARIABLE 
      write (6,*) 'Available VARIABLES are ... '
      do i=1,nvar
         write (6,"(3x,i2,') ',a,1x,a)")
     $        i,trim(f_var(i)),trim(f_unit(i))
      enddo

c --------------
c Monthly mean or daily mean 
      fmd = 'x'
      do while (fmd.ne.'m' .and. fmd.ne.'M' .and.
     $     fmd.ne.'d' .and. fmd.ne.'D') 

         write (6,"(/,3x,a)") 'Monthly or Daily mean ... (m/d)?'
         write (6,"(3x,a)")
     $        '(NOTE: daily mean available for SSH and OBP only.)'
         read(5,*) fmd

      enddo

      write(6,"(/,3x,a,a)") 'fmd = ',fmd
      write(51,"(/,3x,a,a)") 'fmd = ',fmd
      
      if (fmd.eq.'d' .or. fmd.eq.'D') then 
         floc_time = 'd'
         call samp_day(objf, mobjf, nrec)
      else
         floc_time = 'm'
         call samp_mon(objf, mobjf, nrec)
      endif

      close (51)

c --------------
c Output sampled state

      write(f_command,'("_",i5)') nrec
      call StripSpaces(f_command)

      file_out = trim(dir_out) // '/samp.out' // trim(f_command)
      open (51, file=file_out, action='write', access='stream')
      write(51) objf(1:nrec)
      write(51) mobjf 
      close(51)

      f_command = 'mv samp.info ' // trim(dir_out)
      call execute_command_line(f_command, wait=.true.)

      f_command = 'mv data.ecco ' // trim(dir_out)
      call execute_command_line(f_command, wait=.true.)

c --------------
c Delete objf_*_mask* files. 
c Can otherwise cause an error message if samp.x is run again, 
c because INQUIRE returns EXIST=.false. for dangling symbolic links. 
      f_command = 'rm -f objf_*_mask*'
      call execute_command_line(f_command, wait=.true.)

      write(6,"(a,/)") '... Done.'

      stop
      end
      
