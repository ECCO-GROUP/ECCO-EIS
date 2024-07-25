      program mask
c -----------------------------------------------------
c Standalone program to create simple rectilinear mask
c using subroutines cr8_mask2d and cr8_mask3d. 
c     
c 19 June 2024, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces
c files
      character*256 f_inputdir   ! where external tool files exist
      common /tool/f_inputdir
      character*130 file_in, file_out  ! file names 

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr), hfacc(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, kmt, dxg, dyg, dvol3d, rac

c Mask 
      integer imsk 
      character*256 fmask

c --------------
c Set directory where external tool files exist
      call getarg(1,f_inputdir)
      write(6,*) 'inputdir read : ',trim(f_inputdir)

c --------------
c Read model grid from EMU tool directory (XC, YC is fully
c specified. Those used in the model have blank regions.)
c 
      call grid_info
      
c --------------
c Interactive specification of mask 
      write (6,*) 'Creating mask for EMU ... '

c --------------
c Save OBJF information for reference. 
      file_out = 'mask.info'
      open (51, file=file_out, action='write')
      write(51,"(a)") '***********************'
      write(51,"(a)") 'Output of mask.f'
      write(51,"(a)") 'Creating mask for EMU'
      write(51,"(a,/)") '***********************'

c --------------
c Choose 2d or 3d mask 
      write (6,"(3x,a)") 
     $ 'Choose mean of horizontal area (2d) or volume (3d) ... (2/3)?'
      read (5,*) imsk 

      if (imsk.eq.2) then
c --------------
c Horizontal area mean (2d)
         write(6,"(3x,a,/)")
     $        '... Mask will be for horizontal area mean (2d).'
         write(51,"(3x,a,/)")
     $        '... Mask will be for horizontal area mean (2d).'

         call cr8_mask2d(fmask)

      else 
c --------------
c Volume mean (3d)
         write(6,"(3x,a,/)")
     $        '... Mask will be for volume mean (3d).'
         write(51,"(3x,a,/)")
     $        '... Mask will be for volume mean (3d).'

         call cr8_mask3d(fmask)

      endif 

      close (51)

      stop
      end
