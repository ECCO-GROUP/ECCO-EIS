c --------------
      if (pert_1 .eq. 'Y' .or. pert_1 .eq. 'y') then 

c OBJF is single variable at a point 

         write(6,*) '... OBJF to be a variable at a point'
         write(51,"(a,/)") ' --> OBJF is a variable at a point. '

c Select variable 
         pert_v = 0
         do while (pert_v.lt.1 .or. pert_v.gt.5)
            write (6,"(a,i2,a)") '   Enter OBJF variable ... (1-'
     $           nvar,') ?'
            read (5,*) pert_v
         end do

         write (6,"(a,a,/)") ' ..... OBJF will be of ',
     $        trim(f_var(pert_v))
         write(51,"('pert_v = ',i2)") pert_v
         write(51,2001) trim(f_var(pert_v))
 2001    format(' --> OBJF variable : ',a,/)

c Modify data.ecco according to OBJF variable
         if (pert_v .eq. 1 .or. pert_v .eq. 2) then 
            call data_update_2d(pert_v, pert_1)
         else if (pert_v .eq. 3 .or. pert_v .eq. 4) then
            call data_update_3d(pert_v, pert_1)
         else 
            call data_update_uv(pert_v, pert_1)
         endif

c Modify data.ecco according to chosen VARIABLE
      if (pert_v.eq.1) then
         f_command = 'sed -i -e '//
     $        '"s|OBJF_VAR|m_boxmean_eta_dyn|g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (pert_v.eq.2) then
         f_command = 'sed -i -e '//
     $        '"s|OBJF_VAR|m_boxmean_obp|g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (pert_v.eq.3) then
         f_command = 'sed -i -e '//
     $        '"s|OBJF_VAR|m_boxmean_THETA|g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (pert_v.eq.4) then
         f_command = 'sed -i -e '//
     $        '"s|OBJF_VAR|m_boxmean_SALT|g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      else if (pert_v.eq.5) then
         f_command = 'sed -i -e '//
     $        '"s|OBJF_VAR|m_horflux_vol|g" data.ecco'
         call execute_command_line(f_command, wait=.true.)
      endif

c Select spatial location (native grid point)
         pert_i = 0
         pert_j = 0
         pert_k = 0

         write (6,*) '   Identify point in native grid ... '
         do while (pert_i.lt.1 .or. pert_i.gt.nx) 
            write (6,"('   i ... (1-',i2,') ?')") nx
            read (5,*) pert_i
         end do
         do while (pert_j.lt.1 .or. pert_j.gt.ny) 
            write (6,"('   j ... (1-',i4,') ?')") ny
            read (5,*) pert_j
         end do

c Create spatial mask according to location 
         if (pert_v .eq. 1 .or. pert_v .eq. 2) then 

c 2D mask 
            write(6,*) ' ...... objective function is at (i,j) = ',
     $           pert_i,pert_j
            write(51,2002) pert_i,pert_j
 2002       format('pert_i, pert_j = ',i2,2x,i4)
            write(51,"(a,/)") ' --> OBJF model grid location (i,j).'

            dum2d = 0.
            dum2d(pert_i,pert_j) = 1. 

            f_command = 'sed -i -e '//
     $           '"s|OBJF_MSK|objf_mask_|g" data.ecco'
            call execute_command_line(f_command, wait=.true.)

            fmask = 'objf_mask_C'
            INQUIRE(FILE=trim(fmask), EXIST=f_exist)
            if (f_exist) then
               f_command = 'rm -f ' // trim(fmask)
               call execute_command_line(f_command, wait=.true.)
            endif
            open(60,file=fmask,form='unformatted',access='stream')
            write(60) dum2d
            close(60)

            f_command = 'sed -i -e "s|3DYES|FALSE|g" data.ecco'
            call execute_command_line(f_command, wait=.true.)

c Save location for naming run directory
            write(floc,'(i9,"_",i9)') pert_i,pert_j
            call StripSpaces(floc)

         else 

