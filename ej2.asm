
global filtro
extern malloc

;########### SECCION DE DATOS
section .data
dar_vuelta db 11100100b
;########### SECCION DE TEXTO (PROGRAMA)
section .text

;int16_t* operaciones_asm (const int16_t* entrada, unsigned size)
filtro:
    ;rdi = inst16_t* entrada rsi = unsigned size
    ;tengo que llamar a malloc para poder asignar espacio de salida
    ;prologo
	push rbp
	mov rbp, rsp
    push rdi
    push rsi ;esto no hace falta pero alinea la pila
    push r12
    push r13
    ;llamo a malloc
    mov r12, rsi ;r12 = size
    mov r13, rdi ;r13 = entrada
    shl rsi, 5 ;rsi = rsi *32
    mov rdi, rsi ;parametro para malloc
    call malloc
    mov rax, rcx ;conservo en rcx el valor original de rax para usar rax como iterador
    ;rax = int16_t* salida
    mov rdx, 0 ;uso rdx como contador
.ciclo:
    cmp rdx, r12 ;si contador es mayor o igual a size/8 
    jge .fin ;me voy, si no:

    ;xmm1 == entrada[i]
    movdqu  xmm1, [r13]
    
    ;con estas instrucciones extiendo el signo y paso de tener en xmm1 el primer elemento a tenerlo en arrays de 32 bits en xmm1 y xmm2
    pxor       xmm3, xmm3
    movdqa     xmm2, xmm1
    pcmpgtb    xmm3, xmm1     ; upper 8-bit to attach to each BYTE = src >= 0 ? 0 : -1
    punpcklbw  xmm1, xmm3     ; lower 8 WORDS ;i a i + 3
    punpckhbw  xmm2, xmm3     ; upper 8 WORDS ;i+4 a i + 7

    movdqa xmm0, xmm1 ;xmm0 = de 0 a 3
    movdqa xmm4, xmm1 ;xmm4 = de 0 a 3 tambien
    movdqa xmm5, xmm1 ;xmm5 = de 0 a 3 tambien
    movdqa xmm6, xmm1 ;xmm6 = de 0 a 3 tambien
    movdqa xmm3, xmm2 ;xmm3 = de 4 a 7
    pshufd xmm2, xmm2, 11100100b;xmm2 = de 7 a 4

    paddd xmm0, xmm2;xmm5 = de 0 a 3 + de 7 a 4 (parte baja de parte 1)
    psubd xmm1, xmm2;xmm1 = de 0 a 3 - de 7 a 4 (parte alta de parte 1)

    packssdw xmm0, xmm1 ;parte 1

    psubd xmm5, xmm3 
    paddd xmm6, xmm3 ;parte baja y alta de parte 2

    packssdw xmm5, xmm6 ;parte 2

    pmulhw xmm0, xmm5 ;multiplico partes 1 y 2

    movdqu [rax], xmm0

    add rax, 16 ;le sumo 16 bytes que son los que escribi 
    ;son 8 elementos asi que 8 * 16 bits = 16 bytes
    add r13, 16 ;le sumo 16 bytes que son los que fetchie
    add rdx, 8
    jmp .ciclo
.fin:
    mov rcx, rax
    ;epilogo
    pop r13
    pop r12
    pop rsi
    pop rdi
    mov rsp, rbp
	pop rbp
	ret

;Comentarios:
;no me anduvo malloc y no tuve forma de 
;poder debuguear, sospecho que puse mal algun numero y eso hace entrar a posiciones que no deberia