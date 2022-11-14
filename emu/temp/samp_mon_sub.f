c 
c ============================================================
c 
      subroutine samp_mon_var(f1,iobjf,floc_loc)
c Specifiy OBJF variable(s)  

c Argument 
      character*6 f1 ! OBJF variable order (counter)
      integer iobjf  ! OBJF variable index 
      character*256 floc_loc  ! location (mask) of first OBJF variable

c ------------
c Specify spatial mask (weight) according to variable
      if (iobjf .eq. 1 .or. iobjf .eq. 2) then 
         call samp_mon_2d(f1, iobjf,floc_loc)
      else if (iobjf .eq. 3 .or. iobjf .eq. 4) then
         call samp_mon_3d(f1, iobjf,floc_loc)
      else 
         call samp_mon_uv(f1, iobjf,floc_loc)
      endif

      return
      end subroutine
c 
c ============================================================
c 
      subroutine samp_mon_2d(f1, iobjf, floc_loc)

c OBJF for either SSH or OBP
      character*6 f1
      integer iobjf
      character*256 floc_loc  ! location (mask) of first OBJF variable

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny)
      common /grid/xc, yc, rc, bathy
c 
      character*1 pert_2, c1, c2
      integer pert_i, pert_j
      real*4 dum2d(nx,ny)
      character*256 f_command
      character*256 fmask  ! name of mask file 
      character*256 fdum
      logical f_exist
      character*24 fmult
      real*4 amult 

c ------
c Identify OBJF variable among the two available 
      if (iobjf.ne.1 .and. iobjf.ne.2) then
         write(6,*) 'iobjf is NG for objf_var_2d ... ', iobjf
         write(6,*) 'This should not happen. Aborting ...'
         stop
      endif

c ------
c Select type of spatial mask 
      ifunc = 0
      do while (ifunc.ne.1 .and. ifunc.ne.2) 
         write (6,"(3x,a,a)")
     $        'Choose either VARIABLE at a point (1) or ',
     $        'VARIABLE weighted in space (2) ... (1/2)?'
         read (5,*) ifunc
      end do

      write(51,"(3x,'ifunc = ',i2)") ifunc

      if (ifunc .eq. 1) then 
c When OBJF is at a point

         write(6,"(3x,a,/)") '... OBJF will be VARIABLE at a point'
         write(51,"(3x,a,/)") ' --> OBJF is VARIABLE at a point. '

         call slct_2d_pt(pert_i,pert_j)

         write(51,2002) pert_i,pert_j
 2002    format(3x,'pert_i, pert_j = ',i2,2x,i4)
         write(51,"(3x,a,/)") ' --> OBJF model grid location (i,j).'

herehere ...

c Create 2d mask for the point 
         dum2d = 0.
         dum2d(pert_i,pert_j) = 1. 

         fmask = 'objf_' // trim(f1) // '_mask_C'
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) dum2d
         close(60)

c Save location for naming run directory
         write(floc_loc,'(i9,"_",i9)') pert_i,pert_j
         call StripSpaces(floc_loc)

      else
c When OBJF is VARIABLE weighted in space 

         write(6,"(3x,a)")
     $    '... OBJF will be a linear function of selected variable'
         write(6,"(4x,a)")
     $        'i.e., MULT * SUM( MASK * VARIABLE )'
         write(6,"(/,4x,a,/)") '!!!!! MASK must be uploaded' //
     $     ' (binary native format) before proceeding ... '

         write(51,"(3x,a)")
     $   ' --> OBJF is a linear function of selected variable(s)'
         write(51,"(3x,a,/)")
     $     ' --> i.e., MULT * SUM( MASK * VARIABLE )'

c Get mask file name 
         write(6,*) '   Enter MASK filename ... ?'  
         read(5,'(a)') fmask

         write(6,'(3x,"fmask = ",a)') trim(fmask)
         write(51,'(3x,"fmask = ",a)') trim(fmask)
         write(51,"(3x,a,/)") ' --> MASK file. '

c Save mask file name for naming run directory
         floc_loc = trim(fmask)
         call StripSpaces(floc_loc)

c Check mask 
         call chk_mask2d(fmask,nx,ny,dum2d)

