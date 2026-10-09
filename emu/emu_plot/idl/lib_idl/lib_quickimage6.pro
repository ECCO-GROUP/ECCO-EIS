pro lib_quickimage6, ncol,nrow,iplt,data,dmin,dmax,title,$
	IWIN=iw,XR=xr,YR=yr,DR=dr,XTITLE=xtitle,YTITLE=ytitle,BFORM=bform
; plots the iplt'th image on a nrow, ncol page

if (iplt*ncol*nrow ne 1) then begin
   iplt2 = (iplt-1 mod (ncol*nrow)) + 1
endif else begin
   iplt2 = 1
endelse

idum = fix( (iplt2-1)/ncol) 
irow = nrow - idum
icol = iplt2 - idum*ncol

if (dmin eq dmax) then begin
   if (dmin ne 0.) then begin
      dum = minmax(abs(data),flag=1)
      dmin = -dum(1)
      dmax = dum(1)
   endif else begin 
      dum = minmax(data,flag=1)
      dmin = dum(0)
      dmax = dum(1)
   endelse
endif

;print,dmin,dmax
if (dmin eq 0 and dmax eq 0) then return

lib_quickimage4_2,data,icol,irow,ncol,nrow,dmin,dmax,title,$
	IWIN=iw,XR=xr,YR=yr,DR=dr,XTITLE=xtitle,YTITLE=ytitle,BFORM=bform

end
