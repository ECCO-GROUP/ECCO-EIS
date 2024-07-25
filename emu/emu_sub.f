c Subroutines for ECCO Modeling Utilities (EMU).
c
c 28 June 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c   StripSpaces: Remove spaces from string.
c   ijloc: Itentify native grid location (i,j) from lat/lon.
c 
c ============================================================
c 
      subroutine StripSpaces(string)
c Strip spaces from string 

      character(len=*) :: string
      integer :: stringLen 
      integer :: last, actual

      stringLen = len (string)
      last = 1
      actual = 1

      do while (actual < stringLen)
         if (string(last:last) == ' ') then
            actual = actual + 1
            string(last:last) = string(actual:actual)
            string(actual:actual) = ' '
         else
            last = last + 1
            if (actual < last) actual = last
         endif
      end do

      end subroutine
c
c ============================================================
c 
      subroutine ijloc(pert_x,pert_y,pert_i,pert_j,xc,yc,nx,ny)
c Locate closest model grid point (i,j) to given lon/lat (x,y) 

      integer :: pert_i, pert_j, nx, ny
      real*4  :: pert_x, pert_y
      real*4  :: xc(nx,ny), yc(nx,ny)
      real*4  :: dumdist, target, d2r
      integer :: i, j

c Reference (x,y) to -180 to 180 East and -90 to 90 North
c that (xc,yc) is defined 
      pert_x = modulo(pert_x,360.)
      if (pert_x .gt. 180.) pert_x = pert_x - 360.
      pert_y = modulo(pert_y,360.)
      if (pert_y .gt. 180.) pert_y = pert_y - 360.
      if (pert_y .gt. 90.)  pert_y = 180. - pert_y 
      if (pert_y .lt. -90.) pert_y = -180. - pert_y

c Find (i,j) pair within 10-degrees of (x,y)
      pert_i = -9
      pert_j = -9
      target = 9e9
      d2r = 3.1415926/180.

      do j=1,ny
         do i=1,nx
            if (abs(yc(i,j)-pert_y) .lt. 10.) then 
               dumdist = sin(pert_y*d2r)*sin(yc(i,j)*d2r) +
     $    cos(pert_y*d2r)*cos(yc(i,j)*d2r)*cos((xc(i,j)-pert_x)*d2r)
               dumdist = acos(dumdist)
               if (dumdist .lt. target) then
                  pert_i = i
                  pert_j = j
                  target = dumdist
               endif
            endif
         enddo
      enddo
      end subroutine
c 
c ============================================================
c 
      subroutine chk_mask2d(fmask_in,nx,ny,dum2d,ipar)
c Check mask file is native 2d

      character(len=*) :: fmask_in
      integer :: nx, ny, ipar
      real*4 :: dum2d(nx,ny)
      integer :: ij(2)
      real*8 sum8

      character*256 :: f_command
      logical :: f_exist
      integer :: file_size
      integer(kind=8) :: f_target


      INQUIRE(FILE=fmask_in, SIZE=file_size, EXIST=f_exist)

      if (.not. f_exist) then
         write(6,*) 'File does not exist ... ',fmask_in
         write(6,*) '... aborting'
         stop
      endif
      
      f_target = int(nx,kind=8)*int(ny,kind=8)*4
      if (file_size .ne.  f_target) then
         write(6,*) 'File size ',f_target
         write(6,*) 'does not match native grid'
         write(6,*) 'Is input mask on native 2D grid?'
         write(6,*) '... aborting'
         stop
      endif

      open(60,file=fmask_in,form='unformatted',access='stream')
      read(60) dum2d
      close(60)

      if (ipar.eq.1) then ! output from only master process
         ij = maxloc(abs(dum2d))
         write(6,1000) trim(fmask_in)
 1000    format(/,3x,'Mask file : ',a)
         write(6,1001) dum2d(ij(1),ij(2))
 1001    format(3x,'Masks maximum absolute value = ',1pe12.4)
         write(6,1002) ij
 1002    format(3x,6x,'at (i,j) =',i5,1x,i5)

         sum8 = 0.d0
         do i=1,nx
            do j=1,ny
               sum8 = sum8 + dble(dum2d(i,j))
            enddo
         enddo
         write(6,1003) sum8
 1003    format(3x,'Masks sum = ',1pe12.4)
      endif

      return
      end
