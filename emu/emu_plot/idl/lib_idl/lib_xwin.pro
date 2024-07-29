pro lib_xwin, lib_dir ; sets plotting device to x windows & sets color prefs.

;
common colors, rgb_lo, rgb_hi, $
               rgb_land, rgb_missing, rgb_title, rgb_labels, rgb_back
 rgb_lo =       6
 rgb_hi =      63
 rgb_land  =    5
 rgb_missing =  3
 rgb_title =    2
 rgb_back  =    4
 rgb_labels=    1

;
set_plot, 'x'
device, bypass_translation=1
device, decomposed=0  ; for screens supporting 256^3 colors or more
;
window, 0, colors=64, xsize=30,ysize=30 ; if I don't open, 'device' will...
!p.background = rgb_back  ; still needs 'plot,[0,1],back=rgb_back' as first
;                           command after opening a window
!p.color      = rgb_labels
;
lib_loadclt,lib_dir + '/lib_std64.rgb'
!p.font = 0 & device, font='8x13'  ; font -> hardware
wdelete,0  ; the device cmd open window 0.
;
;print, 'lib_xwin done'
end
