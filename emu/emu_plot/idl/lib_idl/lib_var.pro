function lib_var,ss,FLAG=flag
; Compute variance wrt mean 

dummy = 32767.

if keyword_set( flag ) then begin
    ok = where(ss ne 32767., nok)
    if (nok ne 0) then begin 
        mean=total(ss(ok))/nok
        dummy=total((ss(ok)-mean)^2)/nok
    endif
endif else begin 
    mean=total(ss)/n_elements(ss)
    dummy=total((ss-mean)^2)/n_elements(ss)
endelse

return,dummy
end
