function lib_pinv,a,RANGE=mrange
; compute psedo inverse of a
; svd,a,s,u,v

if(n_elements(mrange) eq 0) then mrange = 1.e-4

svdc,a,s,u,v,/column,/double
zero=where(s lt max(s)*mrange)
if (zero(0) ne -1) then begin
   ss = size(a)
   adim = min([ss(1),ss(2)])
   print,'NON-zero singular values found ... ',adim-n_elements(zero)
   print,'zero singular values found ... ',n_elements(zero)
   ss=s
   ss(zero) = 1.
   si=lib_diag_mat(1./ss) 
   si(zero,zero)=0.
endif else begin
   si=lib_diag_mat(1./s)
endelse
dum = v#si#transpose(u)
return,dum
end
