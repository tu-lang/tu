r4:
    cmpxchgl    %edx , (%rcx)
    cmpxchgl    %edx , (%r9)
    cmpxchgl    %eax , %ecx
    cmpxchgl    %ecx , %eax
rmr1:
	lock cmpxchgb	%bl, (%rdx)
	lock cmpxchgb	%al, (%rdx)
	lock cmpxchgb	%cl, (%rdx)    
