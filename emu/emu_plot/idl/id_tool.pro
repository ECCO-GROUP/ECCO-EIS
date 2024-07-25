pro id_tool, frun, ftool ; ID the EMU Tool used 

; Check if the input is a string
;  IF NOT STRING(frun) THEN BEGIN
;    PRINT, 'Error: Input is not a string.'
;    RETURN
; ENDIF

  frun_file=file_basename(frun)

  ; Find the position of the first underscore
  underscore1_pos = STRPOS(frun_file, '_')

  ; Check if the first underscore is found
  IF underscore1_pos EQ -1 THEN BEGIN
    PRINT, 'Error: The first underscore not found.'
    RETURN
 ENDIF

  ; Find the position of the second underscore
  underscore2_pos = STRPOS(frun_file, '_', underscore1_pos + 1)

  ; Check if the second underscore is found
  IF underscore2_pos EQ -1 THEN BEGIN
    PRINT, 'Error: The second underscore not found.'
    RETURN
 ENDIF

  ; Extract the first set of characters preceding the first underscore
  part1 = STRMID(frun_file, 0, underscore1_pos)

                                ; Extract the second set of characters
                                ; between the first and second
                                ; underscores
  part2 = STRMID(frun_file, underscore1_pos + 1, underscore2_pos - underscore1_pos - 1)

  ; Print the results
;  PRINT, 'First part: ', part1
;  PRINT, 'Second part: ', part2

;
  if (part1 ne 'emu') then begin 
     print,'*********************************************'
     print,'Directory name does not conform to EMU syntax.'
     print,'*********************************************'
  endif

  ftool=part2

END
