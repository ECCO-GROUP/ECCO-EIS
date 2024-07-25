      program msim_ave6hrly
c -----------------------------------------------------
c Example program for EMU Modified Simulation Tool (V4r4).
c Average select 6-hourly forcing over time for use in Tool. 
c
c 23 January 2024, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c-----------------------------------------------------

      parameter(nx=90, ny=1170)
      real*4 dum2d(nx,ny)
      real*4 ref2d(nx,ny)
      real*4 ave2d(nx,ny)
      integer icnt 
      character*256 froot, fvar, ff, fout 
      character*4 fyr

c-----------------------------------------------------
      write(6,*) 'Time average forcing file .... '

      write(6,*) 'Enter directory of input forcing ... ?'
      read(5,'(a)') froot
      write(6,*) 'Forcing files read from directory ; '
      write(6,*) froot
      
      write(6,*) 'Enter forcing basename ... (e.g., oceTAUX)?'
      read(5,'(a)') fvar
      write(6,*) '   Forcing will be : ', trim(fvar)

      write(6,*) 'Enter first year to average ... y1 (e.g., 1992)?'
      read(5,*) iy1
      write(6,*) '   First year will be : ',iy1

      write(6,*) 'Enter last year to average ... y2 (e.g., 2017)?'
      read(5,*) iy2
      write(6,*) '   Last year will be : ',iy2
      
c Read in first record of the last year as a reference
      write(fyr,'(i4)') iy2
      ff = trim(froot) // '/' // trim(fvar) // '_6hourlyavg_' // fyr
      open(1, file=trim(ff), access='stream', action='read')
      read(1) ref2d
      close(1)
      icnt = 0

c Average
      do iy=iy1,iy2
         write(fyr,'(i4)') iy
         ff = trim(froot) // '/' // trim(fvar) // '_6hourlyavg_' // fyr
         icnt_y = 0
         open(1, file=trim(ff), access='stream', action='read')
         do id=1,10000
            read(1,end=1000) dum2d
            icnt = icnt + 1
            icnt_y = icnt_y + 1
            ave2d = ave2d + (dum2d-ref2d)
         enddo
 1000    close(1)
         write(6,'("count = ",i4,2x,i4,2x,i0)') iy,icnt_y,icnt
      enddo

c 
      dum = 1./float(icnt)
      ave2d = ave2d*dum + ref2d

c Output
      write(ff,'(i4,"_",i4)') iy1,iy2
      fout = 'msim_ave6hrly_' // trim(ff) // '.' // trim(fvar)
      write(6,*) 'Output file : ',trim(fout)
      open(60, file=trim(fout),  access='stream')
      do i=1,366*4
         write(60) ave2d
      enddo
      close(60)

      stop
      end

      
