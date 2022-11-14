      subroutine samp_day(objf, mobjf, nrec)
c Sample daily mean state

      external StripSpaces
c files
      character*130 file_in, file_out  ! file names 

      logical f_exist

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny)
      common /grid/xc, yc, rc, bathy

c Objective function 
      integer nvar    ! number of OBJF variables 
      parameter (nvar=5)    
      character*72 f_var(nvar), f_unit(nvar)

c
      character*256 f_command

c Strings for naming output directory
      character*256 floc_time ! OBJF time-period
      character*256 floc_var  ! first variable defined as OBJF 
      character*256 floc_loc  ! location (mask) of first OBJF variable

c --------------
c Define OBJF's VARIABLE 

      write(6,"(/,a)") 'Sampling monthly means ... '
      write(51,"(/,a)") 'Sampling monthly means ... '
      
      nobjf = 0 ! number of OBJF variables 
      iobjf = 1
      write(f1,"(i1)") 1 
      call StripSpaces(f1)

      do while (iobjf .ge. 1 .and. iobjf .le. nvar) 

         write (6,"(/,a)") '------------------'
         write (6,"(3x,a,i1,a,i1,a)")
     $     'Choose OBFJ variable # ',nobjf+1,' ... (1-',nvar,')?'
         write(6,"(3x,a)") '(Enter 0 to end variable selection)'

         read (5,*) iobjf

         if (iobjf.ne.0) then 
c Process OBJF variable 
         nobjf = nobjf + 1

         write(6,"(3x,a,i2,1x,a,a)") 'OBJF variable ',
     $        nobjf, 'is ',trim(f_var(iobjf))

         write(51,"(/,a)") '------------------'
         write(51,"(a,i2,a,a)") 'OBJF variable # ',nobjf
         write(51,"(3x,'iobjf = ',i2)") iobjf
         write(51,"(3x,a,a,/)")
     $        ' --> OBJF variable : ', trim(f_var(iobjf))

c Create data.ecco entries for new variable, if not the first
         if (nobjf .eq. 1) then 
            write(floc_var,"(i2)") iobjf
            call StripSpaces(floc_var)
         endif

c Define new OBJF variable 
         call obj_var(f1,iobjf,floc_loc)

         endif 

      end do 

c Extract OBJF  
      call samp_mon_objf(objf, mobjf, nrec)

      return 
      end subroutine 
      
