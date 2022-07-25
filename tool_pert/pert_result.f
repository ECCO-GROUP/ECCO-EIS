      program pert_result 
c -----------------------------------------------------
c Program for Perturbation Tool (V4r4)
c Obtain state perturbation time-series, i.e., 
c difference of model state with and without control perturbation. 
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
      d_out = 'pert_result_output'
      f_command = 'mkdir ' // trim(d_out)
      call execute_command_line(f_command, wait=.true.)

c Save copy of perturbation namelist for reference 
      f_command = 'cp pert_xx.nml ' // trim(d_out)
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
c 
c ========================================================
c
      subroutine pr2d(d_out, f_in, nrec, d_ref, pert_a)
c Perturbed Result 2d
      character(len=*) :: d_out, f_in, d_ref
      real*4 pert_a
      integer  nrec 
c 
      logical f_exists
      integer nx, ny
      parameter (nx=90, ny=1170)
      real*4 dum2d_pert(nx,ny)
      real*4 dum2d_ref(nx,ny)
      character*256 f_file, f_ref, f_pert, f_out, f_meta
      character*256 f_command 
      integer irec 

c List input file 
      f_command = 'ls diags/' // f_in // '*.data' //
     $     '| xargs -n 1 basename > pert_result.dum_data'
      call execute_command_line(f_command, wait=.true.)

      f_command = 'ls diags/' // f_in // '*.meta' //
     $     '| xargs -n 1 basename > pert_result.dum_meta'
      call execute_command_line(f_command, wait=.true.)

      f_file = 'pert_result.dum_data'
      open(50, file=f_file, status='old', action='read')

      f_file = 'pert_result.dum_meta'
      open(51, file=f_file, status='old', action='read')

c Read input file one by one 
      do 
c read perturbed file 
         read(50,'(a)',END=999) f_file
         read(51,'(a)',END=999) f_meta

c read reference file 
         f_pert = 'diags/' // trim(f_file)
         f_ref = trim(d_ref) // '/diags/' // trim(f_file)
         f_out = trim(d_out) // '/' // trim(f_file)

         inquire (file=trim(f_ref), EXIST=f_exists)
         if (f_exists) then

            open(52, file=f_pert, access='direct',
     $           recl=nx*ny*4, form='unformatted')

            open(53, file=f_ref, access='direct',
     $           recl=nx*ny*4, form='unformatted')

            open(60, file=f_out, access='direct',
     $           recl=nx*ny*4, form='unformatted')

            do irec=1,nrec
               read(52,rec=irec) dum2d_pert

               read(53,rec=irec) dum2d_ref

               dum2d_pert = (dum2d_pert - dum2d_ref)/pert_a

               write(60,rec=irec) dum2d_pert
            enddo

            close(52)
            close(53)
            close(60)

c Copy meta file
            f_ref = trim(d_ref) // '/diags/' // trim(f_meta)
            f_command = 'cp ' // trim(f_ref) // ' ' // trim(d_out)
            call execute_command_line(f_command, wait=.true.)

         endif
      enddo

 999  continue
      close(50)
      close(51)

      return
      end
c 
c ========================================================
c
      subroutine pr2d_r8(d_out, f_in, nrec, d_ref, pert_a)
c Perturbed Result 2d
      character(len=*) :: d_out, f_in, d_ref
      real*4 pert_a
      integer  nrec 
c 
      logical f_exists
      integer nx, ny
      parameter (nx=90, ny=1170)
      real*8 dum2d_pert(nx,ny)
      real*8 dum2d_ref(nx,ny)
      real*4 dum2d(nx,ny)
      character*256 f_file, f_ref, f_pert, f_out, f_meta
      character*256 f_command 
      integer irec 

c List input file 
      f_command = 'ls diags/' // f_in // '*.data' //
     $     '| xargs -n 1 basename > pert_result.dum_data'
      call execute_command_line(f_command, wait=.true.)

      f_command = 'ls diags/' // f_in // '*.meta' //
     $     '| xargs -n 1 basename > pert_result.dum_meta'
      call execute_command_line(f_command, wait=.true.)

      f_file = 'pert_result.dum_data'
      open(50, file=f_file, status='old', action='read')

      f_file = 'pert_result.dum_meta'
      open(51, file=f_file, status='old', action='read')

