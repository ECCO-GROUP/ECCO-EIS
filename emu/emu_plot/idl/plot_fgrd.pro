pro plot_fgrd, frun, fgrd2d, fgrd3d
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

; ---------------
; Choose variable
f_var=['SSH', 'OBP', 'THETA', 'SALT', 'U', 'V']
nvar = n_elements(f_var)

print,''
print,'Variables to plot ... '
for i=0,nvar-1 do begin
   pdum=string(i+1,format='(i1)')+') '+f_var(i)
   print,pdum
endfor

print,''
print,'Select monthly or daily mean ... (m/d)?'
print,'(NOTE: daily mean available for SSH and OBP only.)'
fmd = 'n'
read, fmd

; ---------------
; Read and plot chosen variable
pvar = 0
ivar = 0

; ---------------------------      
; Daily mean
if (fmd eq 'd' or fmd eq 'D') then begin 
   print,'==> Reading and plotting daily means ... '
   print,''
   while (pvar lt 1 or pvar gt 2) do begin 
      print,'Enter variable # to plot ... (1-2)?'
      read, pvar 
      ivar = pvar-1 
   endwhile
   print,''
   print,'Plotting ... ',f_var(ivar)
   
; ---------------------------      
; loop among daily mean 2d files 
   pfile = 1
   while (pfile ge 1 and pfile le naa_2d_day) do begin
      print,''
      print,'Enter file # to read ... (1-'+string(naa_2d_day, format='(i0)')+' or -1 to exit)?'
      read, pfile
      if (pfile lt 1) or (pfile gt naa_2d_day) then break 
      ifile=pfile-1
      rd_state2d_r4, aa_2d_day(ifile), ivar, fgrd2d
      
      fname = file_basename(aa_2d_day(ifile))
      pinfo = f_var(ivar) + string(pfile,format='(1x,i0)') + ' ' + fname
      plt_state2d, fgrd2d, pinfo
   endwhile

   print,'*********************************************'
   print,'Returning variable '
   print,'   fgrd2d: last plotted gradient (2d)'
   print,''

endif else begin
; ---------------------------      
; Monthly mean
   print,'==> Reading and plotting monthly means ... '
   print,''
   while (pvar lt 1 or pvar gt nvar) do begin 
      print,'Enter variable # to plot ... (1-',string(nvar,format='(i0)')+')?'
      read, pvar 
      ivar = pvar-1 
   endwhile
   print,''
   print,'Plotting ... ',f_var(ivar)

   if (ivar le 1) then begin 
      
; ---------------------------      
; loop among monthly mean 2d files 
      pfile = 1
      while (pfile ge 1 and pfile le naa_2d_mon) do begin
         print,''
         print,'Enter file # to read ... (1-'+string(naa_2d_mon, format='(i0)')+')?'
         read, pfile
         if (pfile lt 1) or (pfile gt naa_2d_mon) then break 
         ifile=pfile-1
         rd_state2d_r4, aa_2d_mon(ifile), ivar, fgrd2d
      
         fname = file_basename(aa_2d_mon(ifile))
         pinfo = f_var(ivar) + string(pfile,format='(1x,i0)') + ' ' + fname
         plt_state2d, fgrd2d, pinfo
      endwhile

      print,'*********************************************'
      print,'Returning variable '
      print,'   fgrd2d: last plotted gradient (2d)'
      print,''

   endif else begin

; ---------------------------      
; loop among monthly mean 3d files 
      pfile = 1
      while (pfile ge 1 and pfile le naa_3d_mon) do begin
         print,''
         print,'Enter file # to read ... (1-'+string(naa_3d_mon, format='(i0)')+')?'
         read, pfile
         if (pfile lt 1) or (pfile gt naa_3d_mon) then break 
         ifile=pfile-1
         rd_state3d, aa_3d_mon(ifile), ivar-2, fgrd3d ; ivar-2 because no 3d SSH/OBP
      
         fname = file_basename(aa_3d_mon(ifile))
         pinfo = f_var(ivar) + string(pfile,format='(1x,i0)') + ' ' + fname
         plt_state3d, fgrd3d, pinfo, ivar-2 ; ivar-2 because no 3d SSH/OBP
      endwhile

      print,'*********************************************'
      print,'Returning variable '
      print,'   fgrd3d: last plotted gradient (3d)'
      print,''

   endelse
endelse

; 
end
