pro lib_chk_emu_name, fdir, full_path
; Truncate fdir to directory name of emu output, in case fdir points to a
; subdirectory of emu output. 

  ; Check if the input is a string
  IF N_ELEMENTS(fdir) EQ 0 THEN BEGIN
    PRINT, 'Error: No input provided.'
    full_path=' '
    ENDIF

  IF SIZE(fdir, /TNAME) NE 'STRING' THEN BEGIN
    PRINT, 'Error: Input is not a string.'
    full_path=' '
    ENDIF

; Remove trailing slash if present
  if STRMID(fdir, STRLEN(fdir)-1, 1) EQ '/' then fdir = STRMID(fdir, 0, STRLEN(fdir)-1)

; Extract the directory name
  parts = STRSPLIT(fdir, '/', /EXTRACT)
  directory_name = parts[parts.LENGTH - 1]

; Check if directory_name starts with 'emu_'
  IF STRPOS(directory_name, 'emu_') EQ 0 THEN BEGIN
;     PRINT, 'The directory name starts with "emu_".'
     full_path = fdir
  ENDIF ELSE BEGIN
; Extract the parent directory path
     parent_directory = FILE_DIRNAME(fdir)
; Check if the parent directory name start with 'emu_'
     if strpos(parent_directory, 'emu_') eq 0 then begin
; Substitute parent directory path as fdir
        full_path = parent_directory
     endif else begin
; Directory name does not conform to EMU syntax 
        print,'Error: Directory name does not conform to EMU syntax'
        full_path = ' '
     endelse
  ENDELSE

END
