pro plot_state, fdir, fld2d, fld3d, naa_2d_day, naa_2d_mon, naa_3d_mon
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
   print,'Variables to plot ... '
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
      ivar = 0
      if (fmd eq 'd' or fmd eq 'D') then begin 
; ---------------
; Reading state_2d_set1_day
         if (naa_2d_day ne 0) then begin 
            print,''
            print,'==> Reading and plotting daily means ... '
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
               print,'Enter file # to read ... (1-'+string(naa_2d_day, format='(i0)')+')?'
               read, pfile
               if (pfile lt 1) or (pfile gt naa_2d_day) then break 
               ifile=pfile-1
               rd_state2d, aa_2d_day(ifile), ivar, fld2d
               
               fname = file_basename(aa_2d_day(ifile))
               pinfo = f_var(ivar) + string(pfile,format='(1x,i0)') + ' ' + fname
               plt_state2d, fld2d, pinfo
            endwhile

            print,'*********************************************'
            print,'Returning variable '
            print,'   fld2d: last plotted 2d field'
            print,''

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
            ivar = pvar-1 
         endwhile
         print,''
         print,'-------------------'
         print,'Plotting ... ',f_var(ivar)

         if (ivar le 1) then begin 
; ---------------
; Reading state_2d_set1_mon
            if (naa_2d_mon ne 0) then begin 
               print,''
               print,'==> Reading and plotting 2d monthly means ... '
               print,''
               print,'Plotting ... ',f_var(ivar)

; ---------------------------      
; loop among monthly mean 2d files 
               pfile = 1
               while (pfile ge 1 and pfile le naa_2d_mon) do begin
                  print,''
                  print,'Enter file # to read ... (1-'+string(naa_2d_mon, format='(i0)')+')?'
                  read, pfile
                  if (pfile lt 1) or (pfile gt naa_2d_mon) then break 
                  ifile=pfile-1
                  rd_state2d, aa_2d_mon(ifile), ivar, fld2d
               
                  fname = file_basename(aa_2d_mon(ifile))
                  pinfo = f_var(ivar) + string(pfile,format='(1x,i0)') + ' ' + fname
                  plt_state2d, fld2d, pinfo
               endwhile

               print,'*********************************************'
               print,'Returning variable '
               print,'   fld2d: last plotted 2d field'
               print,''

            endif else begin
               print,''
               print,'No monthly mean 2d output available ... '
            endelse

         endif else begin
; ---------------
; Reading state_3d_set1_mon
            if (naa_3d_mon ne 0) then begin 
               print,''
               print,'==> Reading and plotting 3d monthly means ... '
               print,''
               print,'Plotting ... ',f_var(ivar)

; ---------------------------      
; loop among monthly mean 3d files 
               pfile = 1
               while (pfile ge 1 and pfile le naa_3d_mon) do begin
                  print,''
                  print,'Enter file # to read ... (1-'+string(naa_3d_mon, format='(i0)')+')?'
                  read, pfile
                  if (pfile lt 1) or (pfile gt naa_3d_mon) then break 
                  ifile=pfile-1
                  rd_state3d, aa_3d_mon(ifile), ivar-2, fld3d ; ivar-2 because no 3d SSH/OBP
               
                  fname = file_basename(aa_3d_mon(ifile))
                  pinfo = f_var(ivar) + string(pfile,format='(1x,i0)') + ' ' + fname
                  plt_state3d, fld3d, pinfo, ivar-2 ; ivar-2 because no 3d SSH/OBP
               endwhile

               print,'*********************************************'
               print,'Returning variable '
               print,'   fld3d: last plotted 3d field'
               print,''

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

endif else begin
; ---------------
; No available output 
   print,''
   print,'*********************************************'
   print,'No standard state output found in directory '
   print,fdir
endelse

end
