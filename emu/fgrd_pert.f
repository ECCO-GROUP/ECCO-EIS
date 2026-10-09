      program fgrd_pert
c -----------------------------------------------------
c Program for Forward Gradient Tool (V4r4)
c 
c Perturb (modify) V4r4 control specified by fgrd_pert.nml created by
c fgrd_spec.f. 
c
c 28 June 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
c Perturbation (perturbation variable, location, time, amplitude)
      integer pert_v, pert_i, pert_j, pert_k, pert_t
      real*4 pert_a
      namelist /PERT_SPEC/ pert_v, pert_i, pert_j, pert_k,
     $     pert_t, pert_a
c 
      character*130 file_in
      integer rc
      logical file_exists
      
      integer nctrl
      parameter (nctrl=16)
      character*12 f_xx(nctrl) 
      character*256 f_command 
      character*256 f_inputdir
     
      integer nx, ny
      parameter (nx=90, ny=1170, nr=50)
      real*4 xx_2d(nx,ny)
      real*4 xx_3d(nx,ny,nr)

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
      f_xx(9) = 'etan'
      f_xx(10) = 'theta'
      f_xx(11) = 'salt'
      f_xx(12) = 'uvel'
      f_xx(13) = 'vvel'
      f_xx(14) = 'diffkr'
      f_xx(15) = 'kapgm'  
      f_xx(16) = 'kapredi'   

c --------------
      call getarg(1,f_inputdir)
      write(6,*) 'inputdir read : ',trim(f_inputdir)

c --------------
c Read in Perturbation specification from namelist file

      file_in = 'fgrd_pert.nml'

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
      write(6,*) 'pert_k ',pert_k
      write(6,*) 'pert_t ',pert_t
      write(6,*) 'pert_a ',pert_a

      write(6,*) '... perturbing ',trim(f_xx(pert_v))

c --------------
c Create perturbed xx files 

c Replace link with actual file to be perturbed 
      f_command = 'cp -L -f xx_' // trim(f_xx(pert_v))
     $     // '.0000000129.data xx_'// trim(f_xx(pert_v))
     $     // '.0000000129.data_tmp'
      call execute_command_line(f_command, wait=.true.)

      f_command = 'mv -f  xx_' // trim(f_xx(pert_v))
     $     // '.0000000129.data_tmp xx_'// trim(f_xx(pert_v))
     $     // '.0000000129.data'
      call execute_command_line(f_command, wait=.true.)

c Perturb xx file 
      if (pert_v .le. 9) then 
         file_in = 'xx_' // trim(f_xx(pert_v))
     $        // '.0000000129.data'
         open (50, file=file_in, action='readwrite', access='direct',
     $        recl=nx*ny*4, form='unformatted')
         read (50,rec=pert_t) xx_2d

         xx_2d(pert_i,pert_j) = xx_2d(pert_i,pert_j) +
     $        pert_a
      
         write (50,rec=pert_t) xx_2d

         close (50)
      else
         file_in = 'xx_' // trim(f_xx(pert_v))
     $        // '.0000000129.data'
         open (50, file=file_in, action='readwrite', access='direct',
     $        recl=nx*ny*nr*4, form='unformatted')
         read (50,rec=pert_t) xx_3d

         xx_3d(pert_i,pert_j,pert_k) = xx_3d(pert_i,pert_j,pert_k) +
     $        pert_a
      
         write (50,rec=pert_t) xx_3d

         close (50)
      endif

      stop
      end
