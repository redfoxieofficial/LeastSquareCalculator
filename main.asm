.model flat,c

.const 
public LsEpsilon			; With this, c++ will be able to read this
LsEpsilon real8 1.0e-12

.code
CalcLeastSquaresASM proc

	push ebp
	mov ebp,esp
	sub esp, 8			; Allocate 8 bytes under ebp

	xor eax,eax			; eax = 0
	mov ecx,[ebp+16]	; ecx = 'n' variable
	test ecx,ecx
	jle Done			; Jump if less or equal to zero

	mov eax, [ebp+8]	; eax = 'x' offset
	mov edx, [ebp+12]	; edx = 'y' offset

	fldz		; sum_xx
	fldz		; sum_xy
	fldz		; sum_y
	fldz		; sum_x

	;STACK SEEMS LIKE THIS: ST(0) = sum_x, ST(1) = sum_y, ST(2) = sum_xy, ST(3) = sum_xx


	@@:

	fld real8 ptr [eax]

	fld st(0)

	fld st(0)

	fld real8 ptr [edx]

	; FPU stack: y,x,x,x,sum_x,sum_y,sumxy,sumxx

	fadd st(5),st(0) ; sum_y += y

	; FPU stack: y,x,x,x,sum_x,sum_y = y,sumxy,sumxx

	fmulp ; x * y

	; FPU stack: xy,x,x,sum_x,sum_y,sumxy,sumxx

	faddp st(5),st(0) ; sum_xy += xy

	; FPU stack: x,x,sum_x,sum_y = y,sumxy = xy,sumxx

	fadd st(2),st(0) ; sum_x += x

	; FPU stack: x,sum_x = x,sum_y = y,sumxy = xy,sumxx

	fmulp ; x * x

	; FPU stack: xx,sum_x,sum_y,sumxy,sumxx

	faddp st(4),st(0) ; sum_xx += xx

	; FPU stack: sum_x = x,sum_y = y,sumxy = xy,sumxx = x * x



	add eax,8

	add edx,8

	dec ecx

	jnz @B


;double denom = n * sum_xx - sum_x * sum_x;
	fild dword ptr [ebp + 16]		

	;stack n,sum_x,sum_y,sum_xy,sum_xx

	fmul st(0),st(4)	;n * sum_xx

	fld st(1)
	fld st(0)

	;stack sum_x,sum_x, n * sum_xx, sum_x,sum_y,sum_xy,sum_xx
	fmulp

	;stack sum_x*sum_x, n * sum_xx, sum_x,sum_y,sum_xy,sum_xx
	fsubp			

	

	fst real8 ptr [ebp-8]		; denom to ebp-8
	;stack denom,sum_x,sum_y,sum_xy,sum_xx

	fabs		;abs(denom)
	fld real8 ptr [LsEpsilon]		
	fcomip st(0),st(1)		; Compare epsilon and abs(denom)
	fstp st(0)
	jae Done				; Jump if Epsilon >= abs(denom)

;*m (slope) = (n * sum_xy - sum_x * sum_y) / denom;

	fild dword ptr [ebp+16]
	;stack n,sum_x,sum_y,sum_xy,sum_xx

	fmul st(0),st(3)	; n * sum_xy
	fld st(2)
	fld st(2)

	;stack: sum_x,sum_y,n*sum_xy, denom,sum_x,sum_y,sum_xy,sum_xx

	fmulp		; stack: sum_x * sum_y, n*sum_xy, denom,sum_x,sum_y,sum_xy,sum_xx
	fsubp		; stack:  n*sum_xy - sum_x * sum_y, denom,sum_x,sum_y,sum_xy,sum_xx
	fdiv real8 ptr [ebp-8]		; ; stack:  (n*sum_xy - sum_x * sum_y) / denom,     ,sum_x,sum_y,sum_xy,sum_xx


	mov eax,[ebp+20]
	fstp real8 ptr [eax]
	; Slope is now given correctly



	;*b (intercept)= (sum_xx * sum_y - sum_x * sum_xy) / denom;
	fxch st(3)
	fmulp
	fxch st(2)
	fmulp
	fsubp

	fdiv real8 ptr[ebp-8]
	mov eax,[ebp+24]
	fstp real8 ptr[eax]
	mov eax,1

Done:
	mov esp,ebp
	pop ebp
	ret

CalcLeastSquaresASM endp
					end
