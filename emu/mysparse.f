c 
c
c ============================================================
c ============================================================
c
c 
      module mysparse
c
      implicit none 
      contains
c 
c ------------------------------------------------------------
c 
      subroutine sparse3d(msk3d,  wmag, 
     $     n_msk3d, f_msk3d, i_msk3d, j_msk3d, k_msk3d, b_msk3d)
c
c Compact storage of 3d matrix (msk3d) of elements abs() .ge. wmag. 
c Returns
c     n_msk3d: number of elements
c     i_msk3d: 1-d element index 
c     f_msk3d: value of mask element 
c     b_msk3d: for target at mask element 
c

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

      integer i,j,k
c
      real*4 msk3d(nx,ny,nr), wmag 
 
      integer n_msk3d
      real, allocatable, intent(inout) :: f_msk3d(:)
      integer, allocatable, intent(inout) :: i_msk3d(:)
      integer, allocatable, intent(inout) :: j_msk3d(:)
      integer, allocatable, intent(inout) :: k_msk3d(:)
      real, allocatable, intent(inout) :: b_msk3d(:)
c
      integer icnt, ijk 

c First count elements
      n_msk3d = 0
      do i=1,nx
         do j=1,ny
            do k=1,nr 
               if (abs(msk3d(i,j,k)).ge.wmag) n_msk3d = n_msk3d + 1
            enddo
         enddo
      enddo

c Do rest if there is valid point
      if (n_msk3d.ne.0) then 
      
      
c Allocate array for flattened elements
      allocate(f_msk3d(n_msk3d))
      allocate(i_msk3d(n_msk3d))
      allocate(j_msk3d(n_msk3d))
      allocate(k_msk3d(n_msk3d))
      allocate(b_msk3d(n_msk3d))

c     
      icnt = 0
      do i=1,nx
         do j=1,ny
            do k=1,nr
               if (abs(msk3d(i,j,k)).ge.wmag) then 
                  icnt = icnt + 1
                  f_msk3d(icnt) = msk3d(i,j,k)
                  i_msk3d(icnt) = i
                  j_msk3d(icnt) = j
                  k_msk3d(icnt) = k
               endif
            enddo
         enddo
      enddo
c
      if (icnt.ne.n_msk3d) then
         write(6,*) 'icnt ne n_msk3d ... ',icnt,n_msk3d
         stop
      endif
c
      endif     ! end case with valid points 

      return
      end subroutine sparse3d
c 
c ------------------------------------------------------------
c 
      subroutine msk_basic(msk3d, totv_inv, wmag, ipar, 
     $        n3d_v, f3d_v, i3d_v, j3d_v, k3d_v, b3d_v,
     $        n3d_x, f3d_x, i3d_x, j3d_x, k3d_x, b3d_x,
     $        n3d_y, f3d_y, i3d_y, j3d_y, k3d_y, b3d_y,
     $        n3d_z, f3d_z, i3d_z, j3d_z, k3d_z, b3d_z)

c
c Convert 3d volume mask (msk3d) to sparse mode (*_v)
c and compute volume's boundary mask in sparse mode (*_xyz)

c model arrays
      integer nx, ny, nr
      parameter (nx=90, ny=1170, nr=50)

      integer i,j,k

c Mask  
      real*4 msk3d(nx,ny,nr), totv_inv, wmag
      integer ipar

c Masks in sparse mode
c target volume
      integer n3d_v
      real, allocatable, intent(inout) :: f3d_v(:)
      integer, allocatable, intent(inout) :: i3d_v(:)
      integer, allocatable, intent(inout) :: j3d_v(:)
      integer, allocatable, intent(inout) :: k3d_v(:)
      real, allocatable, intent(inout) :: b3d_v(:)
c x-converence
      integer n3d_x
      real, allocatable, intent(inout) :: f3d_x(:)
      integer, allocatable, intent(inout) :: i3d_x(:)
      integer, allocatable, intent(inout) :: j3d_x(:)
      integer, allocatable, intent(inout) :: k3d_x(:)
      real, allocatable, intent(inout) :: b3d_x(:)
c y-converence
      integer n3d_y
      real, allocatable, intent(inout) :: f3d_y(:)
      integer, allocatable, intent(inout) :: i3d_y(:)
      integer, allocatable, intent(inout) :: j3d_y(:)
      integer, allocatable, intent(inout) :: k3d_y(:)
      real, allocatable, intent(inout) :: b3d_y(:)