c 
c ============================================================
c 
      subroutine chk_mask3d(fmask_in,nx,ny,nr,dum3d,ipar)
c Check mask file is native 3d

      character(len=*) :: fmask_in
      integer :: nx, ny, nr, ipar
      real*4 :: dum3d(nx,ny,nr)
      integer :: ijk(3)
      real*8 sum8

      character*256 :: f_command
      logical :: f_exist
      integer :: file_size
      integer(kind=8) :: f_target


      INQUIRE(FILE=fmask_in, SIZE=file_size, EXIST=f_exist)

      if (.not. f_exist) then
         write(6,*) 'File does not exist ... ',fmask_in
         write(6,*) '... aborting'
         stop
      endif
      
      f_target = int(nx,kind=8)*int(ny,kind=8)*int(nr,kind=8)*4
      if (file_size .ne.  f_target) then
         write(6,*) 'File size ',file_size
         write(6,*) 'does not match native grid'
         write(6,*) 'Is input mask on native 3D grid?'
         write(6,*) '... aborting'
         stop
      endif

      open(60,file=fmask_in,form='unformatted',access='stream')
      read(60) dum3d
      close(60)

      if (ipar.eq.1) then ! output from only master process
         ijk = maxloc(abs(dum3d))
         write(6,1000) trim(fmask_in)
 1000    format(/,3x,'Mask file : ',a)
         write(6,1001) dum3d(ijk(1),ijk(2),ijk(3))
 1001    format(3x,'Masks maximum absolute value = ',1pe12.4)
         write(6,1002) ijk
 1002    format(3x,6x,'at (i,j,k) =',i5,1x,i5,1x,i5)

         sum8 = 0.d0
         do i=1,nx
            do j=1,ny
               do k=1,nr
                  sum8 = sum8 + dble(dum3d(i,j,k))
               enddo
            enddo
         enddo
         write(6,1003) sum8
 1003    format(3x,'Masks sum = ',1pe12.4)
      endif

      return
      end
c 
c ============================================================
c 
      subroutine samp_2d_r8(statedir,ffile,
     $     irec,pert_i,pert_j,objf,nrec,mobjf)
c Sample native 2d real*8 file 

      character(len=*) :: statedir, ffile
      integer :: irec, pert_i, pert_j
      real*4 :: objf(*),mobjf
      integer :: nrec

c 
      integer nx, ny
      parameter (nx=90, ny=1170)
      real*8 dum2d(nx,ny), dref
      character*256 f_file
      character*256 f_command 


c List input file 
      f_file = trim(statedir) // '/' // trim(ffile) 
      f_command = 'ls ' // trim(f_file) // '*.data' //
     $     ' > samp.dum_data'
      call execute_command_line(f_command, wait=.true.)

      f_file = 'samp.dum_data'
      open(50, file=f_file, status='old', action='read')

      nrec = 0

c Read first file as reference 
         read(50,'(a)',END=999) f_file

         open(52, file=f_file, access='direct',
     $           recl=nx*ny*8, form='unformatted')
         read(52,rec=irec) dum2d
         nrec = nrec + 1
         dref = dum2d(pert_i,pert_j)
         objf(nrec) = 0.
         close(52)
c Read rest of the files 
      do 
c read state of particular instant 
         read(50,'(a)',END=999) f_file

         open(52, file=f_file, access='direct',
     $           recl=nx*ny*8, form='unformatted')
         read(52,rec=irec) dum2d
         nrec = nrec + 1
         objf(nrec) = dum2d(pert_i,pert_j) - dref 
         close(52)

      enddo

 999  continue
      close(50)

