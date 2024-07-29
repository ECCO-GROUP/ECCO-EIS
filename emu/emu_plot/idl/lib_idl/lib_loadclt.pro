PRO lib_LOADCLT, FILENAME
;
;+
; NAME:
;	lib_LOADCLT
; PURPOSE:
;	Loads a mapit-style color table, makes it current color table
; CATEGORY:
; CALLING SEQUENCE:
;	lib_loadclt, filename 
; INPUTS:
;	FILENAME, the name of the file containing the color table
;     filename must have 256 records, each of the form:
;     index,redval,greenval,blueval
; OPTIONAL INPUT PARAMETER:
;	None.
; OUTPUT:
;	None.
;
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	None.
; RESTRICTIONS:
;	None.
; MODIFICATION HISTORY:
;	Written January 11, 1991 AD by Denis P. Leconte
;-
;
;
r= bytarr(256)
g= bytarr(256)
b= bytarr(256)
k= 0;
OPENR, unit, filename, /GET_LUN
for i= 0, 255 do begin
  readf, unit, k, rr, gr, br
;vz( old: r(i), new: r(k)
  r(k)= rr
  g(k)= gr
  b(k)= br
;vz)
endfor
FREE_LUN, unit
tvlct, r, g, b
END
