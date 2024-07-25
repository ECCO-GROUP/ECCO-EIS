      program fgrd
c -----------------------------------------------------
c     Program for Forward Gradient Tool (V4r4)
c
c Obtain gradient by computing state perturbation time-series, i.e.,
c difference of model state with and without control perturbation,
c divided by amplitude of the perturbation.
c
c 28 June 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c   05 July 2022: Added time to output. Skips instances with no
c                 corresponding reference output. 
c     -----------------------------------------------------

c Perturbation (perturbation variable, location, time, amplitude)
      integer pert_v, pert_i, pert_j, pert_t
      real*4 pert_a
      namelist /PERT_SPEC/ pert_v, pert_i, pert_j, pert_t, pert_a

c 
      character*130 f_in, f_out  ! file names 

      logical f_exists
      character*256 f_command 
      character*256 d_ref
      character*256 d_out

c --------------
c Reference run directory
      call getarg(1,d_ref)
      write(6,*) 'reference run directory : ',trim(d_ref)

c Output directory
      d_out = 'fgrd_result'
      f_command = 'mkdir ' // trim(d_out)
      call execute_command_line(f_command, wait=.true.)

c Save copy of perturbation namelist for reference 
      f_command = 'cp fgrd_pert.nml ' // trim(d_out)
      call execute_command_line(f_command, wait=.true.)

c --------------
c Read in Perturbation specification from namelist file

      f_in = 'fgrd_pert.nml'

      inquire (file=trim(f_in), EXIST=f_exists)
      if (.not. f_exists) then
         write (6,*) ' **** Error: namelist input file = ',trim(f_in) 
         write (6,*) '**** does not exist'
         stop
      endif

      open (50, file=f_in, status='old', action='read')
      read(50, nml=PERT_SPEC) 
      close (50)

      write(6,*) 'pert_v ',pert_v
      write(6,*) 'pert_i ',pert_i
      write(6,*) 'pert_j ',pert_j
      write(6,*) 'pert_t ',pert_t
      write(6,*) 'pert_a ',pert_a

c --------------
c Compute gradient

c SSH & OBP (monthly mean) 
      call pr2d_r8(trim(d_out),
     $     'state_2d_set1_mon', 2, 
     $     trim(d_ref), pert_a)

c SSH & OBP (daily mean) 
      call pr2d_r8(trim(d_out),
     $     'state_2d_set1_day', 2, 
     $     trim(d_ref), pert_a)

c T,S,U,V (monthly mean) 
      call pr3d(trim(d_out),
     $     'state_3d_set1_mon', 4, 
     $     trim(d_ref), pert_a)

      stop
      end
