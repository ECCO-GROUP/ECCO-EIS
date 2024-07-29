pro lib_label,names,names_col
; Print color-coded label after plot 

  nterms = n_elements(names)

; Split x-range 
   x_range=!X.Crange
   x_min = x_range(0)
   x_max = x_range(1)
   tdum = x_min + (findgen(nterms)+1)*(x_max-x_min)/(nterms+1)

; Set y height 
   y_range=!Y.Crange
   y_min = y_range(0)
   y_max = y_range(1)
   ydum = y_max - (y_max-y_min)*0.1

; Print labels 
   for i=0,nterms-1 do begin
      xyouts,[tdum(i)],[ydum],names(i),col=names_col(i)
   endfor

end
