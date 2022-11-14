c     Number of Generic Cost terms:
c     =============================
      INTEGER NGENCOST
      PARAMETER ( NGENCOST=40 )


      INTEGER MAX_LEN_FNAM
      PARAMETER ( MAX_LEN_FNAM = 512 )

      character*(MAX_LEN_FNAM) gencost_name(NGENCOST)
      character*(MAX_LEN_FNAM) gencost_barfile(NGENCOST)
      character*(5)            gencost_avgperiod(NGENCOST)
      character*(MAX_LEN_FNAM) gencost_mask(NGENCOST)
      real*4                   mult_gencost(NGENCOST)
      LOGICAL gencost_msk_is3d(NGENCOST)

      namelist /ecco_gencost_nml/
     &         gencost_barfile,
     &         gencost_name,
     &         gencost_mask,      
     &         gencost_avgperiod,
     &         gencost_msk_is3d,
     &         mult_gencost

c Set default
      do i=1,NGENCOST
         gencost_name(i) = 'gencost'
         gencost_barfile(i) = ' '
         gencost_avgperiod(i) = ' '
         gencost_mask(i) = ' '
         gencost_msk_is3d(i) = .FALSE. 
         mult_gencost(i) = 0.
      enddo
         

      open(70,file='data.ecco')
      read(70,nml=ecco_gencost_nml)
      close(70)

      nout = 0
      do i=1,NGENCOST
         if (gencost_name(i) .eq. 'boxmean') nout = nout + 1
      enddo

      write(6,*) 'nout = ',nout

      do i=1,nout
         write(6,*) 'iobjf = ',i
         write(6,*) 'gencost_avgperiod = ',trim(gencost_avgperiod(i))
         write(6,*) 'gencost_barfile = ',trim(gencost_barfile(i))
         write(6,*) 'gencost_mask = ',trim(gencost_mask(i))
         write(6,*) 'gencost_name = ',trim(gencost_name(i))
         write(6,*) 'gencost_msk_is3d = ',gencost_msk_is3d(i)
         write(6,*) 'mult_gencost = ',mult_gencost(i)
      enddo

      stop
      end
