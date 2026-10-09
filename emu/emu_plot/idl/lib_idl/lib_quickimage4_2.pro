pro lib_quickimage4_2, data, ix, iy, nx, ny, mind, maxd, title,$
	IWIN=iw,XR=xr,YR=yr,DR=dr,XTITLE=xtitle,YTITLE=ytitle,BFORM=bform
; Multi plot version of quickimage
;
; plots color image with color bar
; .run xwinvz beforehand
;
s=size(data)
maxs=max(s(1:2))
minb = mind
maxb = maxd
barticinc = (maxb-minb)/2
  xlo=1. & xhi=s(1)+1 & xticinc=s(1)/10. 
  ylo=1. & yhi=s(2)+1 & yticinc=s(2)/10. 

if (n_elements(bform) eq 0) then bform='(e12.1)'
;

!p.multi=[0,1,1]

if(n_elements(iw) eq 0) then iw=1
iwin2=-iw
if (ix eq 1 and iy eq ny) then iwin2=iw

if (n_elements(xr) ne 0) then begin 
if(n_elements(xr) gt 3) then begin
   print,' quickimage4_2 : Too many elements in XR '
   return
endif else begin
if (n_elements(xr) eq 1) then begin
  xlo=1. & xhi=s(1)+1 & xticinc=s(1)/10. 
endif
if (n_elements(xr) eq 2) then begin
  xlo=xr(0) & xhi=xr(1) & xticinc=(xhi-xlo)/5.
end
if (n_elements(xr) eq 3) then begin
  xlo=xr(0) & xhi=xr(1) & xticinc=xr(2)
endif
endelse
endif

if (n_elements(yr) ne 0) then begin 
if(n_elements(yr) gt 3) then begin
   print,' quickimage4_2 : Too many elements in YR '
   return
endif else begin
if (n_elements(yr) eq 1) then begin
  ylo=1. & yhi=s(1)+1 & yticinc=s(1)/10. 
endif
if (n_elements(yr) eq 2) then begin
  ylo=yr(0) & yhi=yr(1) & yticinc=(yhi-ylo)/5.
end
if (n_elements(yr) eq 3) then begin
  ylo=yr(0) & yhi=yr(1) & yticinc=yr(2)
endif
endelse
endif

if (n_elements(dr) ne 0) then begin 
if(n_elements(dr) gt 3) then begin
   print,' quickimage4_2 : Too many elements in DR '
   return
endif else begin
if (n_elements(dr) le 1) then begin
  minb=dr(0) & maxb=maxd & barticinc=(maxb-minb)/2. 
endif
if (n_elements(dr) eq 2) then begin
  minb=dr(0) & maxb=dr(1) & barticinc=(maxb-minb)/2.
end
if (n_elements(dr) eq 3) then begin
  minb=dr(0) & maxb=dr(1) & barticinc=dr(2)
endif
endelse
endif

;print,'xlo,xyi,xtincinc = ',xlo,xhi,xticinc
;print,'minb,maxb,barticinc',minb,maxb,barticinc
print,'mind,maxd',mind,maxd

DATIMAGE, DATA,  $
;           XWIN=750*s(1)/maxs, YWIN=750*s(2)/maxs, WIN=0, $
           XWIN=750, YWIN=750, WIN=iwin2, $
           XPOS=ix, NXPOS=nx, $
           YPOS=iy, NYPOS=ny, $
           XOFFSET=10, YOFFSET=10, $
           DATLO=mind, DATHI=maxd, BAD=32767., $
           GTITLE=title, $
           BTITLE=' ', $
           XTITLE=xtitle,$
           YTITLE=ytitle, $
;           XLO=1.,XHI=s(1)+1,$
;           YLO=1.,YHI=s(2)+1,$
;           XTICINC=s(1)/10, YTICINC=s(2)/10, $
           XLO=xlo,XHI=xhi,$
           YLO=ylo,YHI=yhi,$
           XTICINC=xticinc, YTICINC=yticinc, $
           BARTICLO=minb, BARTICHI=maxb ,BARTICINC=barticinc  , $
;           BARFORMAT='(f6.1)', ILOGO=0
;           BARFORMAT='(e12.1)', ILOGO=0
           BARFORMAT=bform, ILOGO=0

end