c 3D mask 
            do while (pert_k.lt.1 .or. pert_k.gt.nr) 
               write (6,"('   k ... (1-',i4,') ?')") nr
               read (5,*) pert_k
            end do
            write(6,*)
     $           ' ...... objective function is at (i,j,k) = ',
     $           pert_i,pert_j,pert_k
            write(51,2003) pert_i,pert_j,pert_k
 2003       format('pert_i, pert_j, pert_k = ',i2,2x,i4,2x,i2)
            write(51,"(a,/)") ' --> OBJF model grid location (i,j,k).'

            dum3d = 0.
            dum3d(pert_i,pert_j,pert_k) = 1. 

            if (pert_v .eq. 3 .or. pert_v .eq. 4) then 
               fmask = 'objf_mask_C'
               INQUIRE(FILE=trim(fmask), EXIST=f_exist)
               if (f_exist) then
                  f_command = 'rm -f ' // trim(fmask)
                  call execute_command_line(f_command, wait=.true.)
               endif
               open(60,file=fmask,form='unformatted',access='stream')
               write(60) dum3d
               close(60)

c Save location for naming run directory
               write(floc,'(i9,"_",i9,"_",i9)') pert_i,pert_j,pert_k
               call StripSpaces(floc)

            else
c Ask whether UVEL or VVEL
               if (pert_v .eq. 5) then ! ask if for U or V
                  iuv = 0
                  do while (iuv.ne.1 .and. iuv.ne.2) 
                     write(6,*) 'Is VARIABLE U (1) or V (2) ... (1/2)?'
                     read(5,*) iuv 
                  end do
               endif

               write(51,'("iuv = ",i0)') iuv

               if (iuv .eq. 1) then ! UVEL
                  write(6,*) ' ... OBJF will be UVEL'
                  write(51,"(a,/)") ' --> OBJF will be UVEL.'

                  fmask='objf_mask_W'
                  INQUIRE(FILE=trim(fmask), EXIST=f_exist)
                  if (f_exist) then
                     f_command = 'rm -f ' // trim(fmask)
                     call execute_command_line(f_command, wait=.true.)
                  endif
                  open(60,file=fmask,form='unformatted',access='stream')
                  write(60) dum3d
                  close(60)

                  dum3d = 0.
                  fmask='objf_mask_S'
                  INQUIRE(FILE=trim(fmask), EXIST=f_exist)
                  if (f_exist) then
                     f_command = 'rm -f ' // trim(fmask)
                     call execute_command_line(f_command, wait=.true.)
                  endif
                  open(60,file=fmask,form='unformatted',access='stream')
                  write(60) dum3d
                  close(60)

c Save location for naming run directory
                  write(floc,'("U_",i9,"_",i9,"_",i9)')
     $                 pert_i,pert_j,pert_k
                  call StripSpaces(floc)

               else  ! VVEL
                  write(6,*) ' ... OBJF will be VVEL'
                  write(51,"(a,/)") ' --> OBJF will be VVEL.'

                  fmask='objf_mask_S'
                  INQUIRE(FILE=trim(fmask), EXIST=f_exist)
                  if (f_exist) then
                     f_command = 'rm -f ' // trim(fmask)
                     call execute_command_line(f_command, wait=.true.)
                  endif
                  open(60,file=fmask,form='unformatted',access='stream')
                  write(60) dum3d
                  close(60)

                  dum3d = 0.
                  fmask='objf_mask_W'
                  INQUIRE(FILE=trim(fmask), EXIST=f_exist)
                  if (f_exist) then
                     f_command = 'rm -f ' // trim(fmask)
                     call execute_command_line(f_command, wait=.true.)
                  endif
                  open(60,file=fmask,form='unformatted',access='stream')
                  write(60) dum3d
                  close(60)

c Save location for naming run directory
                  write(floc,'("V_",i9,"_",i9,"_",i9)')
     $                 pert_i,pert_j,pert_k
                  call StripSpaces(floc)

               endif  ! U or V 
            endif  ! TS or UV 
            f_command = 'sed -i -e "s|3DYES|TRUE|g" data.ecco'
            call execute_command_line(f_command, wait=.true.)
         endif

         write(6,1004) 
     $        '        C-grid is (long E, lat N) = ',
     $        xc(pert_i,pert_j),yc(pert_i,pert_j)
 1004    format(a,1x,f6.1,1x,f5.1)
         write(6,1005) 
     $        '        Depth (m) = ',
     $        bathy(pert_i,pert_j)
 1005    format(a,1x,f7.1)
         write (6,*) 

c --------------
a      else  ! pert_1 .ne. 'Y' 

c OBJF is not a single variable at a point 

         write(6,*)
         '... OBJF to be a linear function of selected variable(s)'
         write(6,"(a)")
     $     '... i.e., OBJF will be SUM_i( MASK_i * VARIABLE_i )'
         write(6,"(a,/)") '... Upload all MASK_i ' //
     $     ' (binary native format) before proceeding ... '

         write(51,"(a)")
     $   ' --> OBJF is a linear function of selected variable(s)'
         write(51,"(a,/)")
     $     ' --> i.e., OBJF will be SUM_i( MASK_i * VARIABLE_i )'

