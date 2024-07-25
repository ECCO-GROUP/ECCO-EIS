      program check_timing
      implicit none
    
c Declare variables
      integer nproc, hour26yr_trc, hour26yr_fwd, hour26yr_adj
      namelist /mitgcm_timing/ nproc, hour26yr_trc,
     $     hour26yr_fwd, hour26yr_adj

      character*100 input_line 
      integer ninput
    
c Read mitgcm_timing.nml
      open(unit=10, file='./mitgcm_timing.nml', status='old')
      read(10, nml=mitgcm_timing)
      close(10)
    
c Modify the namelist variables as needed
      write(6,'(/,a,i0)')
     $     'Timing estimate (h) for 26-yr run with nproc = ',nproc
    
c Prompt the user
      input_line='Offline forward tracer'
      call check_value(input_line, hour26yr_trc)

      input_line='Forward V4r4'
      call check_value(input_line, hour26yr_fwd)

      input_line='Adjoint V4r4'
      call check_value(input_line, hour26yr_adj)

c Output namelist file (overwrite)
      open(unit=20, file='./mitgcm_timing.nml', status='replace')
      write(20, nml=mitgcm_timing)
      close(20)
    
      stop
      end program check_timing
c
c ============================================================
c 
      subroutine check_value(fname, hour26yr)
      character*100 fname
      character*100 input_line 
      integer hour26yr
c
      write(6,'(/,a,i0)') trim(fname) // ': ', hour26yr
      write(6,'(a)') 'Press Enter to keep the current value ' //
     $     'or enter a new value ... ?'
      read(5,'(a)') input_line
    
c Check if the user entered any characters
      if (len_trim(input_line) > 0) then
c User entered input
         read(input_line, *) hour26yr
      else
c User pressed Enter, keep the current values
      end if
      write(6,'(a,i0)') '***** ' // trim(fname) //
     $     ' will use: ', hour26yr

      return
      end subroutine check_value
    
      
