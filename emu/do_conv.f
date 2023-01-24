      program do_conv
c -----------------------------------------------------
c Program for Convolution Tool (V4r4)
c Conducts convolution for PARTICULAR control (ictrl). 
c
c Compute convolution of adjoint gradient with forcing based on
c specificitation in data.ecco set up by conv.f.
c     
c 07 December 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c EMU general 
cif      character*256 tooldir   ! directory where tool files are 
cif      common /tool/tooldir
      character*256 file_in, file_out  ! file names 
c
      character*256 f_command
      integer iunit, junit

c Control 
      integer nctrl                    ! number of controls 
      parameter (nctrl=8) 
      character*256 f_xx(nctrl)

      parameter(nweeks=1357) ! max number of weeks in V4r4
      integer nfrc     ! number of available weekly forcing 
      real*4 fac 
      integer istep(nweeks)  ! timestamp of control

      real*4 ctrl(nx,ny,nweeks)
      real*4 dum2d(nx,ny), ref2d(nx,ny)
      character*256 f_ctrl  ! directory name for control 
      character*256 f_dum, f_dum2
      integer ip1, ip2

c Adjoint 
      real*4 adxx(nx,ny,nweeks)
      character*256 f_adxx    ! directory name for adxx 
      integer f_size, nadxx, lag0, ir, ri, nlag 
      logical f_exist

c Convolution 
      real*4 recon2d(nx,ny,nweeks), recon1d(nweeks,nweeks)

      integer ictrl

c Strings for naming output directory
      character*256 dir_out   ! output directory

c ======================================================================

c ------------------
c Read in which control to compute 
      read(5,*) ictrl

c ------------------
c Read in Convolution specifics from conv.out
c (Set by conv.f) 
         
      open(70,file='conv.out')
      read(70,'(a)') f_ctrl
      read(70,'(a)') f_adxx
      read(70,*) nadxx
      read(70,*) lag0
      read(70,*) nlag
      read(70,'(a)') dir_out
      close(70)

c Repeat setup 
      if (ictrl .eq. 1) then 
         write(6,"(/,a,/)")
     $        'Conducting adxx-ctrl convolution ... '
         write(6,"(a,a)") 'ctrl read from = ',trim(f_ctrl)
         write(6,"(a,a)") 'adxx read from = ',trim(f_adxx)
         write(6,"(a,i0)") 'number of adxx records = ',nadxx
         write(6,"(a,i0)") 'Zero lag at (weeks) = ',lag0 
         write(6,"(a,i0)") 'maximum lag (weeks) = ',nlag
c         write(6,"(a,a,/)")
c     $        'Output will be in : ',trim(dir_out)
      endif

c --------------
c Set directory where tool files exist
cif      open (50, file='tool_setup_dir')
cif      read (50,'(a)') tooldir
cif      close (50)

c --------------
c forcing (control) name
      f_xx(1) = 'empmr'
      f_xx(2) = 'pload'   
      f_xx(3) = 'qnet'    
      f_xx(4) = 'qsw'     
      f_xx(5) = 'saltflux'
      f_xx(6) = 'spflx'   
      f_xx(7) = 'tauu'    
      f_xx(8) = 'tauv'    

c --------------
c Loop among the controls 

c      do 1000 i=1,nctrl    ! could be done in parallel
      i = ictrl
         write(6,"(a,i0,2x,a)") 'Conv for ... ',ictrl,trim(f_xx(i))

         recon2d(:,:,:) = 0.

c ------------------
c Read weekly forcing and compute its anomaly 
         if (ictrl.eq.1) then 
            write(6,"(/,3x,a)") '... reading ctrl '
            call flush(6)
         endif

         ref2d(:,:) = 0.

         file_in = trim(f_ctrl) // '/' // trim(f_xx(i)) //
     $        '_weekly_v1.*.data'
         f_command = 'ls ' // trim(file_in) // 
     $     ' > conv.dum_' // trim(f_xx(i))
         call execute_command_line(f_command, wait=.true.)

c Count number of weeks (files) available in forcing 
         file_in = 'conv.dum_' // trim(f_xx(i))
         open(50, file=trim(file_in), status='old', action='read')
         nfrc = 0
         f_dum = '_weekly_v1'
         do 
            read(50,'(a)',END=999) f_dum2 
            nfrc = nfrc + 1
