pro rd_budg_mkup, fdir, budg_msk, budg_mkup, nmkup 
; Read Budget Tool budget makeup (mkup)

; ------------------------------------------
; Create template 
mkup_template = {var:'*', msk:'*', isum:1, mkup_dim:0L, mkup:ptr_new()}   
         ; var is variable name (postfix in filename)
         ; msk is mask name 
         ; isum is corresponding array number in emu_budg.sum file
         ; mkup is time-series of the budget component

; ------------------------------------------
; ID budge makup files 
ff = fdir + 'emu_budg.mkup_*'
fmkup = file_search(ff,count=nmkup)
;print,'nmkup = ',nmkup

if (nmkup eq 0) then begin
   print,'*********************************************'
   print,'nmkup = ',nmkup
   print,'No emu_budg.mkup_? file found ... '
   print,''
   return
endif

budg_mkup = replicate(mkup_template, nmkup)

fvar = '.mkup_'
fmsk = 'x'
iterm = 1L

for im=0,nmkup-1 do begin 

   close,1 & openr,1,fmkup(im),/swap_if_little_endian

; ID makup name 
   ip1 = strpos(fmkup(im),fvar) + strlen(fvar)
   ip2 = strlen(fmkup(im))
   budg_mkup(im).var = strmid(fmkup(im),ip1,ip2-ip1)

; Mask name 
   close,1 & openr,1,fmkup(im),/swap_if_little_endian
   readu,1,fmsk
   budg_mkup(im).msk = fmsk

   imsk = where(budg_msk.msk eq fmsk)  ; mask index 
   if (imsk eq -1) then begin
      print,'f21_k_rd_mkup: No corresponding mask ... ',fvar
      stop
   endif

; Corresponding array number in emu_budg.sum 
   readu,1,iterm
   budg_mkup(im).isum = iterm

; Read time-series of makeup term
   mkup_dim = budg_msk(imsk).msk_dim  ; # of elements in term 
   budg_mkup(im).mkup_dim = mkup_dim

   aa = file_info(fmkup(im))
   nmonths = (aa.size - 2)/4/mkup_dim  ; # of months of term 
;   print,'im, nmonths = ',im,nmonths

   budg_mkup(im).mkup = ptr_new(fltarr(mkup_dim, nmonths))

   fdum = fltarr(mkup_dim,nmonths)

   readu,1,fdum
   *budg_mkup(im).mkup = fdum

close,1

endfor

return
end
