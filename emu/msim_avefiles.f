      program msim_avefiles
c -----------------------------------------------------
c Example program for EMU Modified Simulation Tool (V4r4).
c Average files for use in Tool.
c
c Files can be time-series, each file at a different instant; 
c e.g., state_3d_set1_mon*data 
c   1) All files must be direct access (fixed record length), 
c   2) All files must have same variables (fixed file size),  
c   3) Each file can have multiple variables, 
c   4) Variable must be either 2d (nx, ny) or 3d (nx, ny, nr),
c   5) Variables can be either single or double precision. 
c
c 08 February 2024, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c-----------------------------------------------------

      parameter(nx=90, ny=1170, nr=50)

      character*256 froot, ffile, fvar, file_dum 
      character*256 file_in, file_out
      character*256 ffile_prefix
      
      integer iprec, i3d, i1, i2, iprec1, iprec2
      integer fsize, rlen, nvar

c-----------------------------------------------------

      write(6,'(a,/)') 'Time average state files .... '

      write(6,*) 'Enter directory name of state files ... ?'
      read(5,'(a)') froot
      write(6,*) 'State files to be read from directory ; '
      write(6,'(a,/)') trim(froot)

      write(6,*) 'Enter name of files to average ... '//
     $     '(e.g., state_3d_set1_mon*data)?'
      read(5,'(a)') ffile
      write(6,*) 'Files to average  ; '
      write(6,'(a,/)') trim(ffile)

c Get file name prefix
      index_star = index(ffile, '*') 
      ffile_prefix=ffile(1:index_star-1)

      write(6,*) 'Single or Double precision ... (s/d)?'
      read(5,'(a)') fvar
      iprec1 = INDEX(trim(fvar), 'd') ! single when iprec=0
      iprec2 = INDEX(trim(fvar), 'D') ! single when iprec=0 
      if (iprec1 .eq. 0 .and. iprec2 .eq. 0) then
         iprec = 0
         write(6,'(a,/)') '... File treated as SINGLE precision'
      else
         iprec = 1
         write(6,'(a,/)') '... File treated as DOUBLE precision'
      end if

      write(6,*) 'Are variables 2d or 3d  ... (2/3)?'
      read(5,*) i3d  ! 2d when i3d=2
      if (i3d .eq. 2) then
         write(6,'(a,/)') '... Variables treated as 2D'
      else
         write(6,'(a,/)') '... Variables treated as 3D'
      end if

c Create list of the files 
      file_in = trim(froot) // '/' // trim(ffile)
      file_out = 'msim_avefiles.files'
      call file_search(file_in, file_out, nfiles)
      write(6,'(a,i0,/)') 'number of files ... nfiles = ',nfiles

c First and last file to average
      i1=0
      do while (i1.lt.1 .or. i1.gt.nfiles) 
         write(6,'(a,i0,a)')
     $        'Enter first file to average ... (1-',nfiles,')?'
         read(5,*) i1
      enddo

      i2=0
      do while (i2.lt.1 .or. i2.gt.nfiles .or. i2.lt.i1) 
         write(6,'(a,i0,a)')
     $        'Enter last file to average ... (1-',nfiles,')?'
         read(5,*) i2
      enddo

      write(6,'(/,a,i0,2x,i0,/)')
     $     'First and last file to average ... ',i1,i2

c Compute number of variables in each file 
      open(50, file=file_out, action='read')
      read(50,'(a)') file_dum

      open(51, file=file_dum, action='read', status='OLD')
      inquire(51, size=fsize)
      close(51)

      if (iprec.eq.0) then 
         if (i3d.eq.2) then
            rlen = nx*ny*4
            nvar = fsize/rlen
            write(6,'(a,i0,1x,i0,/)') 'fsize, rlen = ',fsize,rlen
            write(6,'(a,i0,/)')
     $           'Number of variables in file ... ',nvar
            call avefiles_s2d(i1,i2,nvar,nfiles,ffile_prefix)
         else
            rlen = nx*ny*nr*4
            nvar = fsize/rlen
            write(6,'(a,i0,1x,i0,/)') 'fsize, rlen = ',fsize,rlen
            write(6,'(a,i0,/)')
     $           'Number of variables in file ... ',nvar
            call avefiles_s3d(i1,i2,nvar,nfiles,ffile_prefix)
         endif
      else
         if (i3d.eq.2) then
            rlen = nx*ny*8
            nvar = fsize/rlen
            write(6,'(a,i0,1x,i0,/)') 'fsize, rlen = ',fsize,rlen
            write(6,'(a,i0,/)')
     $           'Number of variables in file ... ',nvar
            call avefiles_d2d(i1,i2,nvar,nfiles,ffile_prefix)
         else
            rlen = nx*ny*nr*8
            nvar = fsize/rlen
            write(6,'(a,i0,1x,i0,/)') 'fsize, rlen = ',fsize,rlen
            write(6,'(a,i0,/)')
     $           'Number of variables in file ... ',nvar
            call avefiles_d3d(i1,i2,nvar,nfiles,ffile_prefix)
         endif
      endif

      stop
      end
