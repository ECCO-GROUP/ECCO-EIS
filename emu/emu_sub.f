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

      end subroutine StripSpaces
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
      end subroutine ijloc
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
         stop 1
      endif
      
      f_target = int(nx,kind=8)*int(ny,kind=8)*4
      if (file_size .ne.  f_target) then
         write(6,*) 'File size ',f_target
         write(6,*) 'does not match native grid'
         write(6,*) 'Is input mask on native 2D grid?'
         write(6,*) '... aborting'
         stop 1
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
      end subroutine chk_mask2d
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


      INQUIRE(FILE=trim(fmask_in), SIZE=file_size, EXIST=f_exist) 

      if (.not. f_exist) then
         write(6,*) 'File does not exist ... ',trim(fmask_in)
         write(6,*) '... aborting'
         stop 1
      endif
      
      f_target = int(nx,kind=8)*int(ny,kind=8)*int(nr,kind=8)*4
      if (file_size .ne.  f_target) then
         write(6,*) 'File size ',file_size
         write(6,*) 'does not match native grid'
         write(6,*) 'Is input mask on native 3D grid?'
         write(6,*) '... aborting'
         stop 1
      endif

      open(60,file=trim(fmask_in),form='unformatted',access='stream')
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
      end subroutine chk_mask3d
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
      end subroutine samp_2d_r8
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
      end subroutine samp_3d
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
      end subroutine samp_2d_r8_wgtd
c 
c ============================================================
c 
      subroutine samp_2d_r4_wgtd(statedir,ffile,irec,
     $     wgt2d,objf,nrec,mobjf,istep)
c Sample native 2d real*4 file 

      integer nx, ny
      parameter (nx=90, ny=1170)

      character(len=*) :: statedir, ffile 
      integer :: irec
      real*4 :: wgt2d(nx,ny)
      real*4 :: objf(*), mobjf
      integer :: nrec
      integer :: istep(*)

c 
      real*4 dum2d(nx,ny), dref(nx,ny)
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
     $           recl=nx*ny*4, form='unformatted')
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
     $           recl=nx*ny*4, form='unformatted')
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
      end subroutine samp_2d_r4_wgtd
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
      end subroutine samp_3d_wgtd
c 
c ============================================================
c 
      subroutine emu_getcwd(string)
