.386P

; Структура дескриптора сегмента
descr   struc
    limit   dw  0
    base_l  dw  0
    base_m  db  0
    attr_1  db  0
    attr_2  db  0
    base_h  db  0
descr   ends

; Структура для описания дескрипторов прерываний
idescr struc 
	offs_l  dw 0
	sel 	dw 0
	cntr	db 0
	attr	db 0
	offs_h	dw 0
idescr ends

stack segment STACK use32
	stk_start db 256 dup(0)
	stack_size=$-stk_start
stack ends

data segment use32
    gdt_null descr   <0,0,0,0,0,0>
    gdt_data descr   <data_size-1,0,0,92h,40h,0>
    gdt_code32 descr <code32_size-1,0,0,98h,40h,0>
    gdt_stack descr  <stack_size-1,0,0,92h,40h,0> 
    gdt_screen descr <4095,8000h,0Bh,92h,0,0>
	gdt_data4gb descr <0FFFFh,0,0,92h,0CFh>
    gdt_size=$-gdt_null
	
	pdescr df 0

	datas=8
	code32s=16
	stacks=24
	screens=32
	data4gbs=40
	
	
	idt label word
	idescr_0_12 idescr 13 dup(<0,code32s,0,8Fh,0>)
	idescr_13 idescr 1 dup(<0,code32s,0,8Fh,0>)
	idescr_14_31 idescr 18 dup(<0,code32s,0,8Fh,0>)
	timer_inter idescr <0,code32s,0,10001110b,0>
	keyboard_inter idescr <0,code32s,0,10001110b,0>

	idt_size=$-idt

	ipdescr df 0

	master_mask db 0
	slave_mask db 0

    memmsg_pos=80*2
    mempos=80*2+mem_msg_len*2
    mem_msg db 'Memory: '
    mem_msg_len=$-mem_msg

	cursor_pos dw 80*4
	cursor_on_symb db 219
	cursor_off_symb db 32

	timer_counter db 0
	interval db 10

	is_running db 1

    asciimap db 0, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0, 0
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 0, 0
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', 0, 0, 0, '\'
    db 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/'
	db 0, 0, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 0, 0
    db 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', 0, 0
    db 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', 0, 0, 0, '|'
    db 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?'

	color=1ah
	color_black=0h

    rm_msg_wait db 27, '[29;44mAny key to enter protected mode!', 27, '[0m$'
    rm_msg  db 27, '[29;44mNow in Real Mode again! ', 27, '[0m$'
	
    pm_msg_pos=0
	protectedmode db 'hello from protected mode'
	protectedmode_len=$-protectedmode

	data_size=$-gdt_null
data ends

code32 segment use32
	assume cs:code32, ds:data, ss:stack

code32_starts:
dummy proc
	iretd
dummy endp

inter_13 proc
    pop eax
    iretd
inter_13 endp

timer_int proc
	push di
	push bx
	push cx
	push ax

	mov di, cursor_pos

    cmp timer_counter, 10
	je cursor_on

	cmp timer_counter, 20
	jne inc_timer_counter

    mov al, cursor_off_symb
    mov ah, color
    stosw
	xor eax, eax
	mov timer_counter, al
	jmp inc_timer_counter

cursor_on:
    mov al, cursor_on_symb
    mov ah, color
    stosw

inc_timer_counter:
	mov al, timer_counter
	inc al
	mov timer_counter, al

	pop ax
	pop cx
	pop bx
	pop di

	mov al, 20h
	out 20h, al

	iretd

timer_int endp

new_keyboard proc 
	push di
	push bx
	push cx
	push ax

	in al, 60h
	cmp al, 01h
	jnz print_value

	mov is_running, 0
	jmp return_from_keyboard

print_value:
    cmp al, 80h  ;  При отпускании клавиши контроллер клавиатуры посылает в тот же порт скан-код, увеличенный на 80h
	ja return_from_keyboard

    cmp al, 0Eh
    je backspace

	xor ah, ah
	xor ebx, ebx

	mov bx, ax

	mov di, cursor_pos
	mov ah, color
	mov al, asciimap[ebx]
    stosw

	mov cursor_pos, di

    jmp return_from_keyboard

backspace: 
    backspace_loop:
        mov dl, ' '
        mov al, dl
        mov ah, color_black

        mov bx, cursor_pos
        mov es:[bx], ax
        sub cursor_pos, 2

        mov bx, cursor_pos
        mov es:[bx], ax
    jmp return_from_keyboard


return_from_keyboard:
	in al, 61h
	or al, 80h
	out 61h, al
	and al, 7Fh
	out 61h, al

	mov al, 20h
	out 20h, al

	pop ax
	pop cx
	pop bx
	pop di

	iretd
new_keyboard endp

output_dec proc near
    push edx
    push ecx
    push ebx
    xor edx, edx
    mov ecx, 100000h
    div ecx
    mov ecx, 10
    mov bx, mempos
    prmem:
        xor edx, edx
        div ecx
        add dl, '0'
        mov dh, color
        mov es:[bx], dx
        dec bx
        dec bx
        cmp eax, 0
    jnz prmem

    mov bx, mempos
    add bx, 2
    mov dl, 'M'
    mov es:[bx], dx

    add bx, 2
    mov dl, 'b'
    mov es:[bx], dx

    pop ebx
    pop ecx
    pop edx
    ret
output_dec endp

countMemory proc 
    mov ax, data4gbs
    mov ds, ax

    push eax
    push ebx
    push edx
	push ecx
    mov ebx, 100000h
    mov eax, 0AEh
    xor ecx, ecx
cloop:
	mov dh, [ebx]
    mov [ebx], eax
    cmp eax, [ebx]
    je cloop1
    jmp exit
