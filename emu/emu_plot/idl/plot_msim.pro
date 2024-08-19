pro plot_msim, frun, fld2d, fld3d 
; check Modified Simulation Tool output

; ---------------
; Set EMU output file directory
frun_output = frun + '/diags/'

; ---------------
; Search files 

print,''
print,"Checking EMU standard model state output ... "
print,''

plot_state, frun_output, fld2d, fld3d, naa_2d_day, naa_2d_mon, naa_3d_mon

ndum = max([naa_2d_day, naa_2d_mon, naa_3d_mon])
print,''
print,'*********************************************'
if (ndum ne 0) then begin 
   print,"EMU's standard model state output can be sampled using EMU's "
   print,"Sampling Tool, specifying the diag subdirectory of this run" 
   print,"in response to the Tool's prompt;"
   print,frun_output
   print,''

endif else begin
   print,"No diagnostic state output found in this run's diag subdirectory." 
   print,frun_output
   print,''
endelse

; ---------------
; Search subdirctories 

print,''
print,'*********************************************'
print,"Checking Budget output ... "

; Search for all subdirectories 
entries = file_search(frun_output + '/*')

; Initialize the counter
subdir_count = 0

; Loop through the entries and count only directories
for i = 0, n_elements(entries) - 1 do begin
   ; Check if the entry is a directory
   if file_test(entries[i], /directory) then begin
      subdir_count = subdir_count + 1
   endif
endfor

if (subdir_count ne 0) then begin 

; Count total number of .data files in the subdirectories
   files = file_search(frun_output + '*/*.data')
   total_file_count = n_elements(files)

   if (total_file_count ne 0) then begin 

; Output # of subdirectories 
      print,'' 
      print, 'Total number of subdirectories: ', subdir_count

   ; Initialize the counter
      subdir_count2 = 0
   ; Loop through each subdirectories again 
   ; and count number of .data files in each
      print,'' 
      for i = 0, n_elements(entries) - 1 do begin

   ; Check if the entry is a directory
         if file_test(entries[i], /directory) then begin
            subdir_count2 = subdir_count2 + 1

   ; Search for all files ending with .data in the directory
            files = file_search(entries[i] + '/*.data')

   ; Count the number of .data files
            file_count = n_elements(files)

   ; Print name of subdirectory and number of .data files 
            fname = file_basename(entries[i])
            fdum = string(subdir_count2,format='(3x,i0)')+') '+ fname + ' has '+string(file_count,format='(i0)') + ' files'
            print,fdum

         endif
      endfor

      print,''
      print,'*********************************************'
      print,"Budget output of this run can be analyzed using "
      print,"EMU's Budget Tool, specifying the diag subdirectory of this run" 
      print,"in response to the Tool's prompt;"
      print,frun + '/diags'
      print,'' 
   endif else begin 
      print,''
      print,"No budget output found in this run's diag subdirectory." 
      print,frun + '/diags'
      print,''
   endelse

endif else begin
   print,"No budget output found in this run's diag subdirectory." 
   print,frun + '/diags'
   print,''
endelse

end
