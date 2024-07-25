pro get_timestep, fname, fprefix, timestep
; Extract time-step from MITgcm output file name 

timestep = -999999999L

; Search for the string "ptracer_mon" in the input string
pos = strpos(fname, fprefix)

; If the search string is found, proceed to extract the number
if pos ne -1 then begin
    ; Find the position of the first '.' after the search string
    dot_pos = strpos(fname, '.', pos)
    
    ; Extract the number part starting from the dot position
    if dot_pos ne -1 then begin
        number_string = strmid(fname, dot_pos + 1, strlen(fname) - dot_pos - 1)
        
                                ; Convert the number string to a long
                                ; integer to remove preceding zeros
        timestep = long(number_string)
     endif else begin
        print, 'No dot found after prefix string.'
     endelse
  endif else begin
    print, 'Prefix string not found.'
 endelse

end
