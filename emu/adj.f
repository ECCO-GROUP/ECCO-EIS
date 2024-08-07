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
      character*256 inputdir   ! directory where tool input files are 
      common /tool/inputdir
      character*130 file_in, file_out  ! file names 

      logical f_exist

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

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

c directories
      character*256 dir_out   ! output directory
      character*256 dir_run   ! run directory
      character*256 dir_fin   ! final result directory
      character*256 fcwd      ! current working directory

      integer date_time(8)  ! arrrays for date 
      character*10 bb(3)
      character*256 fdate 

c --------------
c Set directory where tool files exist
      open (50, file='input_setup_dir')
      read (50,'(a)') inputdir
      close (50)
      
c --------------
c Read model grid
      call grid_info
      
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

      write (6,"(/,a)") 'Define objective function (OBJF; '//
     $     'J^bar in Eq 5 of Guide) ... '

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

      write(6,"(/,a)") 'First define OBJF time-period '//
     $     '(t_start and t_g in Eq 6 of Guide) ... '
      
      f_command = 'sed -i -e '//
     $     '"s|OBJF_PRD|month|g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

      call objf_time(floc_time)

c --------------
c Define OBJF's VARIABLE(s) 

      write(6,"(/,a)") 'Next define OBJF variable(s) '//
     $     '(v in Eq 1 of Guide) ... '

      write (6,"(/,3x,a)") 'Available VARIABLES are ... '
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
     $     'Choose OBFJ variable (v in Eq 1 of Guide) # ',
     $        nobjf+1,' ... (1-',nvar,')?'
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

      dir_out = 'emu_adj_' // trim(f_command)
      write(6,"(/,a,a)")
     $     'Adjoint Tool output will be in : ',trim(dir_out)

      inquire (FILE=trim(dir_out), EXIST=f_exist)
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

      call emu_getcwd(fcwd)
      dir_fin = trim(fcwd) // '/' // trim(dir_out) // '/output'

      file_out = 'adj.dir_out'
      open (50, file=file_out, action='write')
      write(50,"(a)") trim(dir_out)
      write(50,"(a)") trim(dir_run)
      write(50,"(a)") trim(dir_fin) 
      close(50)

      write(6,"(/,a,a)") 'Wrote ',trim(file_out)

c Move all needed files into run directory
cif      f_command = 'sed -i -e "s|YOURDIR|'//
cif     $     trim(dir_run) //'|g" pbs_adj.csh'
cif      call execute_command_line(f_command, wait=.true.)
cif
cif      f_command = 'mv pbs_adj.csh ' // trim(dir_run)
cif      call execute_command_line(f_command, wait=.true.)
cif      
cif      f_command = 'ln -sf ' // trim(dir_run) // '/pbs_adj.csh .'
cif      call execute_command_line(f_command, wait=.true.)
      
      f_command = 'mv data ' // trim(dir_run) // '/data_adj'
      call execute_command_line(f_command, wait=.true.)
      
      f_command = 'mv data.ecco ' // trim(dir_run) // '/data.ecco_adj'
      call execute_command_line(f_command, wait=.true.)
      
      f_command = 'mv adj.info ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

      f_command = 'cp -p objf_*_mask* ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

cifc Wrapup 
cif      write(6,"(/,a)") '*********************************'
cif      f_command = 'do_adj.csh'
cif      write(6,"(4x,a)") 'Run "' // trim(f_command) //
cif     $     '" to compute adjoint gradients.'
cif      write(6,"(a,/)") '*********************************'

      stop
      end