c z-converence
      integer n3d_z
      real, allocatable, intent(inout) :: f3d_z(:)
      integer, allocatable, intent(inout) :: i3d_z(:)
      integer, allocatable, intent(inout) :: j3d_z(:)
      integer, allocatable, intent(inout) :: k3d_z(:)
      real, allocatable, intent(inout) :: b3d_z(:)

c model arrays
      real*4 xc(nx,ny), yc(nx,ny), rc(nr), bathy(nx,ny), ibathy(nx,ny)
      common /grid/xc, yc, rc, bathy, ibathy

      real*4 rf(nr), drf(nr), hfacc(nx,ny,nr)
      real*4 dxg(nx,ny), dyg(nx,ny), dvol3d(nx,ny,nr), rac(nx,ny)
      integer kmt(nx,ny)
      common /grid2/rf, drf, hfacc, kmt, dxg, dyg, dvol3d, rac

c Temporary array for mask 
      real*4 totv
      real*4 msk3dx(nx,ny,nr), msk3dy(nx,ny,nr)
      real*4 dum2d(nx,ny)

      character*256 file_dum

c ------------------

c Convert volume mask to sparse mode
      call sparse3d(msk3d,  wmag, 
     $     n3d_v, f3d_v, i3d_v, j3d_v, k3d_v, b3d_v)

      if (ipar.eq.1) then 
      file_dum = './emu_budg.msk3d_v'   ! "v" for volume 
      open(41,file=trim(file_dum),access='stream')
      write(41) n3d_v
      write(41) f3d_v
      write(41) i3d_v, j3d_v, k3d_v
      close(41)
      endif

c Create horizontal convergence mask 
      msk3dx(:,:,:) = 0.
      msk3dy(:,:,:) = 0.
      do k=1,nr
         call native_uv_conv_smpl_flx_msk(msk3d(:,:,k),
     $        msk3dx(:,:,k), msk3dy(:,:,k))
      enddo

      call sparse3d(msk3dx, wmag, 
     $     n3d_x, f3d_x, i3d_x, j3d_x, k3d_x, b3d_x)
      call sparse3d(msk3dy, wmag, 
     $     n3d_y, f3d_y, i3d_y, j3d_y, k3d_y, b3d_y)

      if (n3d_x .ne. 0 .and. ipar.eq.1) then 
         file_dum = './emu_budg.msk3d_x' ! "x" for convergence in x
         open(41,file=trim(file_dum),access='stream')
         write(41) n3d_x
         write(41) f3d_x
         write(41) i3d_x, j3d_x, k3d_x
         close(41)
      endif

      if (n3d_y .ne. 0 .and. ipar.eq.1) then 
         file_dum = './emu_budg.msk3d_y' ! "y" for convergence in y
         open(41,file=trim(file_dum),access='stream')
         write(41) n3d_y
         write(41) f3d_y
         write(41) i3d_y, j3d_y, k3d_y
         close(41)
      endif

c Create vertical flux convergence mask 
      msk3dy(:,:,:) = 0.  ! use as temporary storage 
      call native_w_conv_smpl_flx_msk(msk3d, msk3dy)

      call sparse3d(msk3dy, wmag, 
     $     n3d_z, f3d_z, i3d_z, j3d_z, k3d_z, b3d_z)

      if (n3d_z .ne. 0 .and. ipar.eq.1) then 
         file_dum = './emu_budg.msk3d_z' ! "z" for convergence in z
         open(41,file=trim(file_dum),access='stream')
         write(41) n3d_z
         write(41) f3d_z
         write(41) i3d_z, j3d_z, k3d_z
         close(41)
      endif

c ------------------------------------
c total volume of target 
      totv = 0.
      dum2d(:,:) = 0.
      do k=1,nr
         dum2d(:,:) = dum2d(:,:) + msk3d(:,:,k)*dvol3d(:,:,k)
      enddo
      do i=1,nx
         do j=1,ny
            totv = totv + dum2d(i,j)
         enddo
      enddo

      totv_inv = 1./totv

      return
      end subroutine msk_basic

      end module mysparse
c 
c ============================================================
c 
