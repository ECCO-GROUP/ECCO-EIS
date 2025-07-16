      program do_atrb
c -----------------------------------------------------
c Program for Attribution Tool (V4r4).
c Compute contribution to sampled quantity by type of control. 
c     
c 19 February 2024, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces
c files
      character*256 file_in, file_out  ! file names 

c OBJF 
c     parameter(ndays=9497, nterms=6)
c      parameter(ndays=9497, nterms=7)
      parameter(ndays=9497, nterms=8)
      real*4 objf(ndays, nterms)
      real*4 mobjf(nterms)
      integer istep(ndays)
      character*256 fterms

      integer nrec
      integer filesize 

c --------------
c Count number of records in do_samp.f output
      file_in = 'atrb.tmp_1'
      inquire(file=trim(file_in), size=filesize)
      nrec = filesize/4. - 1

c --------------
c Read sampled output of separate runs
      do i=1,nterms
         write(fterms,'(i1.1)') i
         file_in = 'atrb.tmp_' // trim(fterms)
         open (61, file=file_in, action='read', access='stream')
         read(61) objf(1:nrec,i)
         read(61) mobjf(i) 
         close(61)
      enddo

      write(fterms,'("_",i5)') nrec
      call StripSpaces(fterms)
      file_out = 'samp.step' // trim(fterms)
      open (51, file=file_out, action='read', access='stream')
      read(51) istep(1:nrec)
      close(51)

c --------------
c Compute individual contribution
      do i=2,nterms-1
         objf(1:nrec,i) = objf(1:nrec,1) - objf(1:nrec,i)
         mobjf(i) = mobjf(1) - mobjf(i)
      enddo
c         i=nterms
c         objf(1:nrec,i) = objf(1:nrec,i)
c         mobjf(i) = mobjf(i)

c --------------
c Output
      file_out = 'atrb.out' // trim(fterms)
      open (51, file=file_out, action='write', access='stream')
      write(51) objf(1:nrec,1:nterms)
      write(51) mobjf(1:nterms)
      close(51)

      file_out = 'atrb.step' // trim(fterms)
      open (51, file=file_out, action='write', access='stream')
      write(51) istep(1:nrec)
      close(51)

      file_out = 'atrb.txt'
      open (51, file=file_out, action='write')
      write(51,1501) 'time(hr)', 'ref', 'wind', 'htflx',
     $     'fwflx', 'sflx', 'pload', 'ic', 'mean'
 1501 format(a10,3x,8a20)
      do i=1,nrec
         write(51,1502) istep(i), (objf(i,j)+mobjf(j),j=1,nterms)
      enddo
 1502 format(i10,3x,8(1pe20.12))
      close(51)

      stop
      end program do_atrb
