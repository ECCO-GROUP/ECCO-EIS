pro plot_adj, frun, adxx
; Read and plot Adjoint Tool output

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; ---------------
; Set EMU output file directory
frun_output = frun + '/output/'

; ---------------
; Choose control
fctrl = ['empmr', 'pload', 'qnet', 'qsw', 'saltflux', 'spflx', 'tauu', 'tauv']
nctrl = n_elements(fctrl)

print,''
print,'Choose control to plot ... '
for i=0,nctrl-1 do begin
   pdum=string(i+1,format='(i1)')+') '+fctrl(i)
   print,pdum
endfor

print,''
print,'Enter control # to plot ... (1-' + string(nctrl,format='(i0)')+')?'
read, ictrl
ictrl = ictrl-1 
print,'Plotting control ... ',fctrl(ictrl)

fdum = 'adxx_' + fctrl(ictrl) + '.*.data'
aa = file_search(frun_output + fdum, COUNT=naa)
if (naa ne 1) then begin 
   if (naa eq 0) then begin
      print,'*********************************************'
      print,'File '+fdum+' not found ... '
      print,''
      return
   endif else begin 
      print,'*********************************************'
      print,'More than one '+fdum+' found ... '
      print,''
      return
   endelse
endif

fname = file_basename(aa(0))
print,'Found file: ',fname 

; ---------------
; Read entire adxx time-series 

; number of 2d records
a = file_info(aa(0))
nadxx = a.size / (long(nx)*long(ny)*4L)

; Read adxx 
adxx = fltarr(nx,ny,nadxx)
close,1 & openr,1,aa(0),/swap_if_little_endian
readu,1,adxx

print,''
print,'*********************************************'
print,'Read adjoint gradient for '+fctrl(ictrl)
print,'   adxx: adjoint gradient as a function of space and lag'
print,'from file ',aa(0)

; ---------------
; Identify record that is 0-lag 
lag0 = 0
for j=nadxx-1,1,-1 do begin
   dum=max(abs(adxx(*,*,j)))
   if (dum ne 0 and lag0 lt j) then lag0=j
endfor 

; Identify longest lag
lagmax = nadxx-1
for j=0,nadxx-1 do begin
   dum=max(abs(adxx(*,*,j)))
   if (dum ne 0 and lagmax gt j) then lagmax=j
endfor

print,' '
print,'Zero lag at (week/record) = ',string(lag0+1,format='(i0)')
print,'Max  lag at (week/record) = ',string(lagmax+1,format='(i0)')

; ---------------
; Plot maps of adxx at select lags
dum2d = fltarr(nx,ny)
lib_nat2globe,hfacc(*,*,0),dumg
landg = where(dumg eq 0, nlandg)  ; index where it is dry

print,''
print,'*********************************************'
print,'Plotting maps of adxx at select lags ...'

idum = 0
while (idum ge 0 and idum le lag0-lagmax) do begin 

   print,''
   print,'Enter lag (# of weeks) to plot ... (0-' + string(lag0-lagmax,format='(i0)') + ' or -1 to exit)?'
   read,idum
   irec = lag0 - idum 
   if (irec lt lagmax or irec gt lag0) then break

   dum2d(*) = adxx(*,*,irec)

   ; scale 
   dum=max(abs(dum2d))
   if (dum ne 0) then begin
      order_of_magnitude=floor(alog10(abs(dum)))
      dscale = 10.^(-order_of_magnitude)
   endif else begin
      dscale = 0.
   endelse
   dum2d(*)=dum2d(*)*dscale

   lib_nat2globe,dum2d,dumg
   dmax = max(dum2d)
   dmin = min(dum2d)
   if (dmin eq dmax) then begin 
      if (dmin eq 0.) then begin
         print,''
         print,'*****************************'
         print,'Field is uniformly zero ... '
         dmax =  1.e-3
         dmin = -dmax
      endif else begin
         print,''
         print,'*****************************'
         print,'Field is uniform with value='+string(dmin,format='(e12.4)')
         dmax = dmax + 1.e-3
         dmin = dmin - 1.e-3
      endelse 
   endif else begin 
      dd = max(abs([dmax,dmin]))
      dmax = dd
      dmin = -dd
   endelse

   dumg(landg) = 32767.

   ftitle= 'lag, rec = '+string([idum,irec+1],format='(i0,1x,i0)') + ' ' + fname + ' scaled by x'+string(dscale,format='(e9.0)')
   lib_quickimage2,dumg,dmin,dmax,ftitle

endwhile

; ---------------
; Plot time-series of adxx at select locations 

print,''
print,'*********************************************'
print,'Plotting time-series of adxx at select locations ...'

nlag = lag0-lagmax+1
ww = findgen(nlag)
iww = lag0-findgen(nlag)

valid_pt = 1 
while (valid_pt eq 1) do begin 

   print,''
   print,'Press 1 to continue or 2 to exit ... (1/2)?'
   read, valid_pt
   if (valid_pt ne 1) then break

   slct_2d_pt, xlon, ylat, ix, jy

   ftitle='(i,j,lon,lat)= '+string([ix,jy,xlon,ylat],format='(i2,1x,i4,2X,f7.1,1x,f6.1)')+' ' + fname
   plot,ww,adxx(ix-1,jy-1,iww),title=ftitle,xtitle='lag (weeks)', ytitle='adxx'

endwhile

end
