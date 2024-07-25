      program conv 
c -----------------------------------------------------
c Program for Convolution Tool (V4r4)
c
c Specify set of forcing, adjoint gradients, and maximum lag for
c do_conv.f that will conduct the convolution.
c 
c 07 December 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces
      external rel2abs_fname
      character*256 rel2abs_fname

c files
      character*256 f_inputdir  ! directory where native forcing is 
      character*130 file_in, file_out  ! file names 
      character*1  fcheck 
c
      character*256 f_command
      logical f_exist
      integer f_size, nadxx

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 dum2d(nx,ny)

c Strings for adxx
      character*256 f_adxx    ! directory name for adxx 
      character*256 f_adxx_read  ! directory name for adxx 
      character*256 dir_out   ! output directory
      integer nlag            ! maximum lag in convolution 
      character*256 f_lag     ! character version of nlag
      character*256 f_lag0    ! character version of lag0-1

      integer ip1, ip2
      character*256 fdum1, fdum2

c directories
      character*256 dir_run   ! run directory
      character*256 fcwd      ! current working directory

      integer date_time(8)  ! arrrays for date 
      character*10 bb(3)
      character*256 fdate 

c --------------
c Specifying adjoint gradient convolution with forcing. 
      write (6,"(a,/)") 'Convolution Tool ... '
      write (6,"(a,/)") 'Specify forcing, adjoint gradient, '
     $     // 'and maximum lag below ... '

c --------------
c Set directory names for ECCO input directory and adxx

      call getarg(1, f_inputdir)
      write(6,*) 'f_inputdir : ',trim(f_inputdir)

      call getarg(2, f_adxx)
      write(6,*) 'f_adxx : ',trim(f_adxx)

      call getarg(3, f_adxx_read)
      write(6,*) 'f_adxx_read : ',trim(f_adxx_read)

c --------------
c Save Convolution information
      file_out = 'conv.info'     ! descriptive 
      open (51, file=trim(file_out), action='write')
      write(51,"(a)") '***********************'
      write(51,"(a)") 'Output of conv.f'
      write(51,"(a)")
     $     'Convolution Tool specification'
      write(51,"(a,/)") '***********************'

      file_out = 'conv.out'      ! non-descriptive 
      open (52, file=trim(file_out), action='write')

c --------------
c Specify forcing, if not V4r4's (its directory)
      file_in = trim(f_inputdir) //
     $     '/forcing/other/flux-forced/forcing_weekly'
      write(6,"(a)") 'V4r4 weekly forcing is in directory '
      write(6,"(5x,a,/)") file_in

      write(6,"(a)") 'Use V4r4''s weekly forcing for convolution'//
     $     ' (phi in Eq 7 of Guide) ... (Y/N)? '
      read(5,"(a)") fcheck
      
      if (fcheck.eq.'N' .or. fcheck.eq.'n') then 
         write(6,"(/,a)") '*** Alternate forcing '
     $  // 'must have same file names and structure as V4r4''s ***' 
         write(6,"(a)") 'Enter directory name '
     $        // 'for alternate weekly forcing ... ?'
         read(5,"(a)") file_in 
      endif

      write(6,"(/,a)") 'Reading forcing from directory '
      write(6,"(5x,a)") trim(file_in)

      write(51,"(a)") 'Reading forcing from directory '
      write(51,"(a,/)") trim(file_in)
      
      write(52,"(a)") trim(file_in)

