      program pert_nml
c -----------------------------------------------------
c Program for Perturbation Tool (V4r4)
c
c Create namelist (pert_xx.nml) for pert_xx.f
c 
c Example input: 
c     Perturb EMPMR at (85,601) at week 5
c     using default perturbation magnitude. 
c 
c     1
c     1 
c     85
c     601
c     5
c     1
c
c 28 June 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c -----------------------------------------------------
      external StripSpaces

c Perturbation (perturbation variable, location, time, amplitude)
      integer pert_v, pert_i, pert_j, pert_t
      real*4 pert_a, pert_x, pert_y
      namelist /PERT_SPEC/ pert_v, pert_i, pert_j, pert_t, pert_a

      integer check_v, check_i, check_j, check_t, check_a

c 
      integer nctrl                    ! number of controls 
      parameter (nctrl=8) 
      character*130 file_in, file_out  ! file names 
      logical file_exists
      character*72 f_xx(nctrl), f_xx_unit(nctrl)
      character*256 f_command
      
      integer nx, ny, nwk 
      parameter (nx=90, ny=1170, nr=50, nwk=1358)
      real*4 scale(nx,ny)              ! default perturbation

      real*4 xc(nx,ny), yc(nx,ny), bathy(nx,ny)
      integer iloc

      integer i

c --------------
c Read model grid
      file_in = 'pert_xx.grid'
      open (50, file=file_in, action='read', access='direct',
     $     recl=nx*ny*4, form='unformatted')
      read (50,rec=1) xc
      read (50,rec=2) yc
      read (50,rec=3) bathy
      close (50)
      
c --------------
c xx variable name, unit and description
      f_xx(1) = 'empmr'
      f_xx(2) = 'pload'   
      f_xx(3) = 'qnet'    
      f_xx(4) = 'qsw'     
      f_xx(5) = 'saltflux'
      f_xx(6) = 'spflx'   
      f_xx(7) = 'tauu'    
      f_xx(8) = 'tauv'    

      f_xx_unit(1) = 'kg/m2/s (upward freshwater flux)'
      f_xx_unit(2) = 'N/m2 (downward surface pressure loading)'
      f_xx_unit(3) = 'W/m2 (net upward heat flux)'
      f_xx_unit(4) = 'W/m2 (net upward shortwave radiation)'     
      f_xx_unit(5) = 'g/m2/s (net upward salt flux)'
      f_xx_unit(6) = 'g/m2/s (net downward salt plume flux)'
      f_xx_unit(7) = 'N/m2 (westward wind stress)'     
      f_xx_unit(8) = 'N/m2 (southward wind stress)'     

c --------------
c Interactive specification of perturbation 

c control variable 
      check_v = 0

      write (6,*) 'Available control variables to perturb ... '
      do i=1,nctrl
         write (6,"('   ',i2,') ',a)") i,trim(f_xx(i))
      enddo
      do while (check_v .eq. 0) 
         write (6,"('   Enter control ... (1-',i2,') ?')") nctrl
         read (5,*) pert_v
         if (pert_v .ge. 1 .and. pert_v .le. nctrl) check_v = 1
      end do
      write (6,*) ' ..... perturbing ',trim(f_xx(pert_v))
      write (6,*) 


c Select spatial location (native or lat/lon)
      write (6,*) 'Choose location for perturbation ... '
      write (6,*) '   Enter 1 to choose native grid location (i,j),  '
      write (6,*)
     $     '         9 to select by longitude/latitude ... (1 or 9)? '
      read (5,*) iloc

      if (iloc .ne. 9) then 

