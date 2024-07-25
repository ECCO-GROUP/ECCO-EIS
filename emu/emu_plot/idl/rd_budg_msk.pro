pro rd_budg_msk, fdir, budg_msk
; Read Budget Tool mask (weight) 

; ---------------
; Create template 
msk_template = {msk:'x', msk_dim:0L, f_msk:ptr_new(), i_msk:ptr_new(), j_msk:ptr_new(), k_msk:ptr_new()}

; ---------------
; ID mask files 
ff = fdir + 'emu_budg.msk3d_*'
fmsk = file_search(ff, count=nmsk)
if (nmsk eq 0) then begin
   print,'*********************************************'
   print,'nmsk = ',nmsk
   print,'No emu_budg.msk3d_? file found ... '
   print,''
   return
endif

budg_msk = replicate(msk_template, nmsk)

mag = 0.
inum = 0L
fvar = '.msk3d_'

; Loop among all masks 
for im=0,nmsk-1 do begin 

   close,1 & openr,1,fmsk(im),/swap_if_little_endian

; ID mask type
   ip1 = strpos(fmsk(im),fvar) + strlen(fvar)
   ip2 = strlen(fmsk(im))
   budg_msk(im).msk = strmid(fmsk(im),ip1,ip2-ip1)

; 
   close,1 & openr,1,fmsk(im),/swap_if_little_endian
   readu,1,inum
   budg_msk(im).msk_dim = inum
;   print,fmsk(im),im,inum,format='(a,2x,i2,2x,i)'

   budg_msk(im).f_msk = ptr_new(fltarr(inum))
   budg_msk(im).i_msk = ptr_new(lonarr(inum))
   budg_msk(im).j_msk = ptr_new(lonarr(inum))
   budg_msk(im).k_msk = ptr_new(lonarr(inum))

   fdum = fltarr(inum)
   idum = lonarr(inum)

   readu,1,fdum
   *budg_msk(im).f_msk = fdum
   readu,1,idum
   *budg_msk(im).i_msk = idum
   readu,1,idum
   *budg_msk(im).j_msk = idum
   readu,1,idum
   *budg_msk(im).k_msk = idum

   close,1

endfor

return
end