c Loop among variables 
         pert_v = 1  ! count OBJF variables
         do i=1,nvar
            write(6,"(a,a,a)") 'Is ',trim(f_var(i)),
     $           ' an OBJF variable ... (Y/N)'
            read(5,*) pert_2 

            if (pert_2 .eq. 'Y' .or. pert_2 .eq. 'y') then 
               if (pert_v .ne. 1) then 
c Duplicate namelist entries for this additional variable 
                  write(c1,"(i1)") pert_v - 1 ! previous variable 
                  write(c2,"(i1)") pert_v  ! current new variable 
                  
         s_command = '/(' // c1 // ')/{p;s|(' //
     $                 c1 // ')|(' // c2 // ')|}'
         f_command = 'sed -i -e "' // s_command // '" data.ecco'
                  call execute_command_line(f_command, wait=.true.)
               endif
c Set variable name 

               
               pert_v = pert_v + 1


         pert_v = 0
         do while (pert_v.lt.1 .or. pert_v.gt.5)
            write (6,"(a,i2,a)")
     $  '   Enter number of variables for OBJF... (1-'
     $           nvar,') ?'
            read (5,*) pert_v
         end do

c Specifying kernel for obj function 
         if (pert_v .ne. 5) then 
            write(6,*)
     $  '... objective function will be SUM( MASK*VARIABLE )'
            write(51,"(a,/)") ' --> OBJF is SUM( MASK*VARIABLE )'
            write(6,*)
            write(6,*)
     $  'Upload MASK (binary native format) before proceeding ... '
            write(6,*)
            write(6,*) '   Enter MASK filename ... ?'  
            read(5,'(a)') fmask
            write(51,'("fmask = ",a)') trim(fmask)
            write(51,"(a,/)") ' --> MASK file. '
c Check mask 
            if (pert_v .eq. 1 .or. pert_v .eq. 2) then 
               call chk_mask2d(fmask,nx,ny,dum2d)
               f_command = 'sed -i -e "s|3DYES|FALSE|g" data.ecco'
               call execute_command_line(f_command, wait=.true.)
            else
               call chk_mask3d(fmask,nx,ny,nr,dum3d)
               f_command = 'sed -i -e "s|3DYES|TRUE|g" data.ecco'
               call execute_command_line(f_command, wait=.true.)
            endif

            INQUIRE(FILE='objf_mask_C', EXIST=f_exist)
            if (f_exist) then
               f_command = 'rm -f objf_mask_C'
               call execute_command_line(f_command, wait=.true.)
            endif

            f_command = 'ln -s ' // trim(fmask) 
     $           // ' objf_mask_C'
            call execute_command_line(f_command, wait=.true.)

c Save mask name for naming run directory
            floc = trim(fmask)
            call StripSpaces(floc)

         else
            write(6,*)
     $  '... OBJF to be SUM( MASK_W*UVEL + MASK_S*VVEL )'
            write(51,"(a,/)")
     $           ' --> OBJF is SUM( MASK_W*UVEL + MASK_S*VVEL )'
            write(6,*)
            write(6,*) 'Upload MASK_W, MASK_S before proceeding ... '
            write(6,*) '(binary native format)' 

            write(6,*)
            write(6,*) '   Enter MASK_W filename ... ?'  
            read(5,'(a)') fmask
            write(51,'("fmask = ",a)') trim(fmask)
            write(51,"(a,/)") ' --> MASK_W file. '

            call chk_mask3d(fmask,nx,ny,nr,dum3d)

            INQUIRE(FILE='objf_mask_W', EXIST=f_exist)
            if (f_exist) then
               f_command = 'rm -f objf_mask_W'
               call execute_command_line(f_command, wait=.true.)
            endif

            f_command = 'ln -s ' // trim(fmask) 
     $           // ' objf_mask_W'
            call execute_command_line(f_command, wait=.true.)

c Save mask name for naming run directory
            floc = trim(fmask)
            call StripSpaces(floc)
            
            write(6,*)
            write(6,*) '   Enter MASK_S filename ... ?'  
            read(5,'(a)') fmask
            write(51,'("fmask = ",a)') trim(fmask)
            write(51,"(a,/)") ' --> MASK_S file. '

            call chk_mask3d(fmask,nx,ny,nr,dum3d)

            INQUIRE(FILE='objf_mask_S', EXIST=f_exist)
            if (f_exist) then
               f_command = 'rm -f objf_mask_S'
               call execute_command_line(f_command, wait=.true.)
            endif

            f_command = 'ln -s ' // trim(fmask) 
     $           // ' objf_mask_S'
            call execute_command_line(f_command, wait=.true.)

            f_command = 'sed -i -e "s|3DYES|TRUE|g" data.ecco'
            call execute_command_line(f_command, wait=.true.)