c
c ==============================================================
c
      subroutine avefiles_s2d(i1,i2,nvar,nfiles,ffile_prefix)
      parameter(nx=90, ny=1170, nr=50)

      integer nvar, nfiles
      character*256 ffile_prefix 

      integer icnt
      character*256 file_dum
      real*4 fac 

      real*4, allocatable :: dum2d(:,:)
      real*4, allocatable :: ref2d(:,:,:)
      real*4, allocatable :: ave2d(:,:,:)
      real*4, allocatable :: var2d(:,:,:)

c ............
c Allocate array
      allocate(dum2d(nx,ny))
      allocate(ref2d(nx,ny,nvar))
      allocate(ave2d(nx,ny,nvar))
      allocate(var2d(nx,ny,nvar))

      dum2d(:,:)=0.
      ref2d(:,:,:)=0.
      ave2d(:,:,:)=0.
      var2d(:,:,:)=0.

c Read first file as reference
      rewind(50)
      read(50,'(a)') file_dum

      open(61, file=trim(file_dum), action='read', access='stream')
      do i=1,nvar
         read(61) dum2d
         ref2d(:,:,i) = dum2d
      enddo
      close(61)

c Compute mean and variance 
      rewind(50)
      icnt = 0
      do im=1,nfiles
         read(50,'(a)') file_dum
         if (im.ge.i1 .and. im.le.i2) then 

         icnt = icnt + 1 
         open(61, file=trim(file_dum), action='read', access='stream')
         do iv=1,nvar
            read(61) dum2d
            dum2d = dum2d - ref2d(:,:,iv)
            ave2d(:,:,iv) = ave2d(:,:,iv) + dum2d
            var2d(:,:,iv) = var2d(:,:,iv) + dum2d**2 
         enddo
         close(61)

         endif 
      enddo

c Finalize
      fac = 1./float(icnt)
      ave2d = ave2d*fac
      var2d = var2d*fac - ave2d**2
      ave2d = ave2d + ref2d

c Output
      file_dum='msim_avefiles.s2d_mean.'//ffile_prefix
      write(6,'(a,a,/)') 'Mean written to file ',trim(file_dum)
      open(62, file=trim(file_dum), access='stream')
      write(62) ave2d
      close(62)

      file_dum='msim_avefiles.s2d_var.'//ffile_prefix
      write(6,'(a,a,/)') 'Variance written to file ',trim(file_dum)
      open(62, file=trim(file_dum), access='stream')
      write(62) var2d
      close(62)

      return
      end
c
c ==============================================================
c
      subroutine avefiles_s3d(i1,i2,nvar,nfiles,ffile_prefix)
      parameter(nx=90, ny=1170, nr=50)

      integer nvar, nfiles
      character*256 ffile_prefix 

      integer icnt
      character*256 file_dum
      real*4 fac 

      real*4, allocatable :: dum3d(:,:,:)
      real*4, allocatable :: ref3d(:,:,:,:)
      real*4, allocatable :: ave3d(:,:,:,:)
      real*4, allocatable :: var3d(:,:,:,:)

c ............
c Allocate array
      allocate(dum3d(nx,ny,nr))
      allocate(ref3d(nx,ny,nr,nvar))
      allocate(ave3d(nx,ny,nr,nvar))
      allocate(var3d(nx,ny,nr,nvar))

      dum3d(:,:,:)=0.
      ref3d(:,:,:,:)=0.
      ave3d(:,:,:,:)=0.
      var3d(:,:,:,:)=0.

c Read first file as reference
      rewind(50)
      read(50,'(a)') file_dum

      open(61, file=trim(file_dum), action='read', access='stream')
      do i=1,nvar
         read(61) dum3d
         ref3d(:,:,:,i) = dum3d
      enddo
      close(61)

c Compute mean and variance 
      rewind(50)
      icnt = 0
      do im=1,nfiles
         read(50,'(a)') file_dum
         if (im.ge.i1 .and. im.le.i2) then 

         icnt = icnt + 1 
         open(61, file=trim(file_dum), action='read', access='stream')
         do iv=1,nvar
            read(61) dum3d
            dum3d = dum3d - ref3d(:,:,:,iv)
            ave3d(:,:,:,iv) = ave3d(:,:,:,iv) + dum3d
            var3d(:,:,:,iv) = var3d(:,:,:,iv) + dum3d**2
         enddo
         close(61)

         endif 
      enddo

c Finalize
      fac = 1./float(icnt)
      ave3d = ave3d*fac
      var3d = var3d*fac - ave3d**2
      ave3d = ave3d + ref3d

c Output
      file_dum='msim_avefiles.s3d_mean.'//ffile_prefix
      write(6,'(a,a,/)') 'Mean written to file ',trim(file_dum)
      open(62, file=trim(file_dum), access='stream')
      write(62) ave3d
      close(62)

      file_dum='msim_avefiles.s3d_var.'//ffile_prefix
      write(6,'(a,a,/)') 'Variance written to file ',trim(file_dum)
      open(62, file=trim(file_dum), access='stream')
      write(62) var3d
      close(62)

      return
      end
