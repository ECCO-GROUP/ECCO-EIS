c ============================================================
c     Program to compute budget.
c
c Combines parallel output of do_budg_flx_parallel.f
c ============================================================
c
      program do_budg_flx_combine
      use mysparse 
c -----------------------------------------------------
c ALTERNATE VERSION OF do_budg: Computes and save fluxes 
c through target region faces. 
c 
c Program for Budget Tool (V4r4)
c Collect model output based on data.ecco set up by budg.f. 
c Modeled after f17_e_2.pro 
c     
c 02 August 2023, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces

c files
      character*256 file_in, file_out, file_dum, fvar  ! file names 

c Common variables for all budgets
      parameter(nmonths=312, nyrs=26, yr1=1992, d2s=86400.)
     $                          ! max number of months of V4r4

      character*12  fname 
      integer ibud_i, nmonths_i
      real*4 dt(nmonths)
      real*4 budt(nmonths), dumt(nmonths)

      integer ipar        ! parallel run ID
      character*256 fpar        ! string(ipar)
      integer ncpus, nfiles
      
      character fmsk ! mask name 
      integer n3d  ! mask dimension 
      real, allocatable :: b3d(:)
      
c --------------
c File emu_budg.sum_tend
      file_out = 'emu_budg.sum_tend'
      file_in = trim(file_out) // '_*'
      file_dum = 'do_budg_flx_combine.files'
      
      call file_search(file_in, file_dum, ncpus)
      write(6,*) 'ncpus = ',ncpus
      
      open(11, file=file_out, action='write', access='stream')

      open(12, file=file_dum, action='read')
      i=0
      do
         read(12,"(a)",end=100) file_dum
         i=i+1
         open(20+i,file=trim(file_dum),action='read',access='stream')
      enddo
 100  continue
      close(12)

c Read and add different 
      do i=1,ncpus
         read(20+i) ibud_i
         read(20+i) nmonths_i
         read(20+i) fname
         read(20+i) dt
      enddo
      write(11) ibud_i
      write(11) nmonths_i
      write(11) fname
      write(11) dt

      do
         do i=1,ncpus
            read(20+i,end=101) fname
         enddo
         write(11) fname

         budt(:) = 0.
         do i=1,ncpus
            read(20+i,end=101) dumt
            budt = budt + dumt
         enddo
         write(11) budt
      enddo
 101  continue
      
      do i=1,ncpus
         close(20+i)
      enddo
      close(11)
         
c --------------
c File emu_budg.sum_tint
c (time-integrate tendency in emu_budg.sum_tend)
      file_in = 'emu_budg.sum_tend'
      file_out = 'emu_budg.sum_tint'

      open(11, file=file_in, action='read', access='stream')
      open(12, file=file_out, action='write', access='stream')

      read(11) ibud_i
      read(11) nmonths_i
      read(11) fname
      read(11) dt

      write(12) ibud_i
      write(12) nmonths_i
      write(12) fname
      write(12) dt

      do
         read(11,end=110) fname
         read(11) dumt
         
         call wrt_tint(dumt, fname, dt, 12)
      enddo

 110  continue
      close(11)
      close(12)

c --------------
c File emu_budg.mkup
      file_in = 'emu_budg.mkup_*_001'
      file_dum = 'do_budg_flx_combine.mkup_files'

c search number of mkup terms      
      call file_search(file_in, file_dum, nfiles)
      open(12, file=file_dum, action='read')

c Loop over terms       
      do it=1,nfiles
         read(12,"(a)") file_dum

c Extract name of term         
         index_start = index(file_dum, 'mkup_') + len('mkup_')
         index_end = index(file_dum(index_start:), '_001')

         if (index_start > len('mkup_') .and. index_end > 0) then
            fvar = file_dum(index_start:index_start+index_end-2)
            print *, 'Term: ', trim(fvar)
         else
            print *, 'Term string not found: ',file_dum
            stop
         end if         

         file_out=file_dum(1:index_start-1) // trim(fvar)
         open(11, file=file_out, action='write', access='stream')

c Read in results from 1st job          
         ipar = 1
         write(fpar,'(i3.3)') ipar
         file_dum = trim(file_out) // '_' // trim(fpar)
         open (21, file=trim(file_dum), action='read',
     $        access='stream')
         read(21) fmsk          ! mask
         read(21) i31           ! corresponding array in emu_budg.sum_trend
         
         write(11) fmsk
         write(11) i31

c Read mask dimension
         open(31, file='emu_budg.msk3d_'//fmsk, action='read',
     $        access='stream')
         read(31) n3d
         close(31)
         allocate(b3d(n3d))
         
         do
            read(21,end=102) b3d
            write(11) b3d
         enddo
 102     continue
         close(21)

c Read in results from other jobs
         do ipar=2,ncpus
            write(fpar,'(i3.3)') ipar
            file_dum = trim(file_out) // '_' // trim(fpar)
            open (21, file=trim(file_dum), action='read',
     $           access='stream')
            read(21) fmsk       ! mask
            read(21) i31        ! corresponding array in emu_budg.sum_trend

            do 
               read(21,end=103) b3d
               write(11) b3d
            enddo
 103        close(21)
         enddo
c End Loop over terms
         deallocate(b3d)
      enddo

      close(11)
      close(12)

      stop
      end program do_budg_flx_combine
c 
c ============================================================
c 
      subroutine wrt_tint(budg, fname, dt, fid)
c Integrate tendency in time and output to file 
      parameter(nmonths=312, nyrs=26, yr1=1992, d2s=86400.)
      
      real*4 budg(nmonths), dt(nmonths)
      character*12  fname 
      integer fid

      real*4 tint(nmonths), tdum 

c ------------------------------------
c Integrate in time 
      tint(:) = 0.
      tint(1) = budg(1) *dt(1)
      do im=2,nmonths
         tint(im)  = tint(im-1)  + budg(im)*dt(im)
      enddo

c Reset time-integral reference to im=2
      tdum = tint(2)
      tint(:) = tint(:) - tdum

c Output 
      write(fid) fname
      write(fid) tint 

      return
      end subroutine wrt_tint

      