c Reset reference to time-mean 
      mobjf = sum(objf(1:nrec))/float(nrec) 
      objf(1:nrec) = objf(1:nrec) - mobjf
      mobjf = dref + mobjf 

      return
      end
c 
c ============================================================
c 
      subroutine samp_3d(statedir,ffile,irec,
     $     pert_i,pert_j,pert_k,objf,nrec,mobjf)
c Sample native 3d file 

      character(len=*) :: statedir, ffile 
      integer :: irec, pert_i, pert_j, pert_k
      real*4 :: objf(*), mobjf
      integer :: nrec

c 
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 dum3d(nx,ny,nr), dref
      character*256 f_file
      character*256 f_command 


c List input file 
      f_file = trim(statedir) // '/' // trim(ffile) 
      f_command = 'ls ' // trim(f_file) // '*.data' //
     $     ' > samp.dum_data'
      call execute_command_line(f_command, wait=.true.)

      f_file = 'samp.dum_data'
      open(50, file=f_file, status='old', action='read')

      nrec = 0

c Read first file as reference 
         read(50,'(a)',END=999) f_file

         open(52, file=f_file, access='direct',
     $           recl=nx*ny*nr*4, form='unformatted')
         read(52,rec=irec) dum3d
         nrec = nrec + 1
         dref = dum3d(pert_i,pert_j,pert_k)
         objf(nrec) = 0.
         close(52)
c Read rest of the files 
      do 
c read state of particular instant 
         read(50,'(a)',END=999) f_file

         open(52, file=f_file, access='direct',
     $           recl=nx*ny*nr*4, form='unformatted')
         read(52,rec=irec) dum3d
         nrec = nrec + 1
         objf(nrec) = dum3d(pert_i,pert_j,pert_k) - dref 
         close(52)

      enddo

 999  continue
      close(50)

c Reset reference to time-mean 
      mobjf = sum(objf(1:nrec))/float(nrec) 
      objf(1:nrec) = objf(1:nrec) - mobjf
      mobjf = dref + mobjf 

      return
      end
c 
c ============================================================
c 
      subroutine samp_2d_r8_wgtd(statedir,ffile,irec,
     $     wgt2d,objf,nrec,mobjf,istep)
c Sample native 2d real*8 file 

      integer nx, ny
      parameter (nx=90, ny=1170)

      character(len=*) :: statedir, ffile 
      integer :: irec
      real*4 :: wgt2d(nx,ny)
      real*4 :: objf(*), mobjf
      integer :: nrec
      integer :: istep(*)

c 
      real*8 dum2d(nx,ny), dref(nx,ny)
      character*256 f_file
      character*256 f_command 
      integer ip1, ip2


c List input file 
      f_file = trim(statedir) // '/' // trim(ffile) 
      f_command = 'ls ' // trim(f_file) // '*.data' //
     $     ' > samp.dum_data'
      call execute_command_line(f_command, wait=.true.)

      f_file = 'samp.dum_data'
      open(50, file=f_file, status='old', action='read')

      nrec = 0

c Read first file as reference 
         read(50,'(a)',END=999) f_file

         open(52, file=f_file, access='direct',
     $           recl=nx*ny*8, form='unformatted')
         read(52,rec=irec) dum2d
         nrec = nrec + 1
         dref = dum2d
         objf(nrec) = 0.
         close(52)

c Read corresponding time-step
         ip1 = index(f_file,trim(ffile)) + len(trim(ffile))
         ip2 = index(f_file,'.data')
         f_command = trim(f_file(ip1+1:ip2-1))
         read(f_command,*) istep(nrec)

c Read rest of the files 
      do 
c read state of particular instant 
         read(50,'(a)',END=999) f_file

         open(52, file=f_file, access='direct',
     $           recl=nx*ny*8, form='unformatted')
         read(52,rec=irec) dum2d
         nrec = nrec + 1
         objf(nrec) = sum( wgt2d * (dum2d-dref) ) 
         close(52)