c
c ==============================================================
c
      subroutine avefiles_d2d(i1,i2,nvar,nfiles,ffile_prefix)
      parameter(nx=90, ny=1170, nr=50)

      integer nvar, nfiles
      character*256 ffile_prefix 

      integer icnt
      character*256 file_dum
      real*4 fac 

      real*8, allocatable :: dum2d(:,:)
      real*8, allocatable :: ref2d(:,:,:)
      real*8, allocatable :: ave2d(:,:,:)
      real*8, allocatable :: var2d(:,:,:)

c ............
c Allocate array
      allocate(dum2d(nx,ny))
      allocate(ref2d(nx,ny,nvar))
      allocate(ave2d(nx,ny,nvar))
      allocate(var2d(nx,ny,nvar))

      dum2d(:,:)=0.
      ref2d(:,:,:)=0.
      ave2d(:,:,:)=0.
      var2d(:,:,:)=0.

c Read first file as reference
      rewind(50)
      read(50,'(a)') file_dum

      open(61, file=trim(file_dum), action='read', access='stream')
      do i=1,nvar
         read(61) dum2d
         ref2d(:,:,i) = dum2d
      enddo
      close(61)

c Compute mean and variance 
      rewind(50)
      icnt = 0
      do im=1,nfiles
         read(50,'(a)') file_dum
         if (im.ge.i1 .and. im.le.i2) then 

         icnt = icnt + 1 
         open(61, file=trim(file_dum), action='read', access='stream')
         do iv=1,nvar
            read(61) dum2d
            dum2d = dum2d - ref2d(:,:,iv)
            ave2d(:,:,iv) = ave2d(:,:,iv) + dum2d
            var2d(:,:,iv) = var2d(:,:,iv) + dum2d**2
         enddo
         close(61)

         endif 
      enddo

c Finalize
      fac = 1./float(icnt)
      ave2d = ave2d*fac
      var2d = var2d*fac - ave2d**2
      ave2d = ave2d + ref2d

c Output
      file_dum='msim_avefiles.d2d_mean.'//ffile_prefix
      write(6,'(a,a,/)') 'Mean written to file ',trim(file_dum)
      open(62, file=trim(file_dum), access='stream')
      write(62) ave2d
      close(62)

      file_dum='msim_avefiles.d2d_var.'//ffile_prefix
      write(6,'(a,a,/)') 'Variance written to file ',trim(file_dum)
      open(62, file=trim(file_dum), access='stream')
      write(62) var2d
      close(62)

      return
      end
c
c ==============================================================
c
      subroutine avefiles_d3d(i1,i2,nvar,nfiles,ffile_prefix)
      parameter(nx=90, ny=1170, nr=50)

      integer nvar, nfiles
      character*256 ffile_prefix 

      integer icnt
      character*256 file_dum
      real*4 fac 

      real*8, allocatable :: dum3d(:,:,:)
      real*8, allocatable :: ref3d(:,:,:,:)
      real*8, allocatable :: ave3d(:,:,:,:)
      real*8, allocatable :: var3d(:,:,:,:)

c ............
c Allocate array
      allocate(dum3d(nx,ny,nr))
      allocate(ref3d(nx,ny,nr,nvar))
      allocate(ave3d(nx,ny,nr,nvar))
      allocate(var3d(nx,ny,nr,nvar))

      dum3d(:,:,:)=0.
      ref3d(:,:,:,:)=0.
      ave3d(:,:,:,:)=0.
      var3d(:,:,:,:)=0.

c Read first file as reference
      rewind(50)
      read(50,'(a)') file_dum

      open(61, file=trim(file_dum), action='read', access='stream')
      do i=1,nvar
         read(61) dum3d
         ref3d(:,:,:,i) = dum3d
      enddo
      close(61)

c Compute mean and variance 
      rewind(50)
      icnt = 0
      do im=1,nfiles
         read(50,'(a)') file_dum
         if (im.ge.i1 .and. im.le.i2) then 

         icnt = icnt + 1 
         open(61, file=trim(file_dum), action='read', access='stream')
         do iv=1,nvar
            read(61) dum3d
            dum3d = dum3d - ref3d(:,:,:,iv)
            ave3d(:,:,:,iv) = ave3d(:,:,:,iv) + dum3d
            var3d(:,:,:,iv) = var3d(:,:,:,iv) + dum3d**2
         enddo
         close(61)

         endif 
      enddo

c Finalize
      fac = 1./float(icnt)
      ave3d = ave3d*fac
      var3d = var3d*fac - ave3d**2
      ave3d = ave3d + ref3d

c Output
      file_dum='msim_avefiles.d3d_mean.'//ffile_prefix
      write(6,'(a,a,/)') 'Mean written to file ',trim(file_dum)
      open(62, file=trim(file_dum), access='stream')
      write(62) ave3d
      close(62)

      file_dum='msim_avefiles.d3d_var.'//ffile_prefix
      write(6,'(a,a,/)') 'Variance written to file ',trim(file_dum)
      open(62, file=trim(file_dum), access='stream')
      write(62) var3d
      close(62)

      return
      end
       
      


      