c Read input file one by one 
      do 
c read perturbed file 
         read(50,'(a)',END=999) f_file
         read(51,'(a)',END=999) f_meta

c read reference file 
         f_pert = 'diags/' // trim(f_file)
         f_ref = trim(d_ref) // '/diags/' // trim(f_file)
         f_out = trim(d_out) // '/' // trim(f_file)

         inquire (file=trim(f_ref), EXIST=f_exists)
         if (f_exists) then

            open(52, file=f_pert, access='direct',
     $           recl=nx*ny*8, form='unformatted')

            open(53, file=f_ref, access='direct',
     $           recl=nx*ny*8, form='unformatted')

            open(60, file=f_out, access='direct',
     $           recl=nx*ny*4, form='unformatted')

            do irec=1,nrec
               read(52,rec=irec) dum2d_pert

               read(53,rec=irec) dum2d_ref

               dum2d_pert = (dum2d_pert - dum2d_ref)/pert_a
               dum2d = real(dum2d_pert)

               write(60,rec=irec) dum2d
            enddo

            close(52)
            close(53)
            close(60)

c Copy meta file
            f_ref = trim(d_ref) // '/diags/' // trim(f_meta)
            f_command = 'cp ' // trim(f_ref) // ' ' // trim(d_out)
            call execute_command_line(f_command, wait=.true.)
            f_command = 'sed -i "s|float64|float32|g" ' //
     $           trim(d_out) // '/' // trim(f_meta)
            call execute_command_line(f_command, wait=.true.)

         endif
      enddo

 999  continue
      close(50)
      close(51)

      return
      end
c 
c ========================================================
c
      subroutine pr3d(d_out, f_in, nrec, d_ref, pert_a)
c Perturbed Result 2d
      character(len=*) :: d_out, f_in, d_ref
      real*4 pert_a
      integer  nrec 
c 
      logical f_exists
      integer nx, ny, nr 
      parameter (nx=90, ny=1170, nr=50)
      real*4 dum3d_pert(nx,ny,nr)
      real*4 dum3d_ref(nx,ny,nr)
      character*256 f_file, f_ref, f_pert, f_out, f_meta
      character*256 f_command 
      integer irec 

c List input file 
      f_command = 'ls diags/' // f_in // '*.data' //
     $     '| xargs -n 1 basename > pert_result.dum_data'
      call execute_command_line(f_command, wait=.true.)

      f_command = 'ls diags/' // f_in // '*.meta' //
     $     '| xargs -n 1 basename > pert_result.dum_meta'
      call execute_command_line(f_command, wait=.true.)

      f_file = 'pert_result.dum_data'
      open(50, file=f_file, status='old', action='read')

      f_file = 'pert_result.dum_meta'
      open(51, file=f_file, status='old', action='read')

c Read input file one by one 
      do 
c read perturbed file 
         read(50,'(a)',END=999) f_file
         read(51,'(a)',END=999) f_meta

c read reference file 
         f_pert = 'diags/' // trim(f_file)
         f_ref = trim(d_ref) // '/diags/' // trim(f_file)
         f_out = trim(d_out) // '/' // trim(f_file)

         inquire (file=trim(f_ref), EXIST=f_exists)
         if (f_exists) then

            open(52, file=f_pert, access='direct',
     $           recl=nx*ny*nr*4, form='unformatted')

            open(53, file=f_ref, access='direct',
     $           recl=nx*ny*nr*4, form='unformatted')

            open(60, file=f_out, access='direct',
     $           recl=nx*ny*nr*4, form='unformatted')

            do irec=1,nrec
               read(52,rec=irec) dum3d_pert

               read(53,rec=irec) dum3d_ref

               dum3d_pert = (dum3d_pert - dum3d_ref)/pert_a

               write(60,rec=irec) dum3d_pert
            enddo

            close(52)
            close(53)
            close(60)

c Copy meta file
            f_ref = trim(d_ref) // '/diags/' // trim(f_meta)
            f_command = 'cp ' // trim(f_ref) // ' ' // trim(d_out)
            call execute_command_line(f_command, wait=.true.)

         endif
      enddo

 999  continue
      close(50)
      close(51)

      return
      end
