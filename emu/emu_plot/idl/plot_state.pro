pro plot_state, fdir, fld2d, naa_2d_day, naa_2d_mon, naa_3d_mon
; Read and plot standard state output

; ---------------
; Search available output

print,''
print,'Detected '

fdum = 'state_2d_set1_day.*.data'
aa_2d_day = file_search(fdir+fdum, COUNT=naa_2d_day)
print,string(naa_2d_day,format='(i6)'),' files of ',fdum 

fdum = 'state_2d_set1_mon.*.data'
aa_2d_mon = file_search(fdir+fdum, COUNT=naa_2d_mon)
print,string(naa_2d_mon,format='(i6)'),' files of ',fdum 

fdum = 'state_3d_set1_mon.*.data'
aa_3d_mon = file_search(fdir+fdum, COUNT=naa_3d_mon)
print,string(naa_3d_mon,format='(i6)'),' files of ',fdum 

; ---------------
; Test whether any output was detected 
ndum = max([naa_2d_day, naa_2d_mon, naa_3d_mon])

if (ndum ne 0) then begin 

; ---------------
; Plot available output 

; Choose variable
   f_var=['SSH', 'OBP', 'THETA', 'SALT', 'U', 'V']
   nvar = n_elements(f_var)

   print,''
   print,'Choose variable to plot ... '
   for i=0,nvar-1 do begin
      pdum=string(i+1,format='(i1)')+') '+f_var(i)
      print,pdum
   endfor

; ---------------
; Option to plot another field 
   plot_another = 'Y'
   while (plot_another eq 'y' or plot_another eq 'Y') do begin 
   
      print,''
      print,'Select monthly or daily mean ... (m/d)?'
      print,'(NOTE: daily mean available for SSH and OBP only.)'
      fmd = 'n'
      read, fmd

      pvar = 0
      idum = 0
      if (fmd eq 'd' or fmd eq 'D') then begin 
; ---------------
; Reading state_2d_set1_day
         if (naa_2d_day ne 0) then begin 
            print,''
            print,'==> Reading and plotting daily means ... '
            while (pvar lt 1 or pvar gt 2) do begin 
               print,'Enter variable # to plot ... (1-2)?'
               read, pvar 
               idum = pvar-1 
            endwhile
            print,''
            print,'Plotting ... ',f_var(idum)

            rd_state2d, aa_2d_day, idum, f_var(idum), fld2d
         endif else begin
            print,''
            print,'No daily mean output available ... '
         endelse

      endif else begin
         print,''
         print,'==> Reading and plotting monthly means ... '
         while (pvar lt 1 or pvar gt nvar) do begin 
            print,'Enter variable # to plot ... (1-',string(nvar,format='(i0)')+')?'
            read, pvar 
            idum = pvar-1 
         endwhile
         print,''
         print,'-------------------'
         print,'Plotting ... ',f_var(idum)

         if (idum le 1) then begin 
; ---------------
; Reading state_2d_set1_mon
            if (naa_2d_mon ne 0) then begin 
               rd_state2d, aa_2d_mon, idum, f_var(idum), fld2d
            endif else begin
               print,''
               print,'No monthly mean 2d output available ... '
            endelse
         endif else begin
; ---------------
; Reading state_3d_set1_mon
            if (naa_3d_mon ne 0) then begin 
               rd_state3d, aa_3d_mon, idum, f_var(idum), fld2d
            endif else begin
               print,''
               print,'No monthly mean 3d output available ... '
            endelse
         endelse
      endelse

      print,''
      print,'Plot another file ... (Y/N)?'
      read, plot_another
   endwhile

; ---------------
; Return last plotted 
   print,''
   print,'*********************************************'
   print,'Returning variable '
   print,'   fld2d: last plotted 2d field'

endif else begin
; ---------------
; No available output 
   print,''
   print,'*********************************************'
   print,'No standard state output found in directory '
   print,fdir
endelse

end