c Read corresponding time-step
         f_command = trim(f_file(ip1+1:ip2-1))
         read(f_command,*) istep(nrec)

      enddo

 999  continue
      close(50)

c Reset reference to time-mean 
      mobjf = sum(objf(1:nrec))/float(nrec) 
      objf(1:nrec) = objf(1:nrec) - mobjf
      mobjf = sum(wgt2d * dref) + mobjf 

      return
      end
c 
c ============================================================
c 
      subroutine samp_3d_wgtd(statedir,ffile,irec,
     $     wgt3d,objf,nrec,mobjf,istep)
c Sample native 3d file 

      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c Strip spaces from string 
      character(len=*) :: statedir, ffile 
      integer :: irec
      real*4 :: wgt3d(nx,ny,nr)
      real*4 :: objf(*), mobjf
      integer :: nrec
      integer :: istep(*)

c 
      real*4 dum3d(nx,ny,nr), dref(nx,ny,nr)
      character*256 f_file
      character*256 f_command 
      integer ip1, ip2


c List input file 
      f_file = trim(statedir) // '/' // trim(ffile) 
      f_command = 'ls ' // trim(f_file) // '*.data' //
     $     ' > samp.dum_data'
      call execute_command_line(f_command, wait=.true.)

      f_file = 'samp.dum_data'
      open(50, file=f_file, status='old', action='read')

      nrec = 0

c Read first file as reference 
         read(50,'(a)',END=999) f_file

         open(52, file=f_file, access='direct',
     $           recl=nx*ny*nr*4, form='unformatted')
         read(52,rec=irec) dum3d
         nrec = nrec + 1
         dref = dum3d
         objf(nrec) = 0.
         close(52)

c Read corresponding time-step
         ip1 = index(f_file,trim(ffile)) + len(trim(ffile))
         ip2 = index(f_file,'.data')
         f_command = trim(f_file(ip1+1:ip2-1))
         read(f_command,*) istep(nrec)

c Read rest of the files 
      do 
c read state of particular instant 
         read(50,'(a)',END=999) f_file

         open(52, file=f_file, access='direct',
     $           recl=nx*ny*nr*4, form='unformatted')
         read(52,rec=irec) dum3d
         nrec = nrec + 1
         objf(nrec) = sum( wgt3d * (dum3d-dref) ) 
         close(52)

c Read corresponding time-step
         f_command = trim(f_file(ip1+1:ip2-1))
         read(f_command,*) istep(nrec)

      enddo

 999  continue
      close(50)

c Reset reference to time-mean 
      mobjf = sum(objf(1:nrec))/float(nrec) 
      objf(1:nrec) = objf(1:nrec) - mobjf
      mobjf = sum(wgt3d * dref) + mobjf 

      return
      end
c 
c ============================================================
c 
      subroutine emu_getcwd(string)
c Read current working directory from file emu.fcwd

      character(len=*) :: string

      open(52, file='emu.fcwd')
      read(52,'(a)') string 
      close(52)

      end subroutine
c 
c ============================================================
c 
      subroutine grid_info
      external StripSpaces
