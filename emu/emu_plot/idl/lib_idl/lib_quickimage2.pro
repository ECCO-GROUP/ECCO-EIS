pro lib_quickimage2, data,mind,maxd,title,IWIN=iw
; plots color image with color bar

s=size(data)
maxs=max(s(1:2))

!p.multi=[0,1,1]

if(n_elements(iw) eq 0) then iw=1

lib_datimage, DATA,  $
           XWIN=750, YWIN=750, WIN=iw, $
           XPOS=1, NXPOS=1, $
           YPOS=1, NYPOS=1, $
           XOFFSET=10, YOFFSET=10, $
           DATLO=mind, DATHI=maxd, BAD=32767., $
           GTITLE=title, $
           XTITLE=' ',$
           YTITLE=' ', $
           XLO=1.,XHI=s(1)+1,$
           YLO=1.,YHI=s(2)+1,$
           XTICINC=s(1)/10, YTICINC=s(2)/10, $
           BARTICLO=mind, BARTICHI=maxd ,BARTICINC=(maxd-mind)/5.  , $
           BARFORMAT='(f6.1)', ILOGO=0
end