c Link input mask to what model expects 
         fdum = 'objf_' // trim(f1) // '_mask_C' 
         INQUIRE(FILE=trim(fdum), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fdum)
            call execute_command_line(f_command, wait=.true.)
         endif

         f_command = 'ln -s ' // trim(fmask) // ' ' //
     $        trim(fdum)
         call execute_command_line(f_command, wait=.true.)

c Enter scaling factor
         write(6,"(3x,a)") 'Enter scaling factor MULT ... ?'
         read(5,*) amult

         write(6,'(3x,"amult = ",1pe12.4)') amult 
         write(51,'(3x,"amult = ",1pe12.4)') amult
         write(51,"(3x,a,/)") ' --> OBJF Scaling factor. '

         write(fmult,"(1pe12.4)") amult 
         f_command = 'sed -i -e ' //
     $  '"s/gencost(' // trim(f1) //
     $ ').*/gencost(' // trim(f1) //
     $ ')= ' // fmult // ',/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)

      endif

c Specify variable being NOT 3D      
      f_command = 'sed -i -e ' //
     $     '"s/is3d(' // trim(f1) //
     $     ').*/is3d(' // trim(f1) //
     $     ')=.FALSE.,/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

      return
      end subroutine
c 
c ============================================================
c 
      subroutine objf_var_3d(f1, iobjf, floc_loc)

c Update data.ecco OBJF for either THETA or SALT
      character*6 f1
      integer iobjf
      character*256 floc_loc  ! location (mask) of first OBJF variable

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny)
      common /grid/xc, yc, rc, bathy
c 
      character*1 pert_2, c1, c2
      integer pert_i, pert_j, pert_k
      real*4 dum3d(nx,ny,nr)
      character*256 f_command
      character*256 fmask  ! name of mask file 
      character*256 fdum
      logical f_exist
      character*24 fmult
      real*4 amult 

c ------
c Identify OBJF variable among the two available 
      if (iobjf.eq.3) then
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''m_boxmean_THETA''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (iobjf.eq.4) then 
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''m_boxmean_SALT''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else
         write(6,*) 'iobjf is NG for objf_var_3d ... ', iobjf
         write(6,*) 'This should not happen. Aborting ...'
         stop
      endif

c ------
c Select type of spatial mask 
      ifunc = 0
      do while (ifunc.ne.1 .and. ifunc.ne.2) 
         write (6,*) 'Choose either VARIABLE at a point (1) or ',
     $        ' VARIABLE weighted in space (2) ... (1/2)?'
         read (5,*) ifunc
      end do

      write(51,"(3x,'ifunc = ',i2)") ifunc

      if (ifunc .eq. 1) then 
c When OBJF is at a point

         write(6,"(a,/)") '... OBJF will be VARIABLE at a point'
         write(51,"(3x,a,/)") ' --> OBJF is VARIABLE at a point. '

         call slct_3d_pt(pert_i,pert_j,pert_k)

         write(51,2002) pert_i,pert_j,pert_k
 2002    format(3x,'pert_i, pert_j, pert_k = ',i2,2x,i4,2x,i2)
         write(51,"(3x,a,/)") ' --> OBJF model grid location (i,j,k).'

c Create 3d mask for the point 
         dum3d = 0.
         dum3d(pert_i,pert_j,pert_k) = 1. 

         f_command = 'sed -i -e ' //
     $  '"s/mask(' // trim(f1) //
     $ ').*/mask(' // trim(f1) //
     $ ')=''objf_' // trim(f1) // '_mask_''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)

         fmask = 'objf_' // trim(f1) // '_mask_C'
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) dum3d
         close(60)

c Save location for naming run directory
         write(floc_loc,'(i9,"_",i9,"_",i9)') pert_i,pert_j,pert_k
         call StripSpaces(floc_lod)

      else
c When OBJF is VARIABLE weighted in space 

         write(6,*)
     $    '... OBJF will be a linear function of selected variable'
         write(6,"(4x,a)")
     $     'i.e., SUM( MASK * VARIABLE )'
         write(6,"(/,4x,a,/)") '!!!!! MASK must be uploaded' //
     $     ' (binary native format) before proceeding ... '

         write(51,"(3x,a)")
     $   ' --> OBJF is a linear function of selected variable(s)'
         write(51,"(3x,a,/)")
     $     ' --> i.e., SUM( MASK * VARIABLE )'

c Get mask file name 
         write(6,*) '   Enter MASK filename ... ?'  
         read(5,'(a)') fmask

         write(51,'(3x,"fmask = ",a)') trim(fmask)
         write(51,"(3x,a,/)") ' --> MASK file. '