c Read corresponding time-step
            ip1 = index(f_dum2,trim(f_dum)) + len(trim(f_dum))
            ip2 = index(f_dum2,'.data')
            f_command = trim(f_dum2(ip1+1:ip2-1))
            read(f_command,*) istep(nfrc)
         enddo
 999     close(50)

         if (nfrc.ne.nweeks) then
            write(6,"(/,a,i0,2x,i0,/)") '***** Anomalous # of forcing '
     $           // 'records : ictrl, nfrc = ',ictrl,nfrc
         endif

c reading first forcing as temporary reference
         open(50, file=trim(file_in), status='old', action='read')
         iunit = 50 + i

         j = 1 
            read(50,'(a)') file_in
            open(iunit, file=trim(file_in),
     $           form='unformatted',access='stream')
            read(iunit) ref2d
            close(iunit)
            ctrl(:,:,j) = 0.

c rest of the records
         do j=2,nfrc
            read(50,'(a)') file_in
            open(iunit, file=trim(file_in),
     $           form='unformatted',access='stream')
            read(iunit) dum2d
            close(iunit)
            ctrl(:,:,j) = dum2d-ref2d
         enddo

         close(50)

c Adjust time-mean 
         dum2d(:,:) = 0.
         do j=1,nfrc
            dum2d = dum2d + ctrl(:,:,j)
         enddo
         fac = 1./float(nfrc)
         dum2d = dum2d * fac
         do j=1,nfrc
            ctrl(:,:,j) = ctrl(:,:,j) - dum2d
         enddo
         ref2d = ref2d + dum2d

c ------------------
c Read adxx
         if (ictrl.eq.1) then 
            write(6,"(/,3x,a)") '... reading adxx '
            call flush(6)
         endif

         file_in = trim(f_adxx) //
     $        '/adxx_' // trim(f_xx(i)) //
     $        '.0000000129.data'
         inquire (file=trim(file_in), EXIST=f_exist,
     $        SIZE=f_size)
         if (.not. f_exist) then
            write (6,*) ' **** Error: '//
     $           'adxx file = ',trim(file_in) 
            write (6,*) ' **** does not exist'
            stop
         endif

         open(iunit, file=trim(file_in), action='read',
     $        access='direct', recl=nx*ny*4, form='unformatted')
c         do j=1,nadxx
         do j=lag0-nlag,lag0  ! read only what's needed
            read(iunit,rec=j) dum2d
            adxx(:,:,j) = dum2d
         enddo
         close(iunit)
         
c ------------------
c Do convolution 
         if (ictrl.eq.1) then 
            write(6,"(/,3x,a)") '... computing convolution '
            call flush(6)
         endif

         do k=0,nlag     ! lag
            if (mod(k,12).eq.0 .and. ictrl.eq.1) 
     $           write(6,"(a,i0)") '   lag (wks) = ',k

            do j=k+1,nfrc  ! time index
               recon2d(:,:,j) = recon2d(:,:,j) +
     $              adxx(:,:,lag0-k)*ctrl(:,:,j-k)
            enddo

c Sum to scalar time-series at this lag 
            do j=1,nfrc
               recon1d(j,k+1) = sum(recon2d(:,:,j))
            enddo
         enddo

c ------------------
c Save result
         junit = 60 + i
c         file_out = trim(dir_out) // '/recon2d_' // trim(f_xx(i))
         file_out = 'recon2d_' // trim(f_xx(i))
     $        // '.data'
         open (junit, file=trim(file_out), action='write',
     $        access='stream')
         write(junit) recon2d(:,:,1:nfrc)
         close(junit)

c         file_out = trim(dir_out) // '/recon1d_' // trim(f_xx(i))
         file_out = 'recon1d_' // trim(f_xx(i))
     $        // '.data'
         open (junit, file=trim(file_out), action='write',
     $        access='stream')
         write(junit) recon1d(1:nfrc,1:nlag+1)
         close(junit)

c         file_out = trim(dir_out) // '/istep_' // trim(f_xx(i))
         file_out = 'istep_' // trim(f_xx(i))
     $        // '.data'
         open (junit, file=trim(file_out), action='write',
     $        access='stream')
         write(junit) istep(1:nfrc)
         close(junit)

c 1000 continue
c
c --------------

      if (ictrl .eq. 1) write(6,"(/,a,/)") '... Done convolution.'

      stop
      end
