pro plot_atrb, frun, atrb, atrb_mn, atrb_hr, fctrl
; Read Attribution Tool output

; ---------------
; Set EMU output file directory
ff = frun + '/output/'

; specify controls in file 
;fctrl = ['lhs', 'wind', 'htflx', 'fwflx', 'sflx', 'pload', 'ic']
fctrl = ['ref', 'wind', 'htflx', 'fwflx', 'sflx', 'pload', 'ic', 'mean']
nterms=n_elements(fctrl)

; ---------------
; Read atrb.out_? (OBJF time-series)

fdum = 'atrb.out_'
fdum_all = fdum + '*'
aa = file_search(ff+fdum_all, COUNT=naa)
if (naa ne 1) then begin 
   if (naa eq 0) then begin
      print,'*********************************************'
      print,'File '+fdum_all+' not found ... '
      print,''
      return
   endif else begin 
      print,'*********************************************'
      print,'More than one '+fdum_all+' found ... '
      print,''
      return
   endelse
endif

ip = strpos(aa(0),fdum) + strlen(fdum)
frec = strmid(aa(0),ip,strlen(aa(0)))   
nrec = long(frec)                       ; length of time-series 

atrb = fltarr(nrec,nterms)
atrb_mn = fltarr(nterms)
close,1 & openr,1,aa(0),/swap_if_little_endian
readu,1,atrb
readu,1,atrb_mn
close,1
print,'*********************************************'
print,'Read OBJF and contributions to it from different controls' 
print,'   atrb: temporal anomaly '
print,'   atrb_mn: reference time-mean '
print,'   fctrl: names of atrb/atrb_mn variables '
print,'from file ',aa(0)
print,''

; ---------------
; Read atrb.step_? (time-step)

fdum = 'atrb.step_' + frec 
aa = file_search(ff+fdum, COUNT=naa)
if (naa eq 0) then begin
   print,'*********************************************'
   print,'File '+fdum+' not found ... '
   print,''
   return
endif

atrb_hr = lonarr(nrec)
close,1 & openr,1,aa,/swap_if_little_endian
readu,1,atrb_hr
close,1
print,'*********************************************'
print,'Read variable '
print,'   atrb_hr: sample time (hours from 1/1/1992 12Z)' 
print,'from file ',aa
print,''

atrb_t = (atrb_hr/24.)/365. + 1992. 

; ---------------
; Plot
!p.multi = [0,1,1]

cc=[1, 22 + (55-22)*findgen(nterms-1)/(nterms-2)]

frun_file=file_basename(frun)

tmin = fix(min(atrb_t))-1
tmax = fix(max(atrb_t))+1
plot,atrb_t,atrb(*,0),Title=frun_file,ynozero=1,xtitle='atrb_hr',ytitle='atrb',xrange=[tmin,tmax],xstyle=1
for i=1,nterms-1 do begin 
   oplot,atrb_t,atrb(*,i),col=cc(i)
endfor

; Label terms/controls
lib_label,fctrl,cc

end
