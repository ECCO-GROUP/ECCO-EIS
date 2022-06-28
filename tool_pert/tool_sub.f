c Subroutines for V4r4 tools.
c
c 28 June 2022, Ichiro Fukumori (fukumori@jpl.nasa.gov)
c   StripSpaces: Remove spaces from string.
c   ijloc: Itentify native grid location (i,j) from lat/lon.
c 
c ============================================================
c 
      subroutine StripSpaces(string)
c Strip spaces from string 
      character(len=*) :: string
      integer :: stringLen 
      integer :: last, actual

      stringLen = len (string)
      last = 1
      actual = 1

      do while (actual < stringLen)
         if (string(last:last) == ' ') then
            actual = actual + 1
            string(last:last) = string(actual:actual)
            string(actual:actual) = ' '
         else
            last = last + 1
            if (actual < last) actual = last
         endif
      end do

      end subroutine
c
c ============================================================
c 
      subroutine ijloc(pert_x,pert_y,pert_i,pert_j,xc,yc,nx,ny)
c Locate closest model grid point (i,j) to given lon/lat (x,y) 
      integer :: pert_i, pert_j, nx, ny
      real*4  :: pert_x, pert_y
      real*4  :: xc(nx,ny), yc(nx,ny)
      real*4  :: dumdist, target, d2r
      integer :: i, j

c Reference (x,y) to -180 to 180 East and -90 to 90 North
c that (xc,yc) is defined 
      pert_x = modulo(pert_x,360.)
      if (pert_x .gt. 180.) pert_x = pert_x - 360.
      pert_y = modulo(pert_y,360.)
      if (pert_y .gt. 180.) pert_y = pert_y - 360.
      if (pert_y .gt. 90.)  pert_y = 180. - pert_y 
      if (pert_y .lt. -90.) pert_y = -180. - pert_y

c Find (i,j) pair within 10-degrees of (x,y)
      pert_i = -9
      pert_j = -9
      target = 9e9
      d2r = 3.1415926/180.

      do j=1,ny
         do i=1,nx
            if (abs(yc(i,j)-pert_y) .lt. 10.) then 
               dumdist = sin(pert_y*d2r)*sin(yc(i,j)*d2r) +
     $    cos(pert_y*d2r)*cos(yc(i,j)*d2r)*cos((xc(i,j)-pert_x)*d2r)
               dumdist = acos(dumdist)
               if (dumdist .lt. target) then
                  pert_i = i
                  pert_j = j
                  target = dumdist
               endif
            endif
         enddo
      enddo
      end subroutine