c Read current working directory from file emu.fcwd

      character(len=*) :: string

      open(52, file='emu.fcwd')
      read(52,'(a)') string 
      close(52)

      end subroutine emu_getcwd
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

      write(6,'(/,a,2f7.1,2f6.1,2f7.1)')
     $     'Mask west/east/south/north/bottom/top boundary: ',
     $     x1,x2,y1,y2,z1,z2
      write(51,'(/,a,2f7.1,2f6.1,2f7.1)')
     $     'Mask west/east/south/north/bottom/top boundary: ',
     $     x1,x2,y1,y2,z1,z2

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

      real*4 rf(nr), drf(nr)
      real*4 hfacc(nx,ny,nr), hfacw(nx,ny,nr), hfacs(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, hfacw, hfacs,
     $     kmt, dxg, dyg, dvol3d, rac
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

      write(6,'(/,a,2f7.1,2f6.1)')
     $     'Mask west/east/south/north boundary: ',x1,x2,y1,y2
      write(51,'(/,a,2f7.1,2f6.1)')
     $     'Mask west/east/south/north boundary: ',x1,x2,y1,y2

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
      subroutine mask01_section(maskC,maskW,maskS,x1,x2,y1,y2)
c -----------------------------------------------------
c Create 2d horizontal mask for great circle between model grid 
c points closest to user-specified end points. 
c -----------------------------------------------------

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr)
      real*4 hfacc(nx,ny,nr), hfacw(nx,ny,nr), hfacs(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, hfacw, hfacs,
     $     kmt, dxg, dyg, dvol3d, rac
c 
      real*4 x1,x2,y1,y2
      real*4 pt1(2), pt2(2)
      real*4 maskC(nx,ny), maskW(nx,ny), maskS(nx,ny)

      real*4 dumx(nx,ny), dumy(nx,ny), dum 
      real*4 dum2d(nx,ny)
      real*4 vcheck

c ------
c Area must span at least one model grid pint 
      write(6,*)
     $     'Creating mask for great circle from point 1 to point 2.' 
      write(6,*)
     $     'Positive transport defined from right to left looking '//
     $     'from point 1 (former) to point 2 (latter).'
      write(6,*) '(Will select model grid points closest to '//
     $     'user-specified points.)'

      vcheck = 0.

      do while (vcheck .eq. 0) 

c ------
c Select point 1 
      write(6,*) 'Enter point 1 longitude (-180E to 180E)... x1?'
      read(5,*) x1
      x1 = mod(x1+180., 360.) - 180.

      write(6,*) 'Enter point 1 latitude (-90N to 90N)... y1?'
      read(5,*) y1
      y1 = mod(y1+90., 180.) - 90.

c Select point 2 
      write(6,*) 'Enter point 2 longitude (-180E to 180E)... x2?'
      read(5,*) x2
      x2 = mod(x2+180., 360.) - 180.

      write(6,*) 'Enter point 2 latitude (-90N to 90N)... y2?'
      read(5,*) y2
      y2 = mod(y2+90., 180.) - 90.

c 
      pt1(1) = x1
      pt1(2) = y1
      pt2(1) = x2
      pt2(2) = y2
c 
      write(6,'(/,a,2x,f7.1,1x,f6.1)') 'Point 1 (lon, lat) : ', pt1
      write(6,'(a,2x,f7.1,1x,f6.1)') 'Point 2 (lon, lat) : ', pt2

      write(51,'(/,a,2x,f7.1,1x,f6.1)') 'Point 1 (lon, lat) : ', pt1
      write(51,'(a,2x,f7.1,1x,f6.1)') 'Point 2 (lon, lat) : ', pt2

c Create mask 
      call get_section_line_masks(pt1, pt2, maskC, maskW, maskS)
      
c ------
c Check mask 
      vcheck = 0.
      do i=1,nx
         do j=1,ny
            vcheck = vcheck + abs(maskW(i,j)) + abs(maskS(i,j))
         enddo
      enddo
      
      if (vcheck.eq.0.) then
         write(6,*) 'NG: Section is empty.'
         write(6,*) 'Section must span at least one grid point. '
         write(6,*) 'Re-Enter end points ... '
      endif

      end do  ! end while 
c 
      return
      end subroutine mask01_section
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

      real*4 rf(nr), drf(nr)
      real*4 hfacc(nx,ny,nr), hfacw(nx,ny,nr), hfacs(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, hfacw, hfacs,
     $     kmt, dxg, dyg, dvol3d, rac

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
         write(51,"(3x,a,/)")
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

      real*4 rf(nr), drf(nr)
      real*4 hfacc(nx,ny,nr), hfacw(nx,ny,nr), hfacs(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, hfacw, hfacs,
     $     kmt, dxg, dyg, dvol3d, rac

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
         write(51,"(3x,a,/)")
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
      subroutine cr8_mask_section(fmask_w,fmask_s,x1,x2,y1,y2,z1,z2)
c -----------------------------------------------------
c Subroutine to create masks for volume transport through a section.
c     
c 26 November 2024, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr)
      real*4 hfacc(nx,ny,nr), hfacw(nx,ny,nr), hfacs(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, hfacw, hfacs,
     $     kmt, dxg, dyg, dvol3d, rac

c Mask 
      real*4 x1,x2,y1,y2,z1,z2
      real*4 adum
      real*4 dum3d(nx,ny,nr), dum3d_w(nx,ny,nr), dum3d_s(nx,ny,nr)
      real*4 dum2d_c(nx,ny), dum2d_w(nx,ny), dum2d_s(nx,ny)
      real*4 dum2d(nx,ny)
      real*4 dum1d(nr)

      character*256 floc_loc  ! location (mask) 
      character*256 fmask_w, fmask_s

c --------------
c Get horizontal mask (with values of 0/1/-1)
      call mask01_section(dum2d_c,dum2d_w,dum2d_s,x1,x2,y1,y2)

c Get vertical mask 
      write(6,'(/,a)') 'Enter depth range.' 
      write(6,*) '(Will select closest model levels.)'

c Top level 
      write(6,*) 'Enter minimum depth '//
     $     '(distance from surface in meters) ... z1?'
      read(5,*) z1 

c Find closest level to z1
      dum1d = abs(rc+z1)  ! rc is negative 
      k1 = 1
      dum0 = dum1d(k1)
      do k=2,nr
         if (dum1d(k).lt.dum0) then
            dum0=dum1d(k)
            k1 = k
         endif
      end do

c
      write(6,*) 'Enter maximum depth '//
     $     '(distance from surface in meters) ... z2?'
      read(5,*) z2
      if (z2.lt.z1) then 
         write(6,*) 'z2 must be larger than z1. Setting z2=z1'
         z2=z1
      endif

c Find closest level to z2
      dum1d = abs(rc+z2)  ! rc is negative 
      k2 = 1
      dum0 = dum1d(k2)
      do k=2,nr
         if (dum1d(k).lt.dum0) then
            dum0=dum1d(k)
            k2 = k
         endif
      end do

c
      write(6,'(/,a,2x,f6.1,1x,f6.1)') 'Min/Max depth : ', z1, z2
      write(6,'(a,2x,i6,1x,i6)')       '     k levels : ', k1, k2
 
      write(51,'(/,a,2x,f6.1,1x,f6.1)') 'Min/Max depth : ', z1, z2
      write(51,'(a,2x,i6,1x,i6)')       '     k levels : ', k1, k2
 
c --------------
c Apply area-weight
      do i=1,nx
         do j=1,ny
            do k=k1,k2
               dum3d_w(i,j,k) = dyg(i,j)*drf(k)*hfacw(i,j,k)
     $              *dum2d_w(i,j)
               dum3d_s(i,j,k) = dxg(i,j)*drf(k)*hfacs(i,j,k)
     $              *dum2d_s(i,j)
            enddo
         enddo
      enddo

c Save location for naming mask file 
      write(floc_loc,'(5(f6.1,"_"),f6.1)')
     $     x1,x2,y1,y2,z1,z2
      call StripSpaces(floc_loc)

c For reference, write 2d mask for UV; 
c   0/1 with sign for right-to-left transport in LLC grid
c   looking from (x1,y1) to (x2,y2)
      write(6,"(/,a)") '2d masks identifying section (signed 0/1) ...'

      fmask_w = 'mask2d_w.' // trim(floc_loc)
      write(6,"(3x,2a)")
     $     '2d w mask: ',trim(fmask_w)
      open(60,file=trim(fmask_w),form='unformatted',access='stream')
      write(60) dum2d_w
      close(60)

      fmask_s = 'mask2d_s.' // trim(floc_loc)
      write(6,"(3x,2a)")
     $     '2d s mask: ',trim(fmask_s)
      open(60,file=trim(fmask_s),form='unformatted',access='stream')
      write(60) dum2d_s
      close(60)

c Write 3d mask for UV volume transport (with area weights)
      write(6,"(/,a)") '3d masks for computing volume transport ... '

      fmask_w = 'mask3d_w.' // trim(floc_loc)
      write(6,"(3x,2a)")
     $     'Mask_w (3d): ',trim(fmask_w)
      open(60,file=trim(fmask_w),form='unformatted',access='stream')
      write(60) dum3d_w
      close(60)

      fmask_s = 'mask3d_s.' // trim(floc_loc)
      write(6,"(3x,2a,/)")
     $     'Mask_s (3d): ',trim(fmask_s)
      open(60,file=trim(fmask_s),form='unformatted',access='stream')
      write(60) dum3d_s
      close(60)

      return
      end subroutine cr8_mask_section
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
         stop 1
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
c 
c ============================================================
c 
      subroutine get_pkup_hours(f_pkup, pkuphrs, n_pkuphrs) 
c -----------------------------------------------------
c Subroutine to read in available instances (hours) of pickup files.
c -----------------------------------------------------
      implicit none
      integer, parameter :: max_files = 1000
c Input 
      character(len=256) :: f_pkup ! directory with pickup files
      integer pkuphrs(max_files), n_pkuphrs
c 
      integer :: i, ios, count
      character(len=256) :: line, cmd, fname 
      character(len=256), dimension(max_files) :: filenames

c Command to list files matching the pattern
      fname = trim(f_pkup) // '/pickup.*.data'
      call StripSpaces(fname)
      cmd = "ls " // trim(fname) // " > file_list.txt"
      call execute_command_line(trim(cmd))

c Open the file containing the list of filenames
      open(unit=10, file="file_list.txt", status="old", action="read")
      count = 0

c Read filenames and extract numbers
      do i = 1, max_files
         read(10, '(A)', iostat=ios) line
         if (ios /= 0) exit     ! Exit if end of file
         count = count + 1

c Find the position of "pickup." and ".data" and extract the number
         call extract_pkup_number(line, pkuphrs(count))
      end do
      close(10)

      n_pkuphrs = count 

c Output the extracted numbers
      print *, "Extracted pkuphrs:"
      do i = 1, count
         print *, pkuphrs(i)
      end do

      return
      end subroutine get_pkup_hours
c 
c ============================================================
c 
      subroutine extract_pkup_number(filename, number)
      character(len=*), intent(in) :: filename
      integer, intent(out) :: number
      integer :: start_pos, end_pos
      character(len=20) :: num_str

      start_pos = index(filename, "pickup.") + 7
      end_pos = index(filename, ".data") - 1

      if (start_pos > 7 .and. end_pos > start_pos) then
         num_str = filename(start_pos:end_pos)
         read(num_str, '(I20)') number
      else
         number = -1
      end if

      return
      end subroutine extract_pkup_number