cloop1:
    inc ecx
cloop2:
	mov [ebx], dh
    inc ebx

    jz exit
    jmp cloop

exit:

    mov eax, ecx
    add eax, 100000h
    call output_dec

    pop ecx
    pop edx
    pop ebx
    pop eax
    ret
countMemory endp

start_pm:
	mov ax, datas
	mov ds, ax
	
	mov ax, stacks
	mov ss, ax
	
	mov ax, screens
	mov es, ax

	mov edi, pm_msg_pos
    mov ebx, offset protectedmode
    mov ecx, offset protectedmode_len
    mov ah, color
  
loop_01:
    mov al, byte ptr [ebx]
    inc ebx
    stosw
    loop loop_01

    mov edi, memmsg_pos
    mov ebx, offset mem_msg
    mov ecx, offset mem_msg_len
    mov ah, color

loop_02:
    mov al, byte ptr [bx]
    inc ebx
    stosw
    loop loop_02

    call countMemory
    mov ax, datas
    mov ds, ax
    
    ;Разрешение прерываний
    sti
    xor al, al
    out 70h, al

main_loop:
	cmp is_running, 1
	jz main_loop


	mov ax, datas
	mov ds, ax

    cli

	;mov gdt_code16.limit, 0FFFFh
	;mov gdt_data.limit, 0FFFFh
	;mov gdt_stack.limit, 0FFFFh
	;mov gdt_screen.limit, 0FFFFh
	
	;push ds
	;pop ds
	;push es
	;pop es
	;push ss
	;pop ss

	mov eax, cr0
	and eax, 0FFFFFFFEh
	mov cr0, eax
	

    db 0eah
    dd offset return_rm
    dw code16

	code32_size=$-code32_starts
code32 ends

code16 segment use16
	assume cs:code16, ds:data, ss:stack
start:	
	xor eax, eax
	mov ax, data
	mov ds, ax

	; линейный адрес сегмента данных -> база дескриптора данных
	shl eax, 4
	
	mov ebp, eax

	mov bx, offset gdt_data
	mov [bx].base_l, ax
	shr eax, 16
	mov [bx].base_m, al

	; clear screen
    mov ax, 3
    int 10h

    mov ah, 09h
    lea dx, rm_msg_wait
    int 21h
    xor dx, dx
    mov ah, 2
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h

    ; ожидание ввода символа
    mov ah, 10h
    int 16h

    ; очистить экран
    mov ax, 3
    int 10h

	; линейный адрес сегмента кода -> база дескриптора кода (32р)
	xor eax, eax
	mov ax, code32
	shl eax, 4
	mov bx, offset gdt_code32
	mov [bx].base_l, ax
	shr eax, 16
	mov [bx].base_m, al
	
	; линейный адрес сегмента стека -> база дескриптора стека
	xor eax, eax
	mov ax, ss
	shl eax, 4
	mov bx, offset gdt_stack
	mov [bx].base_l, ax
	shr eax, 16
	mov [bx].base_m, al
	
	mov dword ptr pdescr+2, ebp ; линейный адрес gdt
	mov word ptr pdescr, gdt_size-1
	
	lgdt pdescr

	;setup new int_08
    xor eax, eax
    mov ax, code32
    mov es, ax
    lea eax, es:timer_int
    mov timer_inter.offs_l, ax
    shr eax, 16
    mov timer_inter.offs_h, ax

	;setup new int_09
    lea eax, es:new_keyboard
    mov keyboard_inter.offs_l, ax
    shr eax, 16
    mov keyboard_inter.offs_h, ax

    ; Сохраним маски прерываний контроллеров
    in al, 21h
    mov master_mask, al
    in al, 0A1h
    mov slave_mask, al

    ;Инициализация ведущего контроллера
    mov al, 11h
    out 20h, al                     
    mov al, 32
    out 21h, al                     
    mov al, 4
    out 21h, al
    mov al, 1
    out 21h, al

    ;Запрет прерываний в ведомом контроллере
    mov al, 0FFh
    out 0A1h, al

    ;Запрет прерываний в ведущем контроллере
    mov al, 0FCh
    out 21h, al

    ;Загрузка IDRT
    mov  word ptr  ipdescr, idt_size-1 
    xor eax, eax
    mov ax, offset idt
    add eax, ebp
    mov  dword ptr ipdescr + 2, eax 
    lidt fword ptr ipdescr 
	
	in  al, 92h
    or  al, 2
    out 92h, al

	cli
    mov al, 80h
    out 70h, al
	
	mov eax, cr0
	or eax, 1
	mov cr0, eax 
	
	; protected mode
	
	db 66h
	db 0eah ; код команды far jmp
	dd offset start_pm
	dw code32s ; селектор сегмента команд


return_rm:
	db 0eah
	dw offset go
	dw code16
	
go:
	mov ax, data
	mov ds, ax
	
	mov ax, stack
	mov ss, ax
	mov sp, 256

    ; Перепрограммирование контроллера
    mov al, 11h
    out 20h, al
    mov al, 8
    out 21h, al
    mov al, 4
    out 21h, al
    mov al, 1
    out 21h, al

    ; восстановление масок
    mov al, master_mask
    out 21h, al
    mov al, slave_mask
    out 0A1h, al

    mov ax, 3FFh
    mov word ptr ipdescr, ax
    xor eax, eax
    mov dword ptr ipdescr+2, eax
    lidt ipdescr

    ;A20
    in  al, 70h 
    and al, 7Fh
    out 70h, al

	sti

    ; очистить экран
    mov ax, 3
    int 10h

    mov ah, 09h
    lea dx, rm_msg
    int 21h
    xor dx, dx
    mov ah, 2
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h

	mov ax, 4c00h
	int 21h

code16 ends
end start
