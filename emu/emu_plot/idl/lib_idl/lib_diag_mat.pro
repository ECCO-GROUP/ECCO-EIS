function lib_diag_mat,a
dum1=size(a)
dum2=fltarr(dum1(1),dum1(1))
for i=0,dum1(1)-1 do dum2(i,i)=a(i)
return,dum2
end
