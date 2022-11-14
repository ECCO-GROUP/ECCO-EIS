      subroutine samp_mon(objf, mobjf, nrec)
c Sample monthly mean state

c
      real*4 objf(*)
      real*4 mobjf
      integer nrec

      external StripSpaces

c Objective function 
      integer nvar    ! number of OBJF variables 
      parameter (nvar=5)    
      character*72 f_var(nvar), f_unit(nvar)
      common /objfvar/f_var, f_unit

c Strings for naming output directory
      character*256 floc_time ! OBJF time-period
      character*256 floc_var  ! first variable defined as OBJF 
      character*256 floc_loc  ! location (mask) of first OBJF variable
      common /floc/floc_time, floc_var, floc_loc

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
      
