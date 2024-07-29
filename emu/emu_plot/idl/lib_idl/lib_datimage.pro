PRO LIB_DATIMAGE, DATA,  $
           XWIN=win_xsiz, YWIN=win_ysiz, WIN=wnumber, $
           XPOS=xpos, NXPOS=nxpos, $
           YPOS=ypos, NYPOS=nypos, $
           XOFFSET=xoff, YOFFSET=yoff, $
           DATLO=minv, DATHI=maxv, BAD=misval, $
           GTITLE=gtitle, $
           XTITLE=xtitle, YTITLE=ytitle, $
           BTITLE=btitle, $
           XLO=xmin,XHI=xmax,$
           YLO=ymin,YHI=ymax,$
           XTICINC=xtinc, YTICINC=ytinc, $
           BARTICLO=btmin, BARTICHI=btmax,BARTICINC=btinc, $
           BARFORMAT=form, ILOGO=ilogo, $
	   WHITE=whval             ; where (dat eq whval), rgb_white

;-
common colors, rgb_lo, rgb_hi, $
               rgb_land, rgb_missing, rgb_title, rgb_labels, rgb_back
common map_pos, xsmin,xsmax,ysmin,ysmax,win_xsize,win_ysize
;spawn, 'date', /NOSHELL
;
win_xsize=win_xsiz & win_ysize=win_ysiz
if(n_elements(win_xsiz) eq 0) then win_xsize=400
if(n_elements(win_ysiz) eq 0) then win_ysize=300
if(n_elements(wnumber) eq 0) then wnumber=0
if(n_elements(xpos) eq 0) then xpos=1
if(n_elements(nxpos) eq 0) then nxpos=1
if(n_elements(ypos) eq 0) then ypos=1
if(n_elements(nypos) eq 0) then nypos=1
if(n_elements(xoff) eq 0) then xoff=0
if(n_elements(yoff) eq 0) then yoff=0
if(n_elements(ymin) eq 0) then ymin=-90
if(n_elements(ymax) eq 0) then ymax=90
if(n_elements(xmin) eq 0) then xmin=0
if(n_elements(xmax) eq 0) then xmax=360
if(n_elements(minv) eq 0) then minv=min(data)
if(n_elements(maxv) eq 0) then maxv=max(data) 
if(n_elements(misval) eq 0) then misval=32767.
if(n_elements(gtitle) eq 0) then gtitle=' '
if(n_elements(xtitle) eq 0) then xtitle=' '
if(n_elements(ytitle) eq 0) then ytitle=' '
if(n_elements(btitle) eq 0) then btitle=' '
if(n_elements(ytinc) eq 0) then ytinc=(ymax-ymin)/10.
if(n_elements(xtinc) eq 0) then xtinc=(xmax-xmin)/10.
if(n_elements(btmin) eq 0) then btmin=minv
if(n_elements(btmax) eq 0) then btmax=maxv
if(n_elements(btinc) eq 0) then btinc=(btmax-btmin)/10.
if(n_elements(form) eq 0) then form='(i4)'
if(n_elements(ilogo) eq 0) then ilogo=1

if(n_elements(whval) eq 0) then whval=-32767.
;
; CHECKING PARAMETERS.
;
rxsiz=0
if (rxsiz le 0) then begin
;  rxsiz = 0.8 * win_xsize / nxpos
;  rysiz = 0.7 * win_ysize / nypos
  rxsiz = 0.6 * win_xsize / nxpos
  rysiz = 0.6 * win_ysize / nypos
;  rxsi2 = rysiz * (xmax-xmin)/(ymax-ymin)
;  rysi2 = rxsiz * (ymax-ymin)/(xmax-xmin)
;  if ( rysi2 gt rysiz ) then rxsiz = rxsi2
;  if ( rxsi2 gt rxsiz ) then rysiz = rysi2
endif
data2=data

white= where(data2 eq whval, n_white)

valid=where(data2 ne misval)
data2(valid)=data2(valid) < maxv
data2(valid)=data2(valid) > minv

rgb_white = 4  

missing= where(data2 eq misval, nmissing)
data2= (data2 - minv) * (rgb_hi - rgb_lo) / (maxv - minv) + rgb_lo
if(nmissing gt 0) then data2(missing)= rgb_missing

if(n_white gt 0) then data2(white)= rgb_white

;print, 'missing pixels:',n_elements(missing)
data2=lib_resize(data2,rxsiz,rysiz)
; WINDOW
if (wnumber ge 0) then begin
   window, wnumber,xsize= win_xsize, ysize= win_ysize, retain=2
   plot,[0,1],/nodata,back=rgb_back, color= rgb_back
;
;   print,'win_size ',win_xsize,win_ysize
;   
endif
; POSITION IN WINDOW
xcnt= (xpos - 0.5) * win_xsize / nxpos + 0.01*rxsiz
ycnt= (ypos - 0.5) * win_ysize / nypos + 0.02*rysiz
;print, 'xcnt, ycnt:', xcnt, ycnt,win_xsize,xpos, nxpos
xsmin= xcnt + xoff - rxsiz / 2
xsmax= xsmin + rxsiz 
ysmin= ycnt + yoff - rysiz / 2
ysmax= ysmin + rysiz 
;print, 'Map Position (pixels). X:',xsmin,xsmax,' Y:',ysmin,ysmax
; DISPLAY
tv, data2, xsmin, ysmin
; ANNOTATION SIZE
diagonal= sqrt(rxsiz * rxsiz + rysiz * rysiz) ; diagonal length scale
char_size_def = 10  ; DEFAULT CHARACTER SIZE, IN PIXELS
;  Note: diagonal/50 is the approx. char size in pixels.
;txtscale=  1  ; text scaling factor used in IDL to scale default char size
txtscale = (diagonal/50) / char_size_def
; AXES, LABELS, TITLE 
xtnum= fix((xmax - xmin) / xtinc)
ytnum= fix((ymax - ymin) / ytinc)
;print, 'xtnum,ytnum=',xtnum,ytnum
plot, [xmin, xmax], [ymin, ymax], $
  /nodata, /device, /noerase, $
  pos= [xsmin, ysmin, xsmax, ysmax],  $
  xrange=[xmin,xmax],yrange=[ymin,ymax], $
  xstyle= 1, ystyle= 1, $
  xticks=xtnum, yticks=ytnum, $
  back = rgb_back, color= rgb_labels, $
;  back = rgb_back, color= 1, $
  xtitle=xtitle, ytitle=ytitle, $
;  charsize= 1.2*txtscale, charthick= 1, title= gtitle
  charsize= 1.*txtscale, charthick= 1, title= gtitle
  
;; COLOR BAR
if btinc gt 0. then begin
barlen=diagonal / 1.7
barhei= diagonal / 50
xbar  = (xsmax + xsmin - barlen) / 2
ybar  =  ysmin - (ysmax-ysmin)/7
cbar= lib_makebar(barlen, barhei, rgb_lo, rgb_hi)
lib_barlabel, cbar, rgb_labels, btmin, btmax, minv, maxv, $
  (btmax - btmin) / btinc, form, btitle, $
  x_loc=xbar, y_loc=ybar, $
  text_scale=txtscale / 1.333
endif
;
; SET USER COORDINATES 
plot, [0,1],[0,1],position=[xsmin,ysmin,xsmax,ysmax], $
  /noerase,/nodata,/device,$
      xrange=[xmin,xmax],yrange=[ymin,ymax],color=rgb_back,xstyle=5,ystyle=5

;
return
END
