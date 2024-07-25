      program msim_ic 
c -----------------------------------------------------
c Example program for EMU Modified Simulation Tool (V4r4).
c Replace initial condition (pickup files) with available
c results of msim_avefiles.f. 
c
c 10 February 2024, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c-----------------------------------------------------

      parameter(nx=90, ny=1170, nr=50)

      character*256 fvar, file_dum 
      character*256 file_in, file_out

      integer nfiles 
      
      real*8 u(nx,ny,nr), v(nx,ny,nr)
      real*8 t(nx,ny,nr), s(nx,ny,nr)
      real*8 gunm1(nx,ny,nr), gvnm1(nx,ny,nr)
      real*8 gtnm1(nx,ny,nr), gsnm1(nx,ny,nr)
      real*8 etan(nx,ny), detahdt(nx,ny)
      real*8 etah(nx,ny)
      real*8 ggl90tke(nx,ny,nr)

c-----------------------------------------------------

      write(6,'(a,/)') 'Modify intial condition (pickup files) .... '
      
c---------------------------
c For pickup.*.data file 
      
c Read in pickup file 
      file_in='pickup.*.data'
      file_out='msim_ic.files'
      call file_search(file_in, file_out, nfiles)
      if (nfiles.eq.0) then
         write(6,'(a,i0,/)') 'No pickup.*.data found ... Aborting.'
         stop
      elseif (nfiles.ne.1) then
         write(6,'(a,i0,/)')
     $        'More than one pickup.*.data found ... Aborting.'
         stop
      endif
      
      open(50, file=file_out, action='read')
      read(50,'(a)') file_dum
      close(50)

      open(51, file=file_dum, action='read', access='stream')
      read(51) u
      read(51) v
      read(51) t
      read(51) s
      read(51) gunm1
      read(51) gvnm1
      read(51) gtnm1
      read(51) gsnm1
      read(51) etan
      read(51) detahdt
      read(51) etah
      close(51)

c Replace variables
      fvar='u'
      call getic_3d(fvar, u, inew)
      if (inew.eq.1) gunm1(:,:,:)=0.

      fvar='v'
      call getic_3d(fvar, v, inew) 
      if (inew.eq.1) gvnm1(:,:,:)=0.
         
      fvar='t'
      call getic_3d(fvar, t, inew) 
      if (inew.eq.1) gtnm1(:,:,:)=0.
         
      fvar='s'
      call getic_3d(fvar, s, inew) 
      if (inew.eq.1) gsnm1(:,:,:)=0.
         
      fvar='eta'
      call getic_2d(fvar, etah, inew) 
      if (inew.eq.1) then
         detahdt(:,:)=0.
         etan=etah
      endif

c Save modified pickup file
      open(51, file=file_dum, action='write', access='stream')
      write(51) u
      write(51) v
      write(51) t
      write(51) s
      write(51) gunm1
      write(51) gvnm1
      write(51) gtnm1
      write(51) gsnm1
      write(51) etan
      write(51) detahdt
      write(51) etah
      close(51)

c---------------------------
c For pickup_ggl90.*.data file 
      
c Read in base pickup_ggl90 file 
      file_in='pickup_ggl90.*.data'
      file_out='msim_ic.files'
      call file_search(file_in, file_out, nfiles)
      if (nfiles.eq.0) then
         write(6,'(a,i0,/)')
     $        'No pickup_ggl90.*.data found ... Aborting.'
         stop
      elseif (nfiles.ne.1) then
         write(6,'(a,i0,/)')
     $        'More than one pickup_ggl90.*.data found ... Aborting.'
         stop
      endif
      
      open(50, file=file_out, action='read')
      read(50,'(a)') file_dum
      close(50)

      open(51, file=file_dum, action='read', access='stream')
      read(51) ggl90tke
      close(51)

c Replace variables
      fvar='ggl90tke'
      call getic_3d(fvar, ggl90tke, inew) 

