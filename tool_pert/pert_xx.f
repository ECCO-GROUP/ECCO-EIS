      program pert_xx
c -----------------------------------------------------
c Program for Perturbation Tool (V4r4)
c 
c Perturb (modify) V4r4 control specified by pert_xx.nml created by
c pert_nml.f. 
c
c 28 June 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
c Perturbation (perturbation variable, location, time, amplitude)
      integer pert_v, pert_i, pert_j, pert_t
      real*4 pert_a
      namelist /PERT_SPEC/ pert_v, pert_i, pert_j, pert_t, pert_a
c 
      character*130 file_in
      integer rc
      logical file_exists
      character*12 f_xx(8) 
      character*256 f_command 
      character*256 f_inputdir
     
      integer nx, ny
      parameter (nx=90, ny=1170)
      real*4 xx_2d(nx,ny)

c --------------
c xx variable name
      f_xx(1) = 'empmr'
      f_xx(2) = 'pload'   
      f_xx(3) = 'qnet'    
      f_xx(4) = 'qsw'     
      f_xx(5) = 'saltflux'
      f_xx(6) = 'spflx'   
      f_xx(7) = 'tauu'    
      f_xx(8) = 'tauv'    

c --------------
      call getarg(1,f_inputdir)
      write(6,*) 'inputdir read : ',trim(f_inputdir)

c --------------
c Read in Perturbation specification from namelist file

      file_in = 'pert_xx.nml'

      inquire (file=trim(file_in), EXIST=file_exists)
      if (.not. file_exists) then
         write (6,*) ' **** Error: namelist input file = ',trim(file_in) 
         write (6,*) '**** does not exist'
         stop
      endif

      open (50, file=file_in, status='old', action='read')
      read(50, nml=PERT_SPEC) 
      close (50)

      write(6,*) 'pert_v ',pert_v
      write(6,*) 'pert_i ',pert_i
      write(6,*) 'pert_j ',pert_j
      write(6,*) 'pert_t ',pert_t
      write(6,*) 'pert_a ',pert_a

      write(6,*) '... perturbing ',trim(f_xx(pert_v))

c --------------
c Create perturbed xx files 

c Replace link with actual for file to be perturbed 
      f_command = 'rm -f xx_' // trim(f_xx(pert_v))
     $     // '.0000000129.data'
      call execute_command_line(f_command, wait=.true.)

      f_command = 'cp ' // trim(f_inputdir) //
     $     '/other/flux-forced/xx/xx_'
     $      // trim(f_xx(pert_v)) // '.0000000129.data .'
      call execute_command_line(f_command, wait=.true.)

c Perturb xx file 
      file_in = 'xx_' // trim(f_xx(pert_v))
     $     // '.0000000129.data'
      open (50, file=file_in, action='readwrite', access='direct',
     $     recl=nx*ny*4, form='unformatted')
      read (50,rec=pert_t) xx_2d

      xx_2d(pert_i,pert_j) = xx_2d(pert_i,pert_j) +
     $     pert_a
      
      write (50,rec=pert_t) xx_2d

      close (50)

      stop
      end