c Save mask name for naming run directory
            floc = trim(floc) // '_' // trim(fmask)
            call StripSpaces(floc)

         endif
      endif
         
c --------------
c Define OBJF's TIME 
      write(6,*) 
      write(6,*) 'VARIABLE at what time?  Choose among ... '
c      write(6,*) '   ... particular instant (Hour), or '
c      write(6,*) '   ... average over Day, Month, or Year '
      write(6,*) '   ... average over Month (m), Year (y)'
      write(6,*)
     $     '   ... or over entire model integration Period (p)'
      write(6,*) '   (NOTE: Controls are weekly averages.) '
      write(6,*) 
      
      atime = 'x' 
c      do while (atime.ne.'H' .and. atime.ne.'h' .and.
c     $       atime.ne.'D' .and. atime.ne.'d' .and.
c     $       atime.ne.'M' .and. atime.ne.'m' .and.
      do while (atime.ne.'M' .and. atime.ne.'m' .and.
     $       atime.ne.'Y' .and. atime.ne.'y' .and.
     $       atime.ne.'P' .and. atime.ne.'p' ) 
c         write(6,*) '... Enter h/d/m/y/p ?'
         write(6,*) '... Enter m/y/p ?'
         read(5,'(a)') atime
      enddo

      write(51,'("atime = ",a)') trim(atime)
      write(51,"(a,/)") ' --> OBJF temporal scheme. '

      write(6,*) 'V4r4 integrates from ' //
     $     '1/1/1992 12Z to 12/31/2017 12Z'

c Particular step (Hour)
      if (atime.eq.'H' .or. atime.eq.'h') then 
        write(6,1100) nsteps
 1100   format('over ',i0,' steps (1-hour time-steps)')
        itarget = 0
        do while (itarget.lt.1 .or. itarget.gt.nsteps) 
           write(6,1101) nsteps
 1101      format('Enter OBJF time-step ... (1-',i0,')?')
           read(5,*) itarget 
        enddo

        write(51,'("itarget = ",i0)') itarget 
        write(51,2004) nsteps
 2004   format(' --> OBJF time-step among (1-',i0,')',/)

        tmask = 0.
        tmask(itarget) = 1.

        fmask='objf_mask_T'
        INQUIRE(FILE=trim(fmask), EXIST=f_exist)
        if (f_exist) then
           f_command = 'rm -f ' // trim(fmask)
           call execute_command_line(f_command, wait=.true.)
        endif
        open(60,file=fmask,form='unformatted',access='stream')
        write(60) tmask
        close(60)
        f_command = 'sed -i -e "s|OBJF_PRD|step|g" data.ecco'
        call execute_command_line(f_command, wait=.true.)

c set nTimesteps in data to 1-week beyond itarget
c     to make sure computation is complete,.
         nTimesteps = itarget + 7*24
         if (nTimesteps .gt. nsteps) nTimesteps=nsteps

c Particular day
      elseif (atime.eq.'D' .or. atime.eq.'d') then 
         write(6,*) 'over 9497 days'
         itarget = 0
         do while (itarget.lt.1 .or. itarget.gt.9497) 
            write(6,*) 'Enter OBJF day ... (1-9497)?'
            read(5,*) itarget 
         enddo

         write(51,'("itarget = ",i0)') itarget 
         write(51,"(a,/)")
     $        ' --> OBJF day among (1-9497)'

         tmask = 0.
         tmask(itarget) = 1.

         fmask='objf_mask_T'
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) tmask(1:9497)
         close(60)

         f_command = 'sed -i -e "s|OBJF_PRD|day|g" data.ecco'
         call execute_command_line(f_command, wait=.true.)

c set nTimesteps in data to 1-week beyond itarget
c     to make sure computation is complete,.
         nTimesteps = itarget*24 + 7*24
         if (nTimesteps .gt. nsteps) nTimesteps=nsteps