c Save modified pickup_ggl90 file
      open(51, file=file_dum, action='write', access='stream')
      write(51) ggl90tke
      close(51)

      stop
      end program msim_ic
c
c ==============================================================
c
      subroutine getic_3d(fvar, d3d, inew)
c Get Initial Condition of a 3d variable      

      parameter(nx=90, ny=1170, nr=50)
      character*256 fvar
      real*8 d3d(nx,ny,nr)
      integer inew

      real*4 s3d(nx,ny,nr)
      character*256 file_in, fprec
      integer iprec1, iprec2, iprec, irec
      
c ............

      inew = 0
      write(6,*) 'Enter file name with initial '
     $     // trim(fvar) // ' ... ? '//
     $     ' (Enter return if not replacing.) '
      write(6,*) '(File must be direct access with 3d records.)'
      read(5,'(a)') file_in
      if (trim(file_in).eq.'') then
         write(6,'(a,/)') 'Not replacing ... ' // trim(fvar)
         return
      endif

      inew = 1
      write(6,'(a,a,/)') 'Replacement read from : ',trim(file_in)

      write(6,*) 'Is file Single or Double precision ... (s/d)?'
      read(5,'(a)') fprec
      iprec1 = INDEX(trim(fprec), 'd') ! single when iprec=0
      iprec2 = INDEX(trim(fprec), 'D') ! single when iprec=0 
      if (iprec1 .eq. 0 .and. iprec2 .eq. 0) then
         iprec = 4
         write(6,'(a,/)') '... File treated as SINGLE precision'
      else
         iprec = 8
         write(6,'(a,/)') '... File treated as DOUBLE precision'
      end if

      write(6,*) 'Enter record number of replacement ... ?'
      read(5,*) irec
      write(6,'(a,i0,/)') 'Reading record ... ',irec

      open(60, file=trim(file_in), access='direct',
     $     recl=nx*ny*nr*iprec)
      if (iprec.eq.4) then
         read(60,rec=irec) s3d
         d3d=s3d
      else
         read(60,rec=irec) d3d
      endif
      close(60)

      return
      end subroutine getic_3d
c
c ==============================================================
c
      subroutine getic_2d(fvar, d2d, inew)
c Get Initial Condition of a 2d variable      

      parameter(nx=90, ny=1170, nr=50)
      character*256 fvar
      real*8 d2d(nx,ny)
      integer inew

      real*4 s2d(nx,ny)
      character*256 file_in, fprec
      integer iprec1, iprec2, iprec, irec

c ............

      inew = 0
      write(6,*) 'Enter file name with initial '
     $     // trim(fvar) // ' ... ? '//
     $     ' (Enter return if not replacing.) '
      write(6,*) '(File must be direct access with 2d records.)'
      read(5,'(a)') file_in
      if (trim(file_in).eq.'') then
         write(6,'(a,/)') 'Not replacing ... ' // trim(fvar)
         return
      endif

      inew = 1
      write(6,'(a,a,/)') 'Replacement read from : ',trim(file_in)

      write(6,*) 'Is file Single or Double precision ... (s/d)?'
      read(5,'(a)') fprec
      iprec1 = INDEX(trim(fprec), 'd') ! single when iprec=0
      iprec2 = INDEX(trim(fprec), 'D') ! single when iprec=0 
      if (iprec1 .eq. 0 .and. iprec2 .eq. 0) then
         iprec = 4
         write(6,'(a,/)') '... File treated as SINGLE precision'
      else
         iprec = 8
         write(6,'(a,/)') '... File treated as DOUBLE precision'
      end if

      write(6,*) 'Enter record number of replacement ... ?'
      read(5,*) irec
      write(6,'(a,i0,/)') 'Reading record ... ',irec

      open(60, file=trim(file_in), access='direct',
     $     recl=nx*ny*iprec)
      if (iprec.eq.4) then
         read(60,rec=irec) s2d
         d2d=s2d
      else
         read(60,rec=irec) d2d
      endif
      close(60)

      return
      end subroutine getic_2d
       
      


      
