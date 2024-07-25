pro plot_trc, frun, trc3d
; Read and plot Tracer Tool output

; ---------------
; Set EMU output file directory
frun_output = frun + '/output/'

; ---------------
; Search available output

print,''
print,'Detected '

fdum = 'ptracer_mon_mean.*.data'
aa_mon = file_search(frun_output+fdum, COUNT=naa_mon)
print,string(naa_mon,format='(i6)'),' files of ',fdum 

fdum = 'ptracer_mon_snap.*.data'
aa_snap = file_search(frun_output+fdum, COUNT=naa_snap)
print,string(naa_snap,format='(i6)'),' files of ',fdum 

; Choose variable
print,''
print,'Select monthly mean or snapshot ... (m/s)?'
fmd = 'n'
read, fmd

pvar = 0
idum = 0
if (fmd eq 'm' or fmd eq 'M') then begin 
   print,''
   print,'==> Reading and plotting monthly means ... '
   
   rd_ptracer, aa_mon, irec, trc3d

endif else begin
   print,''
   print,'==> Reading and plotting snapshots ... '

   rd_ptracer, aa_snap, irec, trc3d

endelse

; 
print,''
print,'*********************************************'
print,'Returning variable '
print,'   trc3d: last plotted tracer'
print,''

end