c Particular month
      elseif (atime.eq.'M' .or. atime.eq.'m') then 
         write(6,*) 'over 312 months'
         itarget = 0
         do while (itarget.lt.1 .or. itarget.gt.312) 
            write(6,*) 'Enter OBJF month ... (1-312)?'
            read(5,*) itarget 
         enddo

         write(51,'("itarget = ",i0)') itarget 
         write(51,"(a,/)")
     $        ' --> OBJF month among (1-312).'

         tmask = 0.
         tmask(itarget) = 1.

         fmask='objf_mask_T'
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) tmask(1:312)
         close(60)

         f_command = 'sed -i -e "s|OBJF_PRD|month|g" data.ecco'
         call execute_command_line(f_command, wait=.true.)

c set nTimesteps in data to 1-month beyond itarget
c     to make sure computation is complete,.
         nTimesteps = (itarget/12)*365*24 +
     $        mod(itarget,12)*30*24 + 30*24*1
         if (nTimesteps .gt. nsteps) nTimesteps=nsteps

c Particular year 
      elseif (atime.eq.'Y' .or. atime.eq.'y') then 
         write(6,*) 'over 26 years'
         itarget = 0
         do while (itarget.lt.1 .or. itarget.gt.26) 
            write(6,*) 'Enter OBJF year ... (1-26)?'
            read(5,*) itarget 
         enddo

         write(51,'("itarget = ",i0)') itarget 
         write(51,"(a,/)")
     $        ' --> OBJF year among (1-26).'

         itarget2 = (itarget-1)*12 + 1 
         tmask = 0.
         tmask(itarget2:itarget2+11) = 1./12.

         fmask='objf_mask_T'
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) tmask(1:312)
         close(60)

         f_command = 'sed -i -e "s|OBJF_PRD|month|g" data.ecco'
         call execute_command_line(f_command, wait=.true.)

c set nTimesteps in data to 1-month beyond itarget
c     to make sure computation is complete,.
         nTimesteps = itarget*365*24 + 30*24*1
         if (nTimesteps .gt. nsteps) nTimesteps=nsteps

c Average over integration period
      elseif (atime.eq.'P' .or. atime.eq.'p') then 
         write(6,*)
     $        'OBJF will be averaging over this entire period'
         write(51,"(a,/)")
     $        ' --> OBJF over entire V4r4 period.'

         itarget = 1
         tmask = 0.
         tmask(itarget) = 1.

         fmask='objf_mask_T'
         INQUIRE(FILE=trim(fmask), EXIST=f_exist)
         if (f_exist) then
            f_command = 'rm -f ' // trim(fmask)
            call execute_command_line(f_command, wait=.true.)
         endif
         open(60,file=fmask,form='unformatted',access='stream')
         write(60) tmask(1:312)
         close(60)

         f_command = 'sed -i -e "s|OBJF_PRD|const|g" data.ecco'
         call execute_command_line(f_command, wait=.true.)

c set nTimesteps in data to entire V4r4 period (26-years)
         nTimesteps = nsteps

      endif

      close(51)
      write(6,*)
      write(6,*) 'Wrote ',trim(file_out)

c Specify length of integration in data and pbs_ad.csh 
      f_command = 'cp -f data_emu data'
      call execute_command_line(f_command, wait=.true.)

      write(fstep,'(i24)') nTimesteps
      call StripSpaces(fstep)
      f_command = 'sed -i -e "s|NSTEP_EMU|'//
     $     trim(fstep) //'|g" data'
      call execute_command_line(f_command, wait=.true.)

      f_command = 'cp -f pbs_ad.csh_orig pbs_ad.csh'
      call execute_command_line(f_command, wait=.true.)

      nHours = ceiling(float(nTimesteps)/float(nsteps)
     $     *float(hour26yr))
      write(fstep,'(i24)') nHours
      call StripSpaces(fstep)
      f_command = 'sed -i -e "s|WHOURS_EMU|'//
     $     trim(fstep) //'|g" pbs_ad.csh'
      call execute_command_line(f_command, wait=.true.)

      if (nHours .le. 2) then 
         f_command = 'sed -i -e "s|CHOOSE_DEVEL|'//
     $        'PBS -q devel|g" pbs_ad.csh'
         call execute_command_line(f_command, wait=.true.)
      endif

c Create concatenated string for naming run directory
      write(f_command,1001) pert_v, trim(atime), itarget, trim(floc)
 1001 format(i9,"_",a1,"_",i9,"_",a)
      call StripSpaces(f_command)

      file_out = 'ad_objf.str'
      open (50, file=file_out, action='write')
      write(50,'(a)') trim(f_command)
      close(50)

      write(6,*) 'Wrote ',trim(file_out)