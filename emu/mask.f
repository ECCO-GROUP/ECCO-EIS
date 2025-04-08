      program mask
c -----------------------------------------------------
c Standalone program to create simple masks for EMU. This program is
c provided for reference purpose only; All EMU tools include options to
c run the equivalent of this program. This program provides options to
c create masks for 
c  1) Areal mean over a horizontal region (subroutine cr8_mask2d)
c  2) Volume mean over a 3d region (subroutine cr8_mask3d)
c  3) Horizontal volume transport (subroutine cr8_mask_section)
c     
c Usage:
c     ./mask.x EMU_INPUT_DIR
c where EMU_INPUT_DIR is EMU input directory (specified when setting up
c EMU with emu_setup.sh).
c
c 19 June 2024, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces
c files
      character*256 f_inputdir   ! where external tool files exist
      common /tool/f_inputdir
      character*130 file_in, file_out  ! file names 

c Mask 
      integer imsk, iref 
      character*256 fmask, fmask_w, fmask_s
      real*4 x1,x2,y1,y2,z1,z2

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
      write (6,"(3x,a)") 'Choose mask(s) for horizontal ' //
     $     'area mean (1), volume mean (2),' 
      write (6,"(3x,a)")
     $ '  or horizontal volume transport (3) ... (1/2/3)?'
      read (5,*) imsk 

c --------------
c Horizontal area mean (2d)
      if (imsk.eq.1) then
         write(6,"(3x,a,/)")
     $        '... Mask will be for horizontal area mean (2d).'
         write(51,"(3x,a,/)")
     $        '... Mask will be for horizontal area mean (2d).'

         call cr8_mask2d(fmask,x1,x2,y1,y2,iref)

c --------------
c Volume mean (3d)
      elseif (imsk.eq.2) then 
         write(6,"(3x,a,/)")
     $        '... Mask will be for volume mean (3d).'
         write(51,"(3x,a,/)")
     $        '... Mask will be for volume mean (3d).'

         call cr8_mask3d(fmask,x1,x2,y1,y2,z1,z2,iref)

c --------------
c Horizontal volume transport (3d)
      elseif (imsk.eq.3) then 
         write(6,"(3x,a,/)")
     $        '... Mask will be for horizontal volume transport.'
         write(51,"(3x,a,/)")
     $        '... Mask will be for horizontal volume transport.'

         call cr8_mask_section(fmask_w,fmask_s,x1,x2,y1,y2,z1,z2)

      endif 

      close (51)

      stop
      end