c Save mask file name for naming run directory
         floc_loc = trim(fmask)
         call StripSpaces(floc_loc)

c Check mask 
         call chk_mask3d(fmask,nx,ny,nr,dum3d)

c Link input mask to what model expects 
         fdum = 'objf_' // trim(f1) // '_mask_C' 
         INQUIRE(FILE=trim(fdum), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fdum)
            call execute_command_line(f_command, wait=.true.)
         endif

         f_command = 'ln -s ' // trim(fmask) // ' ' //
     $        trim(fdum)
         call execute_command_line(f_command, wait=.true.)

c Enter scaling factor
         write(6,*) 'Enter scaling factor MULT ... ?'
         read(5,*) amult

         write(6,'("amult = ",1pe12.4)') amult 
         write(51,'(3x,"amult = ",1pe12.4)') amult
         write(51,"(3x,a,/)") ' --> OBJF Scaling factor. '

         write(fmult,"(1pe12.4)") amult 
         f_command = 'sed -i -e ' //
     $  '"s/gencost(' // trim(f1) //
     $ ').*/gencost(' // trim(f1) //
     $ ')= ' // fmult // ',/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)

      endif

c Specify variable is 3D      
      f_command = 'sed -i -e ' //
     $     '"s/is3d(' // trim(f1) //
     $     ').*/is3d(' // trim(f1) //
     $     ')=.TRUE.,/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

      return
      end subroutine
c 
c ============================================================
c 
      subroutine objf_var_UV(f1, iobjf, floc_loc)

c Update data.ecco OBJF for UV
      character*6 f1
      integer iobjf
      character*256 floc_loc  ! location (mask) of first OBJF variable

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny)
      common /grid/xc, yc, rc, bathy

c 
      character*1 pert_2, c1, c2
      integer pert_i, pert_j, pert_k
      real*4 dum3d(nx,ny,nr)
      character*256 f_command
      character*256 fmask  ! name of mask file 
      character*1 ov, m1, m0
      character*256 fdum
      logical f_exist
      character*24 fmult
      real*4 amult 

c ------
c Identify OBJF variable among the two available 
      if (iobjf.eq.5) then
         f_command = 'sed -i -e ' //
     $  '"s/barfile(' // trim(f1) //
     $ ').*/barfile(' // trim(f1) //
     $ ')=''m_horflux_vol''/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else
         write(6,*) 'iobjf is NG for objf_var_UV ... ', iobjf
         write(6,*) 'This should not happen. Aborting ...'
         stop
      endif

c ------
c Select type of spatial mask 
      ifunc = 0
      do while (ifunc.ne.1 .and. ifunc.ne.2) 
         write (6,*) 'Choose either VARIABLE at a point (1) or ',
     $        ' VARIABLE weighted in space (2) ... (1/2)?'
         read (5,*) ifunc
      end do

      write(51,"(3x,'ifunc = ',i2)") ifunc

      if (ifunc .eq. 1) then 
c When OBJF is at a point

         write(6,"(a,/)") '... OBJF will be VARIABLE at a point'
         write(51,"(3x,a,/)") ' --> OBJF is VARIABLE at a point. '

         call slct_3d_pt(pert_i,pert_j,pert_k)

         write(51,2002) pert_i,pert_j,pert_k
 2002    format(3x,'pert_i, pert_j, pert_k = ',i2,2x,i4,2x,i2)
         write(51,"(3x,a,/)") ' --> OBJF model grid location (i,j,k).'

c Select either UVEL or VVEL
         iuv = 0
         do while (iuv.ne.1 .and. iuv.ne.2) 
            write(6,*) 'Choose either U (1) or V (2) ... (1/2)?'
            read(5,*) iuv 
         end do

         write(51,'(3x,"iuv = ",i0)') iuv

         if (iuv .eq. 1) then   ! UVEL
            ov = 'U'
            m1 = 'W'
            m0 = 'S'
         else
            ov = 'V'
            m1 = 'S'
            m0 = 'W'
         endif

         write(6,*) ' ... OBJF will be ' // ov // 'VEL'
         write(51,"(3x,a,/)") ' --> OBJF will be ' // ov // 'VEL.'

