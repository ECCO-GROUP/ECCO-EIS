      program pert_result 
c Obtain state perturbation time-series, i.e., 
c difference of model state with and without control perturbation. 

c Perturbation (perturbation variable, location, time, amplitude)
      integer pert_v, pert_i, pert_j, pert_t
      real*4 pert_a
      namelist /PERT_SPEC/ pert_v, pert_i, pert_j, pert_t, pert_a

c 
      character*130 f_in, f_out  ! file names 

      logical f_exists
      character*256 f_command 
      character*256 f_ref
      character*256 f_dir

c --------------
c Reference run directory
      call getarg(1,f_ref)
      write(6,*) 'reference run directory : ',trim(f_ref)

c Output directory
      f_dir = 'pert_result_output'
      f_command = 'mkdir ' // trim(f_dir)
      call execute_command_line(f_command, wait=.true.)

c Save copy of perturbation namelist for reference 
      f_command = 'cp pert_xx.nml ' // trim(f_dir)
      call execute_command_line(f_command, wait=.true.)

c --------------
c Read in Perturbation specification from namelist file

      f_in = 'pert_xx.nml'

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
c Compute perturbed state

c Sea Level (monthly mean) 
      call pr2d_r8(trim(f_dir) // '/pert_result.ssh_mon',
     $     'diags/state_2d_ssh_mon_mean.*.data', 3, 
     $     f_ref, pert_a)

c OBP (monthly mean) 
      call pr2d_r8(trim(f_dir) // '/pert_result.obp_mon',
     $     'diags/state_2d_obp_mon_mean.*.data', 2, 
     $     f_ref, pert_a)

c Sea Level (daily mean) 
      call pr2d_r8(trim(f_dir) // '/pert_result.ssh_day',
     $     'diags/state_2d_ssh_day_mean.*.data', 3, 
     $     f_ref, pert_a)

c OBP (daily mean) 
      call pr2d_r8(trim(f_dir) // '/pert_result.obp_day',
     $     'diags/state_2d_obp_day_mean.*.data', 2, 
     $     f_ref, pert_a)

c T (monthly mean) 
      call pr3d(trim(f_dir) // '/pert_result.theta_mon',
     $     'diags/state_3d_set1.*.data', 1, 
     $     f_ref, pert_a)

c S (monthly mean) 
      call pr3d(trim(f_dir) // '/pert_result.salt_mon',
     $     'diags/state_3d_set1.*.data', 2, 
     $     f_ref, pert_a)

c UVELMASS (monthly mean) 
      call pr3d(trim(f_dir) // '/pert_result.uvelmass_mon',
     $     'diags/trsp_3d_set1.*.data', 1, 
     $     f_ref, pert_a)

c VVELMASS (monthly mean) 
      call pr3d(trim(f_dir) // '/pert_result.vvelmass_mon',
     $     'diags/trsp_3d_set1.*.data', 2, 
     $     f_ref, pert_a)

      stop
      end
c 
c ========================================================
c
      subroutine pr2d(f_out, f_in, rdrec, f_ref, pert_a)
c Perturbed Result 2d
      character(len=*) :: f_out, f_in, f_ref
      real*4 pert_a
      integer  rdrec 
c 
      integer nx, ny
      parameter (nx=90, ny=1170)
      real*4 dum2d_pert(nx,ny)
      real*4 dum2d_ref(nx,ny)
      character*256 f_file
      character*256 f_command 
      integer irec 

c Open output file 
      open(60, file=f_out, access='direct',
     $     recl=nx*ny*4, form='unformatted')

c List input file 
      f_command = 'ls -al ' // 
     $     f_in //
     $     '| awk ''{ print $9 }'' > pert_result.dum'
      call execute_command_line(f_command, wait=.true.)

      f_file = 'pert_result.dum'
      open(50, file=f_file, status='old', action='read')
      irec = 0

c Read input file one by one 
      do 
c read perturbed file 
         read(50,'(a)',END=999) f_file

         open(51, file=f_file, access='direct',
     $     recl=nx*ny*4, form='unformatted')
         read(51,rec=rdrec) dum2d_pert
         close(51)

