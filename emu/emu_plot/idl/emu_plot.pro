; Read and plot EMU output 
;
; .run emu_plot.pro

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; Suppress the % Compiled module: print out
!QUIET = 1

; ---------------
; Add EMU's directory of idl programs in IDL's path 

; Get the current script's full path using SCOPE_TRACEBACK
traceback = SCOPE_TRACEBACK(/STRUCTURE)
currentRoutinePath = traceback[0].FILENAME

; Extract the directory from the full path
currentDir = FILE_DIRNAME(currentRoutinePath)
;PRINT, 'Current directory:', currentDir

; Check if the directory is already in !PATH
if STRPOS(':' + !PATH + ':', ':' + currentDir + ':') eq -1 then begin
    ; Add the current directory to !PATH
    !PATH = !PATH + ':' + currentDir
    !PATH = !PATH + ':' + currentDir + '/lib_idl'
;    PRINT, 'Directory added to !PATH:', currentDir
endif else begin
;    PRINT, 'Directory already in !PATH:', currentDir
end

;; Print the updated !PATH
;PRINT, '!PATH:', !PATH
emu_plot_dir=currentDir

; ---------------
; Run lib_xwin (set up plotting environment)

lib_xwin,currentDir+'/lib_idl'

; ---------------
; Read emu_ref location

emu_access_dir=file_dirname(emu_plot_dir)
;print,'emu_access_dir=',emu_access_dir

; Find all files in the directory excluding 'emu_env.sh'
files = FILE_SEARCH(emu_access_dir + '/emu_env.*', COUNT=count)
filteredFiles = []

FOR i = 0, count-1 DO BEGIN
    IF FILE_BASENAME(files[i]) NE 'emu_env.sh' THEN filteredFiles = [filteredFiles, files[i]]
ENDFOR

; Check if there is only one file left after filtering
IF N_ELEMENTS(filteredFiles) EQ 1 THEN BEGIN
    fileToRead = filteredFiles[0]
;    PRINT, 'Reading file: ', fileToRead
    
    ; Open the file and read it line by line
    OPENR, lun, fileToRead, /GET_LUN
    line = ''
    emu_input_dir = ''
    WHILE NOT EOF(lun) DO BEGIN
        READF, lun, line
        ; Check if the line starts with 'input_'
        IF STRPOS(line, 'input_') EQ 0 THEN BEGIN
            emu_input_dir = STRMID(line, 6, STRLEN(line) - 6) ; Extract the part after 'input_'
            BREAK
        ENDIF
    ENDWHILE
    FREE_LUN, lun
    
    ; Print the extracted emu_input_dir
    IF emu_input_dir NE '' THEN BEGIN
        PRINT, 'EMU Input Files directory: ', emu_input_dir
    ENDIF ELSE BEGIN
        PRINT, 'No line starting with "input_" found in the file.'
    ENDELSE
ENDIF ELSE BEGIN
    PRINT, 'Error: There are either no files or more than one file excluding emu_env.sh in the directory.'
ENDELSE

; ---------------
; Read model grid information 

emu_ref=emu_input_dir + '/emu_ref'
;print,'emu_ref = ',emu_ref
rd_grid, emu_ref

; ---------------
; Read EMU output

frun_temp = ' '
print,' '
print,'Enter directory of EMU run to examine; e.g., emu_samp_m_2_45_585_1 ... ?'
read, frun_temp
if file_test(frun_temp, /directory) eq 0 then begin
   print, 'Error: Directory does not exist.'
   stop
endif

; Truncate to EMU run directory name in case user provides emu's output subdirectory
lib_chk_emu_name, frun_temp, frun_temp_chk
if (frun_temp_chk eq ' ') then begin 
   print,'Directory name ', frun_temp, ' does not conform to EMU syntax.'
   stop
endif

; Get full pathname to frun_temp 
lib_fullpath, frun_temp_chk, frun 

print,' '
print,'Reading ',frun

id_tool, frun, ftool
if (ftool eq ' ') then begin 
   stop
endif

; ---------------
print,''

case ftool of
; 1) Sampling Tool
   'samp': begin 
      print,'Reading Sampling Tool output .. ' 
      plot_samp,frun, smp, smp_mn, smp_hr
   end

; 2) Foward Gradient Tool
   'fgrd': begin
      print,'Reading Forward Gradient Tool output .. ' 
      plot_fgrd, frun, fgrd2d, fgrd3d 
   end

; 3) Adjoint Tool
   'adj': begin
      print,'Reading Adjoint Tool output .. ' 
      plot_adj, frun, adxx
   end

; 4) Convolution Tool
   'conv': begin
      print,'Reading Convolution Tool output .. ' 
      plot_conv, frun, recon1d, istep, fctrl, ev_lag, ev_ctrl, ev_space
   end

; 5) Tracer Tool
   'trc': begin
      print,'Reading Tracer Tool output .. ' 
      plot_trc, frun, trc3d
   end

; 6) Budget Tool
   'budg': begin
      print,'Reading Budget Tool output .. ' 
      plot_budg, frun, emu_tend, emu_tend_name, emu_tint, emu_tint_name, budg_msk, budg_mkup, nmkup
   end

; 7) Modified Simulation Tool
   'msim': begin
      print,'Reading Modified Simulation Tool output .. ' 
      plot_msim, frun, fld2d, fld3d 
   end

; 8) Attribution Tool                          ;
   'atrb': begin
      print,'Reading Attribution Tool output .. ' 
      plot_atrb,frun, atrb, atrb_mn, atrb_sec, fctrl
   end

; No corresponding Tool
   else: begin 
      print,'Corresponding EMU Tool not found  ... ', ftool
   end
endcase

end
