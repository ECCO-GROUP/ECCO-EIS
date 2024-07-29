pro lib_fullpath, relative_path, full_path
  ; Check if the input is a string
  IF N_ELEMENTS(relative_path) EQ 0 THEN BEGIN
    PRINT, 'Error: No input provided.'
    full_path=' '
    ENDIF

  IF SIZE(relative_path, /TNAME) NE 'STRING' THEN BEGIN
    PRINT, 'Error: Input is not a string.'
    full_path=' '
    ENDIF

  ; Handle the '~' shorthand for the user's home directory
  IF STRMID(relative_path, 0, 1) EQ '~' THEN BEGIN
    home_dir = GETENV('HOME')
    IF home_dir EQ '' THEN BEGIN
      PRINT, 'Error: Unable to get home directory.'
      full_path=' '
      ENDIF
    ; Replace '~' with the home directory path
    full_path = STRJOIN([home_dir, STRMID(relative_path, 1, STRLEN(relative_path)-1)], '/')
    ENDIF ELSE BEGIN
    ; Get the current working directory
    current_dir = FILE_EXPAND_PATH('.')
    
    ; Check if the relative path is already an absolute path
    IF STRMID(relative_path, 0, 1) EQ '/' THEN BEGIN
      full_path = relative_path
      ENDIF ELSE BEGIN
      ; Construct the full path
      full_path = FILE_EXPAND_PATH(current_dir + '/' + relative_path)
      ENDELSE
   ENDELSE

  ; Check if the directory exists
  IF FILE_TEST(full_path, /DIRECTORY) EQ 0 THEN BEGIN
    PRINT, 'Error: Directory does not exist.'
    full_path=' '
    ENDIF

  END
