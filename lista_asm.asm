%define OFFSET_NEXT  0
%define OFFSET_SUM   8
%define OFFSET_SIZE  16
%define OFFSET_ARRAY 24
extern malloc

BITS 64

section .text


; uint32_t proyecto_mas_dificil(lista_t*)
;
; Dada una lista enlazada de proyectos devuelve el `sum` más grande de ésta.
;
; - El `sum` más grande de la lista vacía (`NULL`) es 0.
;
global proyecto_mas_dificil
proyecto_mas_dificil:
	;prologo
	push rbp
	mov rbp, rsp
	;rdi == lista_t*
	    mov rax, 0
.ciclo:
    ;codigo de la guarda
    cmp rdi, 0 ;si es null
    je .fin;me voy, si no
		;codigo del while
		cmp [rdi + OFFSET_SUM], eax ;si lista menor a res
		jl .volver ;me voy, si no:
		mov rax, [rdi + OFFSET_SUM] ;res = rdi + OFFSET_SUM
	.volver:
		mov rdi, [rdi + OFFSET_NEXT] ;lista = lista->next
	jmp .ciclo
.fin:
    ;epilogo
	mov rsp, rbp
	pop rbp
	ret

; void tarea_completada(lista_t*, size_t)
;
; Dada una lista enlazada de proyectos y un índice en ésta setea la i-ésima
; tarea en cero.
;
; - La implementación debe "saltearse" a los proyectos sin tareas
; - Se puede asumir que el índice siempre es válido
; - Se debe actualizar el `sum` del nodo actualizado de la lista
;
global marcar_tarea_completada
marcar_tarea_completada:
	;prologo
	push rbp
	mov rbp, rsp
	;rdi = lsita_t* lista   -  rsi = size_t index
	;variables extra que necesito: curr_i
	;es void asi que rax esta libre -> rax = curr_i
	mov rax, 0 ;inicializo curr_i en 0
	.ciclo:
    ;codigo de la guarda
    cmp rdi, 0
    je .fin;me voy, si no:
	mov rcx, [rdi + OFFSET_SIZE] ;rcx := lista -> size
	add rcx, rax ;rcx := curr_i + lista -> size
	cmp rcx, rsi ;si curr_i + lista -> size > index
	jg .salgoDelCiclo ;si no:
		;codigo del while
		add rax, [rdi + OFFSET_SIZE]
		mov rdi, [rdi + OFFSET_NEXT]
    jmp .ciclo
.salgoDelCiclo:
	sub rsi, rax ;index -= curr_i
	;uso 2 registros temporales para guardar la posicion (a poner en 0)
	;y el valor y restarselo a sum
	mov r9, [rdi + OFFSET_ARRAY] ;r9 = uint32_t* array
	mov r10d, [r9 + 4 * rsi] ;r10d = uint32_t "numero a restarle a res"
	sub dword[rdi + OFFSET_SUM], r10d ;lista ->sum -= lista ->array[index]
	mov dword[r9 + 4 * rsi], 0 ;lista->array[index] = 0
.fin:
    ;epilogo
	mov rsp, rbp
	pop rbp
	ret

; uint64_t* tareas_completadas_por_proyecto(lista_t*)
;
; Dada una lista enlazada de proyectos se devuelve un array que cuenta
; cuántas tareas completadas tiene cada uno de ellos.
;
; - Si se provee a la lista vacía como parámetro (`NULL`) la respuesta puede
;   ser `NULL` o el resultado de `malloc(0)`
; - Los proyectos sin tareas tienen cero tareas completadas
; - Los proyectos sin tareas deben aparecer en el array resultante
; - Se provee una implementación esqueleto en C si se desea seguir el
;   esquema implementativo recomendado
;
global tareas_completadas_por_proyecto
tareas_completadas_por_proyecto:
	;rdi == lista_t* lista
	;variables que necesito: 
	;length (size_t) = lista_len(lista) - r12 (deberia usar no volatil para llamar a malloc)
	;results = malloc(length * sizeof(uint64_t)) - r13
	;i = contador -r14
	;lista - la muevo a r15 para no perderla

	;prologo
	push rbp
	mov rbp, rsp
	push r12 ;desalineada
	push r13 ;alineada
	push r14 ;desalineada
	push r15 ;alineada

	mov r15, rdi ;para preservarla
	call lista_len ;rax = len
	mov r12, rax ;r12 = length (para preservar tambien)

	shl rax, 6 ;rax = 64*len
	mov rdi, rax
	call malloc ;rax = results[0]
	mov r13, rax ;r13 = results[0]

	;codigo de la guarda
	mov r14, 0 ; i = 0
.ciclo:
	cmp r14, r12 ;si i >= length
	jge .fin ;me voy, si no
	mov rdi, [r15 + OFFSET_ARRAY]
	mov rsi, [r15 + OFFSET_SIZE]
	call tareas_completadas ;rax = numero a escribir en results[i]
	mov rcx, r14 ;rcx = i (temporal para indexar results)
	shl rcx, 6 ;multiplico por 64 (rcx = 64*i) == (i*sizeof(uint64_t))
	mov [r13 + rcx], rax ;escribo el resultado en results[i]
	inc r14
	jmp .ciclo 
.fin:
	mov rax, r13
	;epilogo
	pop r15
	pop r14
	pop r13
	pop r12
	mov rsp, rbp
	pop rbp
	ret
; uint64_t lista_len(lista_t* lista)
;
; Dada una lista enlazada devuelve su longitud.
;
; - La longitud de `NULL` es 0
;
lista_len:
	;prologo
	push rbp
	mov rbp, rsp
	;rdi == lista_t*
	    mov rax, 0
.ciclo:
    ;codigo de la guarda
    cmp rdi, 0 ;si es null
    je .fin;me voy, si no
		;codigo del while
		inc rax ;res = rdi + offset_array
		mov rdi, [rdi + OFFSET_NEXT] ;lista = lista->next
	jmp .ciclo
.fin:
    ;epilogo
	mov rsp, rbp
	pop rbp
	ret

; uint64_t tareas_completadas(uint32_t* array, size_t size) {
;
; Dado un array de `size` enteros de 32 bits sin signo devuelve la cantidad de
; ceros en ese array.
;
; - Un array de tamaño 0 tiene 0 ceros.
tareas_completadas:
	;prologo
	push rbp
	mov rbp, rsp
	;rdi == array ;rsi == size
	mov rax, 0 ;res
	mov rcx, 0 ;inicio contador en 0
.ciclo:
    ;codigo de la guarda
    cmp rcx, rsi ;si contador >= size
    jge .fin;me voy, si no
		;codigo del while
		cmp dword[rdi + 4*rsi], 0 ;si no es un cero
		jne .volver ;me voy, si no:
		inc rax ;res += 1
	.volver:
	inc rcx
	jmp .ciclo
.fin:
    ;epilogo
	mov rsp, rbp
	pop rbp
	ret