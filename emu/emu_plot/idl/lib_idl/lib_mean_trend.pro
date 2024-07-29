pro lib_mean_trend,time,tcent,inva,a
; Compute inverse operator for estimating mean&trend
; Problem is;
;
;	/ 1  t(1)-tcent  \             /  rhs(1)  \
;       | 1  t(2)-tcent  |    /   \    |  rhs(2)  |
;       | 1  t(3)-tcent  | *  | x |  = |  rhs(3)  |
;            :                | y |	    :       
;	| 1  t(n-1)-tcent|    \   /    |  rhs(n-1)|
;	\ 1  t(n)-tcent  /	       \  rhs(n)  /
;
; where (x,y) are mean and trend, respectively, and tcent is mean time.
; 
; Input: time (time coordinate)
; Output: tcent (time offset)
;         inva (a 2 by length of time-series array to compute x,y)
;
ntime=n_elements(time)
tcent=total(max(time)+min(time))*0.5  

a=fltarr(ntime,2)
a(*,0)=1.
a(*,1)=time-tcent

inva=lib_pinv(a)

return
end


