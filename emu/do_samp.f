      program do_samp
c -----------------------------------------------------
c Program for Sampling Tool (V4r4)
c Sample model output based on data.ecco set up by samp.f. 
c     
c 30 November 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces
c files
      character*256 f_inputdir   ! directory where tool files are 
      common /tool/f_inputdir
      character*130 file_in, file_out  ! file names 
c
      character*256 f_command

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c Strings for naming output directory
      character*256 dir_out   ! output directory

c OBJF 
      parameter(ndays=9497)
      real*4 objf(ndays)
      real*4 mobjf
      integer nrec
      integer istep(ndays)

c --------------
c Set directory where external tool files exist
      call getarg(1,f_inputdir)
      write(6,*) 'inputdir read : ',trim(f_inputdir)

c --------------
c Read output directory 
cif      file_out = 'samp.dir_out'
cif      open (52, file=file_out, action='read')
cif      read(52,"(a)") dir_out
cif      close(52)

c --------------
c Sample state
      objf(:) = 0.
      mobjf = 0.
      call samp_objf(objf, mobjf, nrec, istep)

c --------------
c Output sampled state

      write(f_command,'("_",i5)') nrec
      call StripSpaces(f_command)

      file_out = 'samp.out' // trim(f_command)
      open (51, file=file_out, action='write', access='stream')
      write(51) objf(1:nrec)
      write(51) mobjf 
      close(51)

      file_out = 'samp.step' // trim(f_command)
      open (51, file=file_out, action='write', access='stream')
      write(51) istep(1:nrec)
      close(51)

      file_out = 'samp.txt'
      open (51, file=file_out, action='write')
      write(51,1501) 'time(hr)', 'sample'
 1501 format(a10,3x,a20)
      do i=1,nrec
         write(51,1502) istep(i), objf(i)+mobjf
      enddo
 1502 format(i10,3x,1pe20.12)
      close(51)

c --------------
c Delete objf_*_mask* files. 
c Can otherwise cause an error message if samp.x is run again, 
c because INQUIRE returns EXIST=.false. for dangling symbolic links. 
cif      f_command = 'rm -f objf_*_mask*'
cif     call execute_command_line(f_command, wait=.true.)
cif
cif      write(6,"(a,/)") '... Done.'
cif
cif      write(6,"(/,a)") '*********************************'
cif      write(6,"(a,a)")
cif     $     'Sampling Tool output is in : ',trim(dir_out)
cif      write(6,"(a,/)") '*********************************'

      stop
      end
c 
c ============================================================
c 
      subroutine samp_objf(objf, mobjf, nrec, istep)
c Compute OBJF per data.ecco by samp.f

c
      real*4 objf(*)
      real*4 mobjf
      integer nrec
      integer istep(*)
c
      character*256 f_inputdir   ! directory where tool files are 
      common /tool/f_inputdir

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

c     Number of Generic Cost terms:
c     =============================
      INTEGER NGENCOST
      PARAMETER ( NGENCOST=40 )


      INTEGER MAX_LEN_FNAM
      PARAMETER ( MAX_LEN_FNAM = 512 )

      character*(MAX_LEN_FNAM) gencost_name(NGENCOST)
      character*(MAX_LEN_FNAM) gencost_barfile(NGENCOST)
      character*(5)            gencost_avgperiod(NGENCOST)
      character*(MAX_LEN_FNAM) gencost_mask(NGENCOST)
      real*4                   mult_gencost(NGENCOST)
      LOGICAL gencost_msk_is3d(NGENCOST)

      namelist /ecco_gencost_nml/
     &         gencost_barfile,
     &         gencost_name,
     &         gencost_mask,      
     &         gencost_avgperiod,
     &         gencost_msk_is3d,
     &         mult_gencost

c 

      parameter(ndays=9497) ! max number of days in V4r4
cif   parameter(nmonths=312) ! max number of months of V4r4
      real*4 objf_1(ndays), objf_2(ndays)
      real*4 mobjf_1, mobjf_2
      integer nobjf 
      character*256 ffile, fmask

      real*4 dum2d(nx,ny), dum3d(nx,ny,nr)

c ------------------
c Read in OBJF definition from data.ecco

c Set ecco_gencost_nml default
      do i=1,NGENCOST
         gencost_name(i) = 'gencost'
         gencost_barfile(i) = ' '
         gencost_avgperiod(i) = ' '
         gencost_mask(i) = ' '
         gencost_msk_is3d(i) = .FALSE. 
         mult_gencost(i) = 0.
      enddo
         
      open(70,file='data.ecco')
      read(70,nml=ecco_gencost_nml)
      close(70)

      nobjf = 0
      do i=1,NGENCOST
         if (gencost_name(i) .eq. 'boxmean') nobjf = nobjf + 1
      enddo

      write(6,*) 'nobjf = ',nobjf