c spatial location (native grid point)
      check_i = 0
      check_j = 0

      write (6,*) '   Enter native (i,j) grid to perturb ... '
      do while (check_i .eq. 0) 
         write (6,"('   i ... (1-',i2,') ?')") nx
         read (5,*) pert_i
         if (pert_i .ge. 1 .and. pert_i .le. nx) check_i = 1
      end do
      do while (check_j .eq. 0) 
         write (6,"('   j ... (1-',i4,') ?')") ny
         read (5,*) pert_j
         if (pert_j .ge. 1 .and. pert_j .le. ny) check_j = 1
      end do

      else 

         check_i = 0
         write (6,*) '   Enter lon/lat (x,y) grid to perturb ... '
         do while (check_i .eq. 0) 
            write (6,*) '   longitude ... (E)?'
            read (5,*) pert_x

            write (6,*) '   latitude ... (N)?'
            read (5,*) pert_y

            call ijloc(pert_x,pert_y,pert_i,pert_j,xc,yc,nx,ny)

            if (bathy(pert_i,pert_j) .le. 0.) then
               write (6,1007) pert_i,pert_j
 1007          format('   Closest (i,j) is (',i2,1x,i4,')')
               write (6,1006) '   C-grid point is dry. Depth (m)= ',
     $              bathy(pert_i,pert_j)
 1006          format(a,f7.1,' Try again.')
            else
               check_i = 1
            endif
         end do
      endif

      write(6,*) ' ...... perturbation at (i,j) = ',pert_i,pert_j
      write(6,1004) 
     $           '        which is (long E, lat N) = ',
     $     xc(pert_i,pert_j),yc(pert_i,pert_j)
 1004 format(a,1x,f6.1,1x,f5.1)
      write(6,1005) 
     $           '        Depth (m) at this location = ',
     $     bathy(pert_i,pert_j)
 1005 format(a,1x,f7.1)
      write (6,*) 

c time (week)
      check_t = 0
      do while (check_t .eq. 0) 
         write (6,"('Enter week to perturb ... (1-',i4,') ?')") nwk 
         read (5,*) pert_t
         if (pert_t .ge. 1 .and. pert_t .le. nwk) check_t = 1
      end do
      write(6,*) ' ...... perturbing week = ',pert_t
      write (6,*) 

c amplitude
      file_in = 'pert_xx.scale'
      inquire (file=trim(file_in), EXIST=file_exists)
      if (.not. file_exists) then
         write (6,*) ' **** Error: default perturbation scale file = ',
     $        trim(file_in) 
         write (6,*) '**** does not exist'
         stop
      endif
      
      open (50, file=file_in, action='read', access='direct',
     $     recl=nx*ny*4, form='unformatted')
      read (50,rec=pert_v) scale
      close (50)

      pert_a = scale(pert_i,pert_j)
      write(6,"(a,1x,e12.4)") 'Default perturbation = ',pert_a
      write(6,"(8x,'in unit ',a)") f_xx_unit(pert_v)

      write (6,*) 'Enter 1 to keep, 9 to change ... ?'
      read (5,*) check_a
      if (check_a .eq. 9) then 
         write (6,*) '   Enter perturbation magnitude ... ?'
         read (5,*) pert_a
      endif

c --------------
c Output Perturbation specification to namelist file

      file_out = 'pert_xx.nml'

c      inquire (file=trim(file_out), EXIST=file_exists)
c      if (file_exists) then
c         write (6,*) ' **** Error: namelist file = ',
c     $        trim(file_out) 
c         write (6,*) '**** already exists'
c         stop
c      endif

      open (50, file=file_out, action='write')
      write(50, nml=PERT_SPEC) 
      close (50)

      write (6,*) 'Wrote ',trim(file_out)

c Also create concatenated string for creating run director
      if (pert_a .ne. 0.) then 
         write(f_command,1001) pert_v, pert_i, pert_j, pert_t, pert_a
 1001    format(i9,"_",i9,"_",i9,"_",i9,"_",1p e12.2)
      else 
         write(f_command,'(a)') 'ref'
      endif
      call StripSpaces(f_command)

      file_out = 'pert_xx.str'
      open (50, file=file_out, action='write')
      write(50,'(a)') trim(f_command)
      close(50)

      write (6,*) 'Wrote ',trim(file_out)

      stop
      end
