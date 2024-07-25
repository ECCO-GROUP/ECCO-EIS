pro plot_samp, frun, smp, smp_mn, smp_sec
; Read Sampling Tool output

; ---------------
; Set EMU output file directory
ff = frun + '/output/'

; ---------------
; Read samp.out_? (OBJF time-series)

fdum = 'samp.out_'
fdum_all = fdum + '*'
aa = file_search(ff+fdum_all, COUNT=naa)
if (naa ne 1) then begin 
   print,''
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

smp = fltarr(nrec)
smp_mn = 1.
close,1 & openr,1,aa(0),/swap_if_little_endian
readu,1,smp
readu,1,smp_mn
close,1
print,''
print,'*********************************************'
print,'Read variables '
print,'   smp: temporal anomaly of sampled variable'
print,'   smp_mn: reference time-mean of sampled variable'
print,'from file ',aa(0)

; ---------------
; Read samp.step_? (time-step)

fdum = 'samp.step_' + frec 
aa = file_search(ff+fdum, COUNT=naa)
if (naa eq 0) then begin
   print,''
   print,'*********************************************'
   print,'File '+fdum+' not found ... '
   print,''
   return
endif

smp_sec = lonarr(nrec)
close,1 & openr,1,aa(0),/swap_if_little_endian
readu,1,smp_sec
close,1
print,''
print,'*********************************************'
print,'Read variable '
print,'   smp_sec: sample time (seconds from 1/1/1992 12Z)' 
print,'from file ',aa(0)

smp_yday = (smp_sec/24.)/365. + 1992. 

; ---------------
; Plot
print,''
print,'Plotting sampled time-series ... '

!p.multi = [0,1,1]

samp_t = smp_yday 
samp_v = smp+smp_mn

frun_file=file_basename(frun)

tmin = fix(min(samp_t))-1
tmax = fix(max(samp_t))+1
plot,samp_t,samp_v,title=frun_file,ynozero=1,ytitle='smp + smp_mn',xtitle='smp_sec',xrange=[tmin,tmax],xstyle=1

end