c Create 3d mask 
         dum3d = 0.

         fmask='objf_' // trim(f1) // '_mask_' // m0
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) dum3d
         close(60)

         dum3d(pert_i,pert_j,pert_k) = 1. 

         fmask='objf_' // trim(f1) // '_mask_' // m1
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) dum3d
         close(60)

c Save location for naming run directory
         write(floc_loc,'(a1,"_",i9,"_",i9,"_",i9)')
     $        ov,pert_i,pert_j,pert_k
         call StripSpaces(floc_loc)

      else
c When OBJF is VARIABLE weighted in space 

         write(6,*)
     $     '... OBJF will be a linear function of selected variable'
         write(6,"(4x,a)")
     $        'i.e., MULT * SUM( MASK_W*UVEL + MASK_S*VVEL )'
         write(6,"(4x,a,/)")
     $     '!!!!! MASK_W & MASK_S must be uploaded' //
     $     ' (binary native format) before proceeding ... '

         write(51,"(3x,a)")
     $   ' --> OBJF is a linear function of selected variable(s)'
         write(51,"(3x,a,/)")
     $     ' --> i.e., MULT * SUM( MASK_W*UVEL + MASK_S*VVEL )'

c --------------------
c UVEL

c Get mask file name 
         write(6,"(3x,a)") 'Enter MASK_W filename for UVEL ... ?'  
         read(5,'(a)') fmask

         write(6,'("fmask_W = ",a)') trim(fmask)
         write(51,'(3x,"fmask_W = ",a)') trim(fmask)
         write(51,"(3x,a,/)") ' --> MASK_W file for UVEL. '

c Save mask file name for naming run directory
         floc_loc = trim(fmask)
         call StripSpaces(floc_loc)

c Check mask 
         call chk_mask3d(fmask,nx,ny,nr,dum3d)

c Link input mask to what model expects 
         fdum = 'objf_' // trim(f1) // '_mask_W' 
         INQUIRE(FILE=trim(fdum), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fdum)
            call execute_command_line(f_command, wait=.true.)
         endif

         f_command = 'ln -s ' // trim(fmask) // ' ' //
     $        trim(fdum)
         call execute_command_line(f_command, wait=.true.)

c --------------------
c VVEL

c Get mask file name 
         write(6,"(3x,a)") 'Enter MASK_S filename for VVEL ... ?'  
         read(5,'(a)') fmask

         write(6,'("fmask_S = ",a)') trim(fmask)
         write(51,'(3x,"fmask_S = ",a)') trim(fmask)
         write(51,"(3x,a,/)") ' --> MASK_S file for VVEL. '

c Check mask 
         call chk_mask3d(fmask,nx,ny,nr,dum3d)

c Link input mask to what model expects 
         fdum = 'objf_' // trim(f1) // '_mask_S' 
         INQUIRE(FILE=trim(fdum), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fdum)
            call execute_command_line(f_command, wait=.true.)
         endif

         f_command = 'ln -s ' // trim(fmask) // ' ' //
     $        trim(fdum)
         call execute_command_line(f_command, wait=.true.)

c --------------------
c Enter scaling factor
         write(6,*) 'Enter scaling factor MULT ... ?'
         read(5,*) amult

         write(6,'("amult = ",1pe12.4)') amult 
         write(51,'(3x,"amult = ",1pe12.4)') amult
         write(51,"(3x,a,/)") ' --> OBJF Scaling factor. '

         write(fmult,"(1pe12.4)") amult 
         f_command = 'sed -i -e ' //
     $  '"s/gencost(' // trim(f1) //
     $ ').*/gencost(' // trim(f1) //
     $ ')= ' // fmult // ',/g" data.ecco'
         call execute_command_line(f_command, wait=.true.)

      endif

c Specify variable is 3D      
      f_command = 'sed -i -e ' //
     $     '"s/is3d(' // trim(f1) //
     $     ').*/is3d(' // trim(f1) //
     $     ')=.TRUE.,/g" data.ecco'
      call execute_command_line(f_command, wait=.true.)

      return
      end subroutine
c 
c ============================================================
c 
      subroutine slct_2d_pt(pert_i,pert_j)
c Pick 3d model grid point 

c argument 
      integer pert_i, pert_j

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny)
      common /grid/xc, yc, rc, bathy

c local variables
      integer iloc, check_d
      real*4 pert_x, pert_y