c --------------
c Check adxx files
      fdum1 = 'emu_adj_'
      fdum2 = '/output'
      ip1 = index(f_adxx,trim(fdum1)) 
      ip2 = index(f_adxx,trim(fdum2)) 
      if (ip1.eq.0 .or. ip2.eq.0 .or. ip1.gt.ip2) then
         write(6,"(3x,a)") 'Directory name does not conform to Tool.'
         write(6,"(3x,a,/)") 'Directory name must include '//
     $        '''emu_adj_'' and end ''/output''.'
         write(6,"(3x,a,/)") 'Try again.'
         stop
      endif
      ip1 = ip1 + len(trim(fdum1))
      ip2 = ip2 - 1

c
      write(6,"(/,5x,a)") 'Reading adxx from '
      write(6,"(5x,a,/)") trim(f_adxx)

      write(51,"(a)") 'Reading adxx from '
      write(51,"(a,/)") trim(f_adxx)

      write(52,"(a)") trim(f_adxx)

c Check number of records in adxx
      file_in = trim(f_adxx_read) //
     $     '/adxx_tauu.0000000129.data'
      inquire (file=trim(file_in), EXIST=f_exist,
     $     SIZE=f_size)
      if (.not. f_exist) then
         write (6,*) ' **** Error: '//
     $        'adxx file = ',trim(file_in) 
         write (6,*) '**** does not exist'
         stop
      endif

      nadxx = f_size/(nx*ny*4)
      
      write(6,"(5x,a,i0,/)") 'number of adxx records = ',nadxx
      write(51,"(a,i0,/)") 'number of adxx records = ',nadxx
      write(52,"(i0)") nadxx

c Identify record that is 0-lag 
      open(60, file=trim(file_in), action='read',
     $     access='direct', recl=nx*ny*4, form='unformatted')
      lag0 = 0
      do j=nadxx,1,-1
         read(60,rec=j) dum2d
         dum = maxval(abs(dum2d))
         if (dum.ne.0. .and. lag0.lt.j) lag0 = j
      enddo
      close(60)

      write(6,"(5x,a,i0,/)") 'Zero lag at (weeks) = ',lag0 
      write(51,"(a,i0,/)") 'Zero lag at (weeks) = ',lag0 
      write(52,"(i0)") lag0
         
      write(f_lag0,"(i0)") lag0-1
      call StripSpaces(f_lag0)

c --------------
c Define maximum lag in convolution
      write(6,"(a)")
     $     'Enter maximum lag (weeks) to use in convolution '
     $     //'(delta_t_max in Eq 7 of Guide) ... (0-'
     $     // trim(f_lag0) // ')?'
      read (5,*) nlag
      write(6,"(5x,a,1x,i0)") 'nlag = ',nlag

      if (lag0-nlag .lt. 1) then
         nlag = lag0-1
         write(6,"(5x,a)")
     $        'nlag exceeds maximum available in adxx file.'
         write(6,"(5x,a,i0,/)")
     $        '*** max lag re-set to = ',nlag
      endif

      write(51,"(a,1x,i0,/)") 'Maximum lag (weeks) in convolution = ',
     $     nlag

      write(52,"(i0)") nlag 

      write(f_lag,"(i0)") nlag
      call StripSpaces(f_lag)

c --------------
c set pbs script (walltime for computation)
      f_command = 'cp -f pbs_conv.sh_orig pbs_conv.sh'
      call execute_command_line(f_command, wait=.true.)
cif      f_command = 'cp -f do_conv_int.sh_orig do_conv_int.sh'
cif      call execute_command_line(f_command, wait=.true.)

c --------------
c Create output directory for convolution
      dir_out = 'emu_conv_' // trim(f_adxx(ip1:ip2))
     $     // '_' // trim(f_lag)
      write(6,"(/,a,a,/)")
     $     'Convolution Tool output will be in : ',trim(dir_out)

      inquire (file=trim(dir_out), EXIST=f_exist)
      if (f_exist) then
         write (6,*) '**** WARNING: Directory exists already : ',
     $        trim(dir_out) 
         call date_and_time(bb(1), bb(2), bb(3), date_time)
         write(fdate,"('_',i4.4,2i2.2,'_',3i2.2)")
     $     date_time(1:3),date_time(5:7)
         dir_out = trim(dir_out) // trim(fdate)
         write(6,"(/,a,a,/)")
     $        '**** Renaming output directory to :',trim(dir_out)
      endif

      f_command = 'mkdir ' // dir_out
      call execute_command_line(f_command, wait=.true.)
      call getcwd(fcwd)
      dir_run = trim(fcwd) // '/' // trim(dir_out) // '/temp'
      f_command = 'mkdir ' // dir_run
      call execute_command_line(f_command, wait=.true.)

      file_out = 'conv.dir_out'
      open (53, file=file_out, action='write')
      write(53,"(a)") trim(dir_out)
      write(53,"(a)") trim(dir_run)
      write(53,"(a)") trim(dir_out) // '/output'
      close(53)

      write(51,"(a,1x,a,/)") 'Output directory : ',trim(dir_out)
      close(51)

      write(52,"(a)") trim(dir_out)
      close(52)

      write(6,"(a)") '... Done conv setup (conv.out)'

c Move all needed files into run directory
cif      f_command = 'sed -i -e "s|YOURDIR|'//
cif     $     trim(dir_run) //'|g" pbs_conv.sh'
cif      call execute_command_line(f_command, wait=.true.)
cif
cif      f_command = 'sed -i -e "s|YOURDIR|'//
cif     $     trim(dir_run) //'|g" do_conv_int.sh'
cif      call execute_command_line(f_command, wait=.true.)
cif
cif      f_command = 'cp -f pbs_conv.sh ' // trim(dir_run)
cif      call execute_command_line(f_command, wait=.true.)
      
      f_command = 'mv -f conv.info ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

      f_command = 'mv -f conv.out ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

      f_command = 'cp -f conv.dir_out ' // trim(dir_run)
      call execute_command_line(f_command, wait=.true.)

c Wrapup 
      write(6,"(/,a)") '*********************************'
      f_command = 'do_conv.x'
      write(6,"(4x,a)") 'Run "' // trim(f_command) //
     $     '" to conduct convolution.'
      write(6,"(a,/)") '*********************************'

      stop
      end
