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

data segment use16
    gdt_null descr   <0,0,0,0,0,0>
    gdt_data descr   <data_size-1,0,0,92h,0,0>
    gdt_code16 descr <code16_size-1,0,0,98h,0,0>
    gdt_code32 descr <code32_size-1,0,0,98h,40h,0>
    gdt_stack descr  <stack_size-1,0,0,92h,40h,0> 
    gdt_screen descr <4095,8000h,0Bh,92h,0,0>
	gdt_data4gb descr <0FFFFh,0,0,92h,0CFh>
    gdt_size=$-gdt_null
	
	pdescr df 0

	datas=8
	code16s=16
	code32s=24
	stacks=32
	screens=40
	data4gbs=48
	
	
	idt label word
	idescr_0_31 idescr 32 dup(<0,code32s,0,8Fh,0>)
	timer_inter idescr <0,code32s,0,10001110b,0>
	keyboard_inter idescr <0,code32s,0,10001110b,0>

	idt_size=$-idt

	ipdescr df 0

	master_mask db 0
	slave_mask db 0

	mempos=200
	cursor_pos dw 0
	cursor_on_symb db 219
	cursor_off_symb db 32

	timer_counter db 0
	interval db 10

	is_running db 1

    asciimap db 0, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0, 0
    db 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']', 0, 0
    db 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', 0, 0, 0, '\'
    db 'Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/'

	color=1ah
	
	realmode db 'hello from real mode'
	realmode_len=$-realmode
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
	cmp al, 80h
	ja return_from_keyboard

	xor ah, ah
	xor ebx, ebx

	mov bx, ax

	mov di, cursor_pos
	mov ah, color
	mov al, asciimap[ebx]
    stosw

	mov cursor_pos, di


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

print_eax proc
	push ecx
	push ebx
	push edx

    add ebx, 10h
    mov ecx, 8
    mov dh, color

    print_symbol:
        mov dl, al
        and dl, 0Fh

        cmp dl, 10
        jl add_zero_sym
        add dl, 'A' - '0' - 10

    add_zero_sym:
        add dl, '0' 
        mov es:[ebx], dx 
        ror eax, 4       
        sub ebx, 2       
    loop print_symbol

	pop edx
	pop ebx
	pop ecx

    ret
print_eax endp

 output_dec:
        push edx
        push ecx
        push ebx
    
    mov ecx, 1024
    xor edx, edx
    div ecx

        mov ecx, 10
        mov bx, mempos
        prmem:
            xor edx, edx
            div ecx; edx:eax / 10
      
      add dl, '0'
            mov dh, color
            mov es:[bx], dx
            dec bx
            dec bx
            cmp eax, 0
        jnz prmem
    
    mov bx, mempos + 2
    mov ah, color
    mov al, 'k'
    mov es:[bx], ax
    inc bx
    inc bx
    mov al, 'b'
    mov es:[bx], ax

    pop ebx
    pop ecx
    pop edx
	jmp return_from_output

count_memory:
        mov ax, datas
        mov ds, ax

		push eax
        push ebx
        push edx
        mov ebx, 100000h
        mov eax, 400h
        xor edx, edx
    cloop:
        mov [ebx], eax
        cmp eax, [ebx]
        je cloop1
        jmp exit
    cloop1:
        add edx, 4h
    cloop2:
        add ebx, 4h
    
        jz exit
        jmp cloop
    exit:

    mov eax, edx
  ;xor edx, edx
  ;mov ebx, 1024
  ;div bx; eax / 1024
    jmp output_dec
return_from_output:

    pop edx
    pop ebx
    pop eax

	jmp return_from_count

start_pm:
	mov ax, datas
	mov ds, ax
	
	mov ax, stacks
	mov ss, ax
	
	mov ax, screens
	mov es, ax

    sti

	mov di, cursor_pos
    mov bx, offset protectedmode
    mov cx, offset protectedmode_len
    mov ah, color
  
loop_01:
    mov al, byte ptr [bx]
    inc bx
    stosw
    loop loop_01

	mov cursor_pos, di

main_loop:
	cmp is_running, 1
	jz main_loop

    jmp count_memory
return_from_count:
	mov ax, datas
	mov ds, ax

	mov gdt_code16.limit, 0FFFFh
	mov gdt_data.limit, 0FFFFh
	mov gdt_stack.limit, 0FFFFh
	mov gdt_screen.limit, 0FFFFh
	
	push ds
	pop ds
	push es
	pop es
	push ss
	pop ss
	
	db 0eah
	dd offset return_rm
	dw code16s

	code32_size=$-code32_starts
code32 ends

code16 segment use16
	assume cs:code16, es:code32, ds:data, ss:stack

start:	
	; clear screen
    mov ax, 3
    int 10h

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
	
	; линейный адрес сегмента кода -> база дескриптора кода (16р)
	xor eax, eax
	mov ax, cs
	shl eax, 4
	mov bx, offset gdt_code16
	mov [bx].base_l, ax
	shr eax, 16
	mov [bx].base_m, al
	
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
	
	mov eax, cr0
	or eax, 1
	mov cr0, eax 
	
	; protected mode
	
	db 66h
	db 0eah ; код команды far jmp
	dd offset start_pm
	dw code32s ; селектор сегмента команд


return_rm:
	mov eax, cr0
	and eax, 0FFFFFFFEh
	mov cr0, eax
	
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

    mov ax, 3
    int 10h

	mov ax, 4c00h
	int 21h
	
	code16_size=$-start
code16 ends

stack segment STACK use32
	stk_start db 256 dup(0)
	stack_size=$-stk_start
stack ends
end start