c read reference file 
         f_file = trim(f_ref) // '/' // trim(f_file)
         open(51, file=f_file, access='direct',
     $     recl=nx*ny*4, form='unformatted')
         read(51,rec=rdrec) dum2d_ref
         close(51)

         irec = irec + 1
         dum2d_pert = (dum2d_pert - dum2d_ref)/pert_a
         write(60,rec=irec) dum2d_pert

      enddo

 999  close (50)
      close (60)

      return
      end
c 
c ========================================================
c
      subroutine pr2d_r8(f_out, f_in, rdrec, f_ref, pert_a)
c Perturbed Result 2d
      character(len=*) :: f_out, f_in, f_ref
      real*4 pert_a
      integer  rdrec 
c 
      integer nx, ny
      parameter (nx=90, ny=1170)
      real*8 dum2d_pert(nx,ny)
      real*8 dum2d_ref(nx,ny)
      real*4 dum2d(nx,ny)
      character*256 f_file
      character*256 f_command 
      integer irec 

c Open output file 
      open(60, file=f_out, access='direct',
     $     recl=nx*ny*4, form='unformatted')

c List input file 
      f_command = 'ls -al ' // 
     $     f_in //
     $     '| awk ''{ print $9 }'' > pert_result.dum'
      call execute_command_line(f_command, wait=.true.)

      f_file = 'pert_result.dum'
      open(50, file=f_file, status='old', action='read')
      irec = 0

c Read input file one by one 
      do 
c read perturbed file 
         read(50,'(a)',END=999) f_file

         open(51, file=f_file, access='direct',
     $     recl=nx*ny*8, form='unformatted')
         read(51,rec=rdrec) dum2d_pert
         close(51)

c read reference file 
         f_file = trim(f_ref) // '/' // trim(f_file)
         open(51, file=f_file, access='direct',
     $     recl=nx*ny*8, form='unformatted')
         read(51,rec=rdrec) dum2d_ref
         close(51)

         irec = irec + 1
         dum2d_pert = (dum2d_pert - dum2d_ref)/pert_a
         dum2d = real(dum2d_pert)
         write(60,rec=irec) dum2d

      enddo

 999  close (50)
      close (60)

      return
      end
c 
c ========================================================
c
      subroutine pr3d(f_out, f_in, rdrec, f_ref, pert_a)
c Perturbed Result 2d
      character(len=*) :: f_out, f_in, f_ref
      real*4 pert_a
      integer  rdrec 
c 
      integer nx, ny
      parameter (nx=90, ny=1170, nr=50)
      real*4 dum3d_pert(nx,ny,nr)
      real*4 dum3d_ref(nx,ny,nr)
      character*256 f_file
      character*256 f_command 
      integer irec 

c Open output file 
      open(60, file=f_out, access='direct',
     $     recl=nx*ny*nr*4, form='unformatted')

c List input file 
      f_command = 'ls -al ' // 
     $     f_in //
     $     '| awk ''{ print $9 }'' > pert_result.dum'
      call execute_command_line(f_command, wait=.true.)

      f_file = 'pert_result.dum'
      open(50, file=f_file, status='old', action='read')
      irec = 0

c Read input file one by one 
      do 
c read perturbed file 
         read(50,'(a)',END=999) f_file

         open(51, file=f_file, access='direct',
     $     recl=nx*ny*nr*4, form='unformatted')
         read(51,rec=rdrec) dum3d_pert
         close(51)

c read reference file 
         f_file = trim(f_ref) // '/' // trim(f_file)
         open(51, file=f_file, access='direct',
     $     recl=nx*ny*nr*4, form='unformatted')
         read(51,rec=rdrec) dum3d_ref
         close(51)

         irec = irec + 1
         dum3d_pert = (dum3d_pert - dum3d_ref)/pert_a
         write(60,rec=irec) dum3d_pert

      enddo

 999  close (50)
      close (60)

      return
      end