c -------------
c Choose method of selecting point 
      write (6,*) 'Choose hotizontal location ... '
      write (6,"(3x,a)")
     $     'Enter 1 to select native grid location (i,j),  '
      write (6,"(6x,a)")
     $     'or 9 to select by longitude/latitude ... (1 or 9)? '
      read (5,*) iloc

      if (iloc .ne. 9) then 

c By native grid point 
         pert_i = 0
         pert_j = 0

         write(6,"(/,3x,a)") 'Identify point in native grid ... '
         do while (pert_i.lt.1 .or. pert_i.gt.nx) 
            write (6,"(3x,'i ... (1-',i2,') ?')") nx
            read (5,*) pert_i
         end do
         do while (pert_j.lt.1 .or. pert_j.gt.ny) 
            write (6,"(3x,'j ... (1-',i4,') ?')") ny
            read (5,*) pert_j
         end do

      else 

c By long/lat 
         check_d = 0
         write (6,"(/,3x,a)")
     $        'Enter location''s lon/lat (x,y) ... '
         do while (check_d .eq. 0) 
            write (6,"(6x,a)") 'longitude ... (E)?'
            read (5,*) pert_x

            write (6,"(6x,a)") 'latitude ... (N)?'
            read (5,*) pert_y

            call ijloc(pert_x,pert_y,pert_i,pert_j,xc,yc,nx,ny)

c Make sure point is wet      
            if (bathy(pert_i,pert_j) .le. 0.) then
               write (6,1007) pert_i,pert_j
 1007          format(/,6x,'Closest C-grid (',i2,1x,i4,') is dry.')
               write (6,"(6x,a,f7.1)") 'Depth (m)= ',
     $            bathy(pert_i,pert_j)
               write (6,"(6x,a)")'Select another point ... '
            else
               check_d = 1
            endif
         end do

      endif

c Confirm location 
      write(6,"(/,a,i2,2x,i4)")
     $     ' ...... Chosen point is (i,j) = ',pert_i,pert_j
      write(6,"(9x,a,f6.1,1x,f5.1)") 
     $    'C-grid is (long E, lat N) = ',
     $     xc(pert_i,pert_j),yc(pert_i,pert_j)
      write (6,"(6x,a,f7.1,/)") 'Depth (m)= ',
     $     bathy(pert_i,pert_j)

      return
      end subroutine 
c 
c ============================================================
c 
      subroutine slct_3d_pt(pert_i,pert_j,pert_k)
c Pick 3d model grid point 

c argument 
      integer pert_i, pert_j, pert_k

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny)
      common /grid/xc, yc, rc, bathy

c local variables
      integer iloc, k
      real*4 pert_z
      real*4 dum1d(nr), dum0
c -------------

c Choose horizontal location 
      call slct_2d_pt(pert_i,pert_j)

c Choose depth 
      write (6,*) 'Choose depth ... '
      write (6,"(3x,a)")
     $     'Enter 1 to select native vertical level (k),  '
      write (6,"(6x,a)")
     $     'or 9 to select by meters ... (1 or 9)? '
      read (5,*) iloc

      if (iloc .ne. 9) then 

c By native vertical level 
         pert_k = 0

         write(6,"(/,3x,a)")
     $        'Identify point in native vertical level ... '
         do while (pert_k.lt.1 .or. pert_k.gt.nr) 
            write (6,"(3x,'k ... (1-',i2,') ?')") nr
            read (5,*) pert_k
         end do

      else 

c By depth in meters
         write (6,"(/,3x,a)")
     $        'Enter location''s distance from surface ... (m)?'
         read (5,*) pert_z

         pert_k = 0  ! bottom wet point 
         do k=1,nr
            if (bathy(pert_i,pert_j) .gt. rc(k)) pert_k = k
         end do

         dum1d = abs(rc-pert_z)
c         idum = minloc(dum1d)
         dum0 = dum1d(1)
         idum = 1
         do k=2,pert_k
            if (dum1d(k).lt.dum0) then
               dum0=dum1d(k)
               idum = k
            endif
         end do
c         if (idum .gt. pert_k) pert_k=idum

      endif

c Confirm location 
      write(6,"(/,a,i2,2x,i4)")
     $     ' ...... closest wet level is (k) = ',pert_k
      write(6,"(9x,a,2x,i2)") 
     $    '  at depth (m) = ',rc(pert_k)

      return
      end subroutine 

