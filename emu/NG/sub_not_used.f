c 
c ============================================================
c 
      subroutine objf_time_myp

c Alternate version of objf_time. Also allows specifying OBJF
c time-period of a particular calendar year or a particular month.
c Subroutine objf_time simplifies the choice that achieves the same by
c just adopting the "period" option in this routine. 

c Specifiy OBJF in time; Output temporal mask (weight) and set
c model integration time accordingly in files data and pbs_ad.csh. 
c
c For this version of the ECCO Modeling Utility, OBJF will be
c restricted to being a function of monthly averages; i.e., 
c      gencost_avgperiod(*)='month'
c

c V4r4 specific 
      integer nsteps, nyears, nmonths, whours
      parameter(nsteps=227903) ! max number of steps of V4r4
      parameter(nyears=26)  ! max number of years of V4r4
      parameter(nmonths=312) ! max number of months of V4r4
      parameter(whours=108) ! wallclock hours for nsteps of adjoint 

      integer mdays(12)
      data mdays/31,28,31,30,31,30,31,31,30,31,30,31/
      integer adays(nmonths) ! # of days of each of the 312 months 
      integer adays2(12,nyears)
      equivalence (adays, adays2)

      real*4 tmask(nmonths), tdum 
      character*256 fmask
      logical f_exist

c Other variables 
      character*1   atime
      character*128 atime_desc

      integer itarget, ndays
      integer itarget2, i

      integer nTimesteps, nHours
      character*24 fstep

      character*256 f_command

c ---------
c Assign number of days in each month
      do i=1,nyears
         adays2(:,i) = mdays(i)
      enddo
      
      do i=1,nyears,4   ! leap year starting from first (1992)
         adays2(2,i) = 29
      enddo      

c ---------
c Select OBJF time period 
      write(6,"(/,3x,a)") 'V4r4 can integrate from ' //
     $     '1/1/1992 12Z to 12/31/2017 12Z'
      write(6,"(7x,a,/)") 'which is 26-years (312-months).'

      write(6,"(/,3x,a)") 'Select OBJF time-period among ... '
      write(6,"(3x,a)")
     $     '... a particular MONTH (m), a particular YEAR (y)'
      write(6,"(3x,a,/)") '... or another PERIOD (p)'
      write(6,"(a,/)") '(NOTE: Controls are weekly averages.) '

      atime = 'x' 
      do while (atime.ne.'M' .and. atime.ne.'m' .and.
     $       atime.ne.'Y' .and. atime.ne.'y' .and.
     $       atime.ne.'P' .and. atime.ne.'p' ) 
         write(6,*) '... Enter (m/y/p) ?'
         read(5,'(a)') atime
      enddo

      if (atime .eq. 'M' .or. atime .eq. 'm') then 
         atime_desc =  'a month'
      else if (atime .eq. 'Y' .or. atime .eq. 'y') then 
         atime_desc =  'a year'
      else
         atime_desc =  'a period'
      endif

      write(6,"(3x,a,a,/)") 'OBJF time-period will be '
     $     , trim(atime_desc)

      write(51,'("atime = ",a)') trim(atime)
      write(51,"(a,a,/)") ' --> OBJF time-period is '
     $     , trim(atime_desc)

c ----------------------- For different OBJF time periods  
c For a particular MONTH
      if (atime.eq.'M' .or. atime.eq.'m') then 
         itarget = 0
         do while (itarget.lt.1 .or. itarget.gt.312) 
            write(6,*) 'Enter OBJF month ... (1-312)?'
            read(5,*) itarget 
         enddo

         write(6,"(a,i0)") 'MONTH = ',itarget
         write(51,'("itarget = ",i0)') itarget 
         write(51,"(a,/)")
     $        ' --> OBJF month among (1-312).'

c Set mask 
         tmask = 0.
         tmask(itarget) = 1.

c Set model integration time steps (nTimesteps)
         ndays = sum(adays(1:itarget))
         nTimesteps = ndays*24
         if (nTimesteps .gt. nsteps) nTimesteps=nsteps

c -----------------------
c For a particular YEAR 
      elseif (atime.eq.'Y' .or. atime.eq.'y') then 
         itarget = 0
         do while (itarget.lt.1 .or. itarget.gt.26) 
            write(6,*) 'Enter OBJF year ... (1-26)?'
            read(5,*) itarget 
         enddo

         write(6,"(a,i0)") 'YEAR = ',itarget
         write(51,'("itarget = ",i0)') itarget 
         write(51,"(a,/)")
     $        ' --> OBJF year among (1-26).'

c Set mask 
         itarget2 = (itarget-1)*12 + 1 
         tmask = 0.
         tmask(itarget2:itarget2+11) = 1.

c Set model integration time steps (nTimesteps).
         ndays = sum(adays(1:itarget2+11))
         nTimesteps = ndays*24
         if (nTimesteps .gt. nsteps) nTimesteps=nsteps

c -----------------------
c For another period
      elseif (atime.eq.'P' .or. atime.eq.'p') then 
         itarget  = 0
         itarget2 = 0
         do while (itarget.lt.1 .or. itarget.gt.312 .or. 
     $        itarget2.lt.1 .or. itarget2.gt.312 .or.
     $        itarget2.lt.itarget) 
            write(6,*) 'Enter first month of OBJF period ... (1-312)?'
            read(5,*) itarget 
            write(6,*) 'Enter last month of OBJF period ... (1-312)?'
            read(5,*) itarget2
         enddo

         write(6,"(a,i0,1x,i0)") 'PERIOD start & end months = ',
     $        itarget,itarget2
         write(51,'("itarget, itarget2 = ",i0,1x,i0)')
     $        itarget,itarget2
         write(51,"(a,/)")
     $        ' --> OBJF start & end months (1-312).'

c Set mask 
         tmask = 0.
         tmask(itarget:itarget2) = 1.

c Set model integration time steps (nTimesteps).
         ndays = sum(adays(1:itarget2))
         nTimesteps = ndays*24
         if (nTimesteps .gt. nsteps) nTimesteps=nsteps

      endif

c ----------------------- END different OBJF time periods  

c Convert tmask to weight
      tmask = tmask * adays
      tdum = sum(tmask) 
      tmask = tmask/tdum

c Output temporal mask (weight)
      fmask='objf_mask_T'
      INQUIRE(FILE=trim(fmask), EXIST=f_exist)
      if (f_exist) then
         f_command = 'rm -f ' // trim(fmask)
         call execute_command_line(f_command, wait=.true.)
      endif
      open(60,file=fmask,form='unformatted',access='stream')
      write(60) tmask
      close(60)

c ----------------
c Set integration time/period in data and pbs_ad.csh 
c (data.ecco to be set in main routine.) 

c File data 
      f_command = 'cp -f data_emu data'
      call execute_command_line(f_command, wait=.true.)

      write(fstep,'(i24)') nTimesteps
      call StripSpaces(fstep)
      f_command = 'sed -i -e "s|NSTEP_EMU|'//
     $     trim(fstep) //'|g" data'
      call execute_command_line(f_command, wait=.true.)

c File pbs_ad.csh
      f_command = 'cp -f pbs_ad.csh_orig pbs_ad.csh'
      call execute_command_line(f_command, wait=.true.)

      nHours = ceiling(float(nTimesteps)/float(nsteps)
     $     *float(whours))
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

c 
      write(6,"(/,a,/)") '... Program has set computation periods '
     $    // 'in files data and pbs_ad.csh accordingly.'

      return
      end subroutine 
