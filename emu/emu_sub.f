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
      subroutine chk_mask2d(fmask_in,nx,ny,dum2d)
c Check mask file is native 2d

      character(len=*) :: fmask_in
      integer :: nx, ny
      real*4 :: dum2d(nx,ny)
      integer :: ij(2)
      real*8 sum8

      character*256 :: f_command
      logical :: f_exist
      integer :: file_size
      integer :: f_target


      INQUIRE(FILE=fmask_in, SIZE=file_size, EXIST=f_exist)

      if (.not. f_exist) then
         write(6,*) 'File does not exist ... ',fmask_in
         write(6,*) '... aborting'
         stop
      endif
      
      f_target = long(nx)*long(ny)*4
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

      ij = maxloc(abs(dum2d))
      write(6,1000) trim(fmask_in)
 1000 format(/,3x,'Mask file : ',a)
      write(6,1001) dum2d(ij(1),ij(2))
 1001 format(3x,'Masks maximum absolute value = ',1pe12.4)
      write(6,1002) ij
 1002 format(3x,6x,'at (i,j) =',i5,1x,i5)

      sum8 = 0.d0
      do i=1,nx
         do j=1,ny
            sum8 = sum8 + dble(dum2d(i,j))
         enddo
      enddo
      write(6,1003) sum8
 1003 format(3x,'Masks sum = ',1pe12.4)

      return
      end
c 
c ============================================================
c 
      subroutine chk_mask3d(fmask_in,nx,ny,nr,dum3d)
c Check mask file is native 3d

      character(len=*) :: fmask_in
      integer :: nx, ny, nr
      real*4 :: dum3d(nx,ny,nr)
      integer :: ijk(3)
      real*8 sum8

      character*256 :: f_command
      logical :: f_exist
      integer :: file_size
      integer :: f_target


      INQUIRE(FILE=fmask_in, SIZE=file_size, EXIST=f_exist)

      if (.not. f_exist) then
         write(6,*) 'File does not exist ... ',fmask_in
         write(6,*) '... aborting'
         stop
      endif
      
      f_target = long(nx)*long(ny)*long(nr)*4
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

      ijk = maxloc(abs(dum3d))
      write(6,1000) trim(fmask_in)
 1000 format(/,3x,'Mask file : ',a)
      write(6,1001) dum3d(ijk(1),ijk(2),ijk(3))
 1001 format(3x,'Masks maximum absolute value = ',1pe12.4)
      write(6,1002) ijk
 1002 format(3x,6x,'at (i,j,k) =',i5,1x,i5,1x,i5)

      sum8 = 0.d0
      do i=1,nx
         do j=1,ny
            do k=1,nr
               sum8 = sum8 + dble(dum3d(i,j,k))
            enddo
         enddo
      enddo
      write(6,1003) sum8
 1003 format(3x,'Masks sum = ',1pe12.4)

      return
      end
c 
c ============================================================
c 
      subroutine samp_2d_r8(tooldir,ffile,
     $     irec,pert_i,pert_j,objf,nrec,mobjf)
c Sample native 2d real*8 file 

      character(len=*) :: tooldir, ffile
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
      f_file = trim(tooldir) // '/emu_pert_ref/diags/' // trim(ffile) 
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
      subroutine samp_3d(tooldir,ffile,irec,
     $     pert_i,pert_j,pert_k,objf,nrec,mobjf)
c Sample native 3d file 

      character(len=*) :: tooldir, ffile 
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
      f_file = trim(tooldir) // '/emu_pert_ref/diags/' // trim(ffile) 
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
      subroutine samp_2d_r8_wgtd(tooldir,ffile,irec,
     $     wgt2d,objf,nrec,mobjf,istep)
c Sample native 2d real*8 file 

      integer nx, ny
      parameter (nx=90, ny=1170)

      character(len=*) :: tooldir, ffile 
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
      f_file = trim(tooldir) // '/emu_pert_ref/diags/' // trim(ffile) 
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
      subroutine samp_3d_wgtd(tooldir,ffile,irec,
     $     wgt3d,objf,nrec,mobjf,istep)
c Sample native 3d file 

      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c Strip spaces from string 
      character(len=*) :: tooldir, ffile 
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
      f_file = trim(tooldir) // '/emu_pert_ref/diags/' // trim(ffile) 
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
