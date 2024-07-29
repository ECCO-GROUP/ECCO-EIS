pro lib_barlabel, color_bar, color_value, min_value, max_value, minv, maxv, step, $
  form, text, x_loc=x_loc, y_loc=y_loc, text_scale=text_scale
;+
;NAME:
;	COLORBAR
;
;PURPOSE:
;	color bar label and label axis.
;INPUT:
;	BAR_LABEL = PROGRAM
;	COLOR_BAR = actual array of the color bar.
;	COLOR_VALUE = color of the text.
;	MIN_VALUE = minium value 
;	MAX_VALUE = maxium value.
;	STEP= number of step
;	FORM= FORTRAN-type format for the tick marks annotations
;	TEXT= 'TEXT LABEL'
;OPTIONS:
;	X_LOC	= position of x-location to be display
;	Y_LOC	= position of y-location to be display
;	text_scale = size of the text for out put.
;	OUTPUT:
;		none.
;COMMON BLOCKS
; vz+ vzcolors
;
;MODIFICATION HISTORY:
;	Written by Andy V. Tran, Feb. 6, 1991
;	Modified by Denis P. Leconte, Feb. 13, 1991; vz 920821
;-
;vz+
common vzcolors, rgb_lo, rgb_hi, $
               rgb_land, rgb_missing, rgb_title, rgb_labels, rgb_back
;vz+
;print,  min_value, max_value, step
x_no = n_elements(color_bar(*,0))
y_no = n_elements(color_bar(0,*))
if n_elements(text_scale) eq 0 then text_scale = 1
if n_elements(x_loc) eq 0 then begin
  print,'move the mouse to the desired position'
  cursor,x_loc,y_loc,/wait,/device
  y_loc = y_loc - y_no
  tv,color_bar,x_loc,y_loc
endif else begin
  tv,color_bar,x_loc,y_loc
endelse

x_interval = (max_value - min_value) / step
xtnam= strarr(step + 1)
xtval= fltarr(step + 1)
x= min_value - x_interval
for i= 0L, step do begin
  x= x + x_interval
; print, 'colorbar-i- x=',x, step, i, long(step)
  if (x ge minv) and (x le maxv) then begin
    xtval(i)= x 
    xtnam(i)= string(format=form,x)
  endif 
;vz( 920820
  char_size_def = 10 ; DEFAULT CHARACTER SIZE, in pixels.
;if970806  if (x lt minv) then i = i-1
;if970806  if (x gt maxv) then i = step+1
endfor
plot, [minv, maxv], [0,1], /nodata, /device, xstyle= 5, ystyle= 5, $
  pos= [x_loc, y_loc, x_loc + x_no - 1, y_loc + y_no - 1],  /noerase, $
  color= color_value
axis, /data, color=color_value, xaxis= 0, xstyle= 0, ystyle= 0, xticks= step, $
  xminor= 1, ticklen= -0.4, xcharsize= text_scale, xtickname= xtnam, $
  xtickv= xtval
if N_params(0) eq 9 then begin ; begin to do text label.
  text_len = strlen(text)
;vz-  x_cur_pos = (x_loc + (x_no/2.)) - (text_len * 4 * text_scale)
;vz-  y_cur_pos = y_loc - 20 - 0.5 * y_no - 18 * text_scale
;vz(
  x_cur_pos = (x_loc + (x_no/2.))
  y_cur_pos = (y_loc - (y_no*3))
  xyouts,x_cur_pos,y_cur_pos,text,charthick=1,size=1.5*text_scale,  $
    color=color_value,alignment=0.5,/device
;vz)
endif
end