c files
      character*256 f_inputdir   
      common /tool/f_inputdir
      character*256 file_in, file_out, file_dum  ! file names 
      logical f_exist

      character*256 f_setup   ! directory where tool files are 

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c model arrays
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr), hfacc(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, kmt, dxg, dyg, dvol3d, rac

c --------------
c Read model grid

cc Directory where tool files exist
c      open (50, file='tool_setup_dir')
c      read (50,'(a)') f_setup
c      close (50)

c
c      file_in = trim(f_setup) // '/emu/emu_input/XC.data'
      file_in = trim(f_inputdir) // '/emu_ref/XC.data'
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

c      file_in = trim(f_setup) // '/emu/emu_input/YC.data'
      file_in = trim(f_inputdir) // '/emu_ref/YC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) yc
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/RC.data'
      file_in = trim(f_inputdir) // '/emu_ref/RC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) rc
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/Depth.data'
      file_in = trim(f_inputdir) // '/emu_ref/Depth.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) bathy
      close (50)
      
c      file_in = trim(f_setup) // '/emu/emu_input/RF.data'
      file_in = trim(f_inputdir) // '/emu_ref/RF.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) rf   ! depth of layer boundary
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/hFacC.data'
      file_in = trim(f_inputdir) // '/emu_ref/hFacC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) hfacc
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/RAC.data'
      file_in = trim(f_inputdir) // '/emu_ref/RAC.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) rac 
      close (50)

c      file_in = trim(f_setup) // '/emu/emu_input/DRF.data'
      file_in = trim(f_inputdir) // '/emu_ref/DRF.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) drf
      close (50)

      file_in = trim(f_inputdir) // '/emu_ref/DXG.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) dxg
      close (50)

      file_in = trim(f_inputdir) // '/emu_ref/DYG.data'
      open (50, file=file_in, action='read', access='stream')
      read (50) dyg
      close (50)

c Derived quantities
      kmt(:,:) = 0
      do i=1,nx
         do j=1,ny
            do k=1,nr
               if (hfacc(i,j,k).ne.0.) kmt(i,j)=k
            enddo
         enddo
      enddo

c Inverse depth
      ibathy(:,:) = 0.
      do i=1,nx
         do j=1,ny
            if (bathy(i,j).ne.0.) ibathy(i,j)=1./bathy(i,j)
         enddo
      enddo

c Volume
      dvol3d(:,:,:) = 0.
      do k=1,nr
         dvol3d(:,:,k) = rac(:,:)*hfacc(:,:,k)*drf(k)
      enddo

      return
      end subroutine grid_info
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
     $     '| xargs -n 1 basename > pr2d.dum_data'
      call execute_command_line(f_command, wait=.true.)

      f_command = 'ls diags/' // f_in // '*.meta' //
     $     '| xargs -n 1 basename > pr2d.dum_meta'
      call execute_command_line(f_command, wait=.true.)

      f_file = 'pr2d.dum_data'
      open(50, file=f_file, status='old', action='read')

      f_file = 'pr2d.dum_meta'
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
      end subroutine pr2d 
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
     $     '| xargs -n 1 basename > pr2d_r8.dum_data'
      call execute_command_line(f_command, wait=.true.)

      f_command = 'ls diags/' // f_in // '*.meta' //
     $     '| xargs -n 1 basename > pr2d_r8.dum_meta'
      call execute_command_line(f_command, wait=.true.)

      f_file = 'pr2d_r8.dum_data'
      open(50, file=f_file, status='old', action='read')

      f_file = 'pr2d_r8.dum_meta'
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
      end subroutine pr2d_r8
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
     $     '| xargs -n 1 basename > pr3d.dum_data'
      call execute_command_line(f_command, wait=.true.)

      f_command = 'ls diags/' // f_in // '*.meta' //
     $     '| xargs -n 1 basename > pr3d.dum_meta'
      call execute_command_line(f_command, wait=.true.)

      f_file = 'pr3d.dum_data'
      open(50, file=f_file, status='old', action='read')

      f_file = 'pr3d.dum_meta'
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
      end subroutine pr3d
c 
c ============================================================
c 
      subroutine file_search(file_in, file_out, nfiles) 
c Search for files matching file_in (can have wild card) and 
c output there names to file file_out and 
c return the number of files as nfiles.

c Argument 
      character*256 file_in, file_out
      integer nfiles

c
      character*256 f_command

c ------------------------------------
c      write(6,*) 'file_search (file_in): ',trim(file_in)
c      write(6,*) 'file_search (file_out): ',trim(file_out)

c ------------------------------------
c ID the files 
      call StripSpaces(file_in)
      f_command = 'ls ' // trim(file_in) // ' > ' // trim(file_out)
      call execute_command_line(f_command, wait=.true.)

c ------------------------------------
c Count number of files 
      open (53, file=trim(file_out), action='read')
      nfiles = 0
      do 
         read(53, '(A)', iostat=ios) f_command
         if (ios /= 0) exit     ! Exit the loop at the end of the file
         nfiles = nfiles + 1
      end do

      close(53)

      return
      end subroutine file_search 
c 
c ============================================================
c 
      subroutine mask01_3d(dum3d,x1,x2,y1,y2,z1,z2)
c -----------------------------------------------------
c Create 3d mask (1 within, 0 outside) based on user-specified limit on
c longitude, latitude, depth. 
c -----------------------------------------------------

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy
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
      end subroutine mask01_3d
c 
c ============================================================
c 
      subroutine mask01_2d(dum2d,x1,x2,y1,y2)
c -----------------------------------------------------
c Create 2d horizontal mask (1 within, 0 outside) based on
c user-specified limit on longitude and latitude.
c -----------------------------------------------------

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr), hfacc(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, kmt, dxg, dyg, dvol3d, rac
c 
      real*4 x1,x2,y1,y2

      real*4 dumx(nx,ny), dumy(nx,ny), dum 
      real*4 dum2d(nx,ny)
      real*4 vcheck

c ------
c Area must span at least one model grid pint 
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
      
c Find all (i,j) locations that is within volume 
      dumx(:,:) = 0.
      dumy(:,:) = 0.

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
         
      do i=1,nx
         do j=1,ny
            dum2d(i,j) = dumx(i,j)*dumy(i,j)*hfacc(i,j,1)
         enddo
      enddo

c ------
c Check Area
      vcheck = 0.
      do i=1,nx
         do j=1,ny
            vcheck = vcheck + dum2d(i,j)
         enddo
      enddo
      
      if (vcheck.eq.0.) then
         write(6,*) 'NG: Area is empty.'
         write(6,*) 'Area must span at least one grid point. '
         write(6,*) 'Re-Enter area specification ... '
      endif

      end do  ! end while 
c 
      return
      end subroutine mask01_2d
c 
c ============================================================
c 
      subroutine cr8_mask2d(fmask,x1,x2,y1,y2,iref)
c -----------------------------------------------------
c Subroutine to create a mask for area-weighting ocean points on the
c C-grid over a horizontal rectilinear region.
c     
c 19 June 2024, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr), hfacc(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, kmt, dxg, dyg, dvol3d, rac

c Mask 
      integer iref
      real*4 x1,x2,y1,y2
      real*4 adum
      real*4 dum2d(nx,ny), dum2d_a(nx,ny)

      character*256 floc_loc  ! location (mask) 
      character*256 fmask

c --------------
c Get 0/1 mask 
      call mask01_2d(dum2d,x1,x2,y1,y2)

c Convert to area mean          
      adum = 0.
      do i=1,nx
         do j=1,ny
            dum2d(i,j) = dum2d(i,j)*rac(i,j)
            adum = adum + dum2d(i,j)
         enddo
      enddo
      dum2d = dum2d/adum

c Option to define mask relative to global mean
      write(6,"(3x,a,a)")
     $     'Should area mean be relative to global mean ',
     $     '... (enter 1 for yes)?'
      read(5,*) iref

      if (iref .eq. 1) then
         write(6,"(3x,a,/)")
     $        '... 2d Mask will be relative to global mean'

         adum = 0.
         dum2d_a = 0.
         do i=1,nx
            do j=1,ny
               if (kmt(i,j).ne.0) then
                  dum2d_a(i,j) = rac(i,j)
                  adum = adum + rac(i,j)
               endif
            enddo
         enddo
         dum2d_a = dum2d_a / adum
         
         dum2d = dum2d - dum2d_a

c Save area for naming mask file 
         write(floc_loc,'(3(f6.1,"_"),f6.1,a4)')
     $        x1,x2,y1,y2,'-gmn'
      else
c Save area for naming mask file 
         write(floc_loc,'(3(f6.1,"_"),f6.1)')
     $        x1,x2,y1,y2
      endif 

      call StripSpaces(floc_loc)
      fmask = 'mask2d.' // trim(floc_loc)

      write(6,"(3x,a,/)")
     $     '2d Mask output: ',trim(fmask)

      open(60,file=trim(fmask),form='unformatted',access='stream')
      write(60) dum2d
      close(60)

      return
      end subroutine cr8_mask2d
c 
c ============================================================
c 
      subroutine cr8_mask3d(fmask,x1,x2,y1,y2,z1,z2,iref)
c -----------------------------------------------------
c Subroutine to create a mask for volume-weighting ocean points on the
c C-grid over a rectilinear volume. 
c     
c 19 June 2024, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr), hfacc(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, kmt, dxg, dyg, dvol3d, rac

c Mask 
      integer iref
      real*4 x1,x2,y1,y2,z1,z2
      real*4 adum
      real*4 dum3d(nx,ny,nr), dum3d_a(nx,ny,nr)

      character*256 floc_loc  ! location (mask) 
      character*256 fmask

c --------------
c Get 0/1 mask 
      call mask01_3d(dum3d,x1,x2,y1,y2,z1,z2)

c Convert to volume mean          
      adum = 0.
      do i=1,nx
         do j=1,ny
            do k=1,nr
               dum3d(i,j,k) = dum3d(i,j,k)*dvol3d(i,j,k)
               adum = adum + dum3d(i,j,k)
            enddo
         enddo
      enddo
      dum3d = dum3d/adum

c Option to define mask relative to global mean
      write(6,"(3x,a,a)")
     $     'Should volume mean be relative to global mean ',
     $     '... (enter 1 for yes)?'
      read(5,*) iref

      if (iref .eq. 1) then
         write(6,"(3x,a,/)")
     $        '... 3d Mask will be relative to global mean'

         adum = 0.
         dum3d_a = 0.
         do i=1,nx
            do j=1,ny
               do k=1,nr
                  dum3d_a(i,j,k) = dvol3d(i,j,k)
                  adum = adum + dvol3d(i,j,k)
               enddo
            enddo
         enddo
         dum3d_a = dum3d_a / adum

         dum3d = dum3d - dum3d_a

c Save area for naming mask file 
         write(floc_loc,'(5(f6.1,"_"),f6.1,a4)')
     $        x1,x2,y1,y2,z1,z2,'-gmn'
      else
c Save area for naming mask file 
         write(floc_loc,'(5(f6.1,"_"),f6.1)')
     $        x1,x2,y1,y2,z1,z2
      endif 

      call StripSpaces(floc_loc)
      fmask = 'mask3d.' // trim(floc_loc)

      write(6,"(3x,a,/)")
     $     '3d Mask output: ',trim(fmask)

      open(60,file=trim(fmask),form='unformatted',access='stream')
      write(60) dum3d
      close(60)

      return
      end subroutine cr8_mask3d
c 
c ============================================================
c 
      function rel2abs_fname(rel_fname) result(abs_fname)
c -----------------------------------------------------
c Subroutine to change a relative file name (rel_fname) to an absolute
c file name (abs_fname). Will also work even if rel_fname is already an
c absolute name.
c -----------------------------------------------------
c 
      character*256 rel_fname, abs_fname, cwd 
      integer ierror

c Get the current working directory
      call getcwd(cwd, ierror)
      if (ierror /= 0) then
         print *, 'Error getting current working directory (getcwd)'
         stop
      end if

c Combine cwd and relative path to get the absolute path
      if (rel_fname(1:1) == '/') then
        ! If the relative path is actually absolute
         abs_fname = trim(rel_fname)
      else
        ! Otherwise, concatenate the cwd with the relative path
         abs_fname = trim(cwd) // '/' // trim(rel_fname)
      end if

      return
      end function rel2abs_fname
