pro plot_fgrd, frun, fgrd2d
; Read and plot Forward Gradient Tool output

; ---------------
; Set EMU output file directory
frun_output = frun + '/output/'

; ---------------
; Search available output

print,''
print,'Detected '

fdum = 'state_2d_set1_day.*.data'
aa_2d_day = file_search(frun_output+fdum, COUNT=naa_2d_day)
print,string(naa_2d_day,format='(i6)'),' files of ',fdum 

fdum = 'state_2d_set1_mon.*.data'
aa_2d_mon = file_search(frun_output+fdum, COUNT=naa_2d_mon)
print,string(naa_2d_mon,format='(i6)'),' files of ',fdum 

fdum = 'state_3d_set1_mon.*.data'
aa_3d_mon = file_search(frun_output+fdum, COUNT=naa_3d_mon)
print,string(naa_3d_mon,format='(i6)'),' files of ',fdum 

; Choose variable
f_var=['SSH', 'OBP', 'THETA', 'SALT', 'U', 'V']
nvar = n_elements(f_var)

print,''
print,'Choose variable to plot ... '
for i=0,nvar-1 do begin
   pdum=string(i+1,format='(i1)')+') '+f_var(i)
   print,pdum
endfor

print,''
print,'Select monthly or daily mean ... (m/d)?'
print,'(NOTE: daily mean available for SSH and OBP only.)'
fmd = 'n'
read, fmd

pvar = 0
idum = 0
if (fmd eq 'd' or fmd eq 'D') then begin 
   print,'==> Reading and plotting daily means ... '
   print,''
   while (pvar lt 1 or pvar gt 2) do begin 
      print,'Enter variable # to plot ... (1-2)?'
      read, pvar 
      idum = pvar-1 
   endwhile
   print,''
   print,'Plotting ... ',f_var(idum)
   
   rd_state2d_r4, aa_2d_day, idum, f_var(idum), fgrd2d

endif else begin
   print,'==> Reading and plotting monthly means ... '
   print,''
   while (pvar lt 1 or pvar gt nvar) do begin 
      print,'Enter variable # to plot ... (1-',string(nvar,format='(i0)')+')?'
      read, pvar 
      idum = pvar-1 
   endwhile
   print,''
   print,'Plotting ... ',f_var(idum)

   if (idum le 1) then begin 
      rd_state2d_r4, aa_2d_mon, idum, f_var(idum), fgrd2d
   endif else begin
      rd_state3d, aa_3d_mon, idum, f_var(idum), fgrd2d
   endelse
endelse

; 
print,'*********************************************'
print,'Returning variable '
print,'   fgrd2d: last plotted gradient'
print,''

end