c ------------------
c Read in model state

c Monthly state 
      if (trim(gencost_avgperiod(1)).eq.'month') then 

      write(6,"(a,/)") 'Sampling MONTHLY means ... '

      do i=1,nobjf

         if (gencost_barfile(i).eq.'m_boxmean_eta_dyn') then 
            ffile = 'state_2d_set1_mon'
            fmask = trim(gencost_mask(i)) // 'C'
            call chk_mask2d(fmask,nx,ny,dum2d)
            call samp_2d_r8_wgtd(f_inputdir,ffile,1,dum2d,
     $           objf_1,nrec,mobjf_1,istep)

         else if (gencost_barfile(i).eq.'m_boxmean_obp') then 
            ffile = 'state_2d_set1_mon'
            fmask = trim(gencost_mask(i)) // 'C'
            call chk_mask2d(fmask,nx,ny,dum2d)
            call samp_2d_r8_wgtd(f_inputdir,ffile,2,dum2d,
     $           objf_1,nrec,mobjf_1,istep)

         else if (gencost_barfile(i).eq.'m_boxmean_THETA') then 
            ffile = 'state_3d_set1_mon'
            fmask = trim(gencost_mask(i)) // 'C'
            call chk_mask3d(fmask,nx,ny,nr,dum3d)
            call samp_3d_wgtd(f_inputdir,ffile,1,dum3d,
     $           objf_1,nrec,mobjf_1,istep)

         else if (gencost_barfile(i).eq.'m_boxmean_SALT') then 
            ffile = 'state_3d_set1_mon'
            fmask = trim(gencost_mask(i)) // 'C'
            call chk_mask3d(fmask,nx,ny,nr,dum3d)
            call samp_3d_wgtd(f_inputdir,ffile,2,dum3d,
     $           objf_1,nrec,mobjf_1,istep)

         else if (gencost_barfile(i).eq.'m_horflux_vol') then 
            ffile = 'state_3d_set1_mon'
            fmask = trim(gencost_mask(i)) // 'W'
            call chk_mask3d(fmask,nx,ny,nr,dum3d)
            call samp_3d_wgtd(f_inputdir,ffile,3,dum3d,
     $           objf_1,nrec,mobjf_1,istep)

            fmask = trim(gencost_mask(i)) // 'S'
            call chk_mask3d(fmask,nx,ny,nr,dum3d)
            call samp_3d_wgtd(f_inputdir,ffile,4,dum3d,
     $           objf_2,nrec,mobjf_2,istep)

            objf_1 = objf_1 + objf_2
            mobjf_1 = mobjf_1 + mobjf_2

         else
            write(6,*) 'This should not happen ... '
            stop
         endif
            
         objf_1 = objf_1*mult_gencost(i)
         mobjf_1 = mobjf_1*mult_gencost(i)

         objf(1:nrec) = objf(1:nrec) + objf_1(1:nrec)
         mobjf = mobjf + mobjf_1

      enddo

c Daily state 
      else if (trim(gencost_avgperiod(1)).eq.'day') then 

      write(6,"(a,/)") 'Sampling DAILY means ... '
      do i=1,nobjf

         if (gencost_barfile(i).eq.'m_boxmean_eta_dyn') then 
            ffile = 'state_2d_set1_day'
            fmask = trim(gencost_mask(i)) // 'C'
            call chk_mask2d(fmask,nx,ny,dum2d)
            call samp_2d_r8_wgtd(f_inputdir,ffile,1,dum2d,
     $           objf_1,nrec,mobjf_1,istep)

         else if (gencost_barfile(i).eq.'m_boxmean_obp') then 
            ffile = 'state_2d_set1_day'
            fmask = trim(gencost_mask(i)) // 'C'
            call chk_mask2d(fmask,nx,ny,dum2d)
            call samp_2d_r8_wgtd(f_inputdir,ffile,2,dum2d,
     $           objf_1,nrec,mobjf_1,istep)

         else
            write(6,*) 'This should not happen ... '
            stop
         endif
            
         objf_1 = objf_1*mult_gencost(i)
         mobjf_1 = mobjf_1*mult_gencost(i)

         objf(1:nrec) = objf(1:nrec) + objf_1(1:nrec)
         mobjf = mobjf + mobjf_1

      enddo

c Incorrect average specified
      else
         write(6,*) 'This should not happen ... '
         write(6,*) 'avgperiod = ',trim(gencost_avgperiod(1))
         stop
      endif

      return 
      end subroutine 
c 
c ============================================================
c 
      
