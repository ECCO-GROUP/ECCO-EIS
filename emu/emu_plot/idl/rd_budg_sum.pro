pro rd_budg_sum, ff, emubudg, emubudg_name, lhs, rhs, adv, mix, frc, nvar, ibud
; Read and sort Budget Tool output file emu_budg.sum_*

; ---------------
; Open emu_budg.sum_? file 
aa = file_search(ff, COUNT=naa)
if (naa eq 0) then begin
   print,'*********************************************'
   print,'File '+ff+' not found ... '
   print,''
   return
endif

close,1 & openr,1,ff,/swap_if_little_endian

; ---------------
; Read ID of budget quantity 
ibud = 1L 
readu,1,ibud
if (ibud lt 1 or ibud gt 5) then begin
   print,'INVALID ibud in this Budget Tool output ... ',ibud
   stop
endif
ibud = ibud-1
;print,'ibud = ',ibud

; ---------------
; Read number of months in the time-series
nmonths = 1L
readu,1,nmonths
;print,'nmonths = ',nmonths

; ---------------
; Read budget variable name and its time-series.
fvar = '123456789012'
fdum = fltarr(nmonths)

readu,1,fvar
emubudg_name = fvar
readu,1,fdum
emubudg = fdum
nvar = 1

; ---------------
; Repeat reading budget variable name and its time-series until end 
while not eof(1) do begin
   readu,1,fvar
   emubudg_name = [emubudg_name, fvar]
   readu,1,fdum
   emubudg = [ [emubudg], [fdum] ]
   nvar = nvar + 1
endwhile 

;print,'nvar = ',nvar

; -----------------------------------
; For plotting LHS vs RHS of the budget 

tt = findgen(nmonths)/12. + 1992.

fdum(*) = emubudg(*,2)
for i=3,nvar-1 do fdum(*) = fdum(*) + emubudg(*,i)

lhs = fltarr(nmonths)
rhs = fltarr(nmonths)

lhs(*) = emubudg(*,1)
rhs(*) = fdum(*)

; -----------------------------------
; Sum the different terms that make up advection (adv), mixing (mix), and forcing (frc)

; adv
fvar = 'adv'
adv = fltarr(nmonths)
nterms=0
for it=0,nvar-1 do begin
   idum = strpos(emubudg_name(it), fvar)
   if (idum ne -1) then begin
      adv = adv + emubudg(*,it)
      nterms=nterms+1
   endif
endfor
if (nterms eq 0) then print,'**** no adv terms ***'

; mix
fvar = 'mix'
mix = fltarr(nmonths)
nterms=0
for it=0,nvar-1 do begin
   idum = strpos(emubudg_name(it), fvar)
   if (idum ne -1) then begin
      mix = mix + emubudg(*,it)
      nterms=nterms+1
   endif
endfor
if (nterms eq 0) then print,'**** no mix terms ***'

; frc
frc = fltarr(nmonths)
nterms=0
for it=0,nvar-1 do begin
   if (emubudg_name(it) ne 'dt  ' and emubudg_name(it) ne 'lhs ') then begin
      id0 = strpos(emubudg_name(it), 'dt ')
      id1 = strpos(emubudg_name(it), 'lhs')
      id2 = strpos(emubudg_name(it), 'adv')
      id3 = strpos(emubudg_name(it), 'mix')
      if (id0 eq -1 and id1 eq -1 and id2 eq -1 and id3 eq -1) then begin
         frc = frc + emubudg(*,it)
         nterms=nterms+1
      endif
   endif
endfor
if (nterms eq 0) then print,'**** no frc terms ***'

end

