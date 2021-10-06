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
    gdt_size=$-gdt_null

	
	pdescr df 0

	datas=8
	code16s=16
	code32s=24
	stacks=32
	screens=40
	
	
	idt label word
	idescr_0_31 idescr 32 dup(<0,code32s,0,8Fh,0>)
	timer_inter idescr <0,code32s,0,10001110b,0>
	idt_size=$-idt

	ipdescr df 0

	master_mask db 0
	slave_mask db 0
	
	row=13
	col=26
	color=1ah
	
	realmode db 'hello from real mode'
	realmode_len=$-realmode
	protectedmode db 'hello from protected mode'
	protectedmode_len=$-protectedmode
	
	data_size=$-gdt_null
data ends

code32 segment para public 'code' use32
	assume cs:code32, ds:data, ss:stack

dummy proc
	db 66h
	iret
dummy endp

timer_int proc
	push di
	push bx
	push cx
	push ax

	mov di, (row + 1) * 160 + col * 2
	; mov bx, offset protectedmode
	; mov cx, offset protectedmode_len
	mov ah, color
	mov al, 'm'
	stosw

;loop_01:
	;mov al, byte ptr [bx]
	;inc bx
;	loop loop_01

	pop di
	pop bx
	pop cx
	pop ax

	db 66h
	iret

timer_int endp
	
start_pm:
	mov ax, datas
	mov ds, ax
	
	mov ax, stacks
	mov ss, ax
	
	mov ax, screens
	mov es, ax

        sti

;forever loop
	mov ecx, 1
forever:
	inc ecx
loop forever
	
	
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

	code32_size=$-start_pm
code32 ends

code16 segment para public 'code' use16
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

        ;setup IDT0..31 !!
        xor eax, eax
        mov ax, code32
        mov es, ax
        lea eax, es:timer_int
        mov timer_inter.offs_l, ax
        shr eax, 16
        mov timer_inter.offs_h, ax

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
        mov al, 0FEh
        out 21h, al

        ;Загрузка IDRT
        mov  word ptr  ipdescr, idt_size-1 
        xor eax, eax
        mov ax, offset idt
        add eax, ebp
        mov  dword ptr ipdescr + 2, eax 
        lidt fword ptr ipdescr 
	
	; линия а20
        ;****************************************************

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

        ; ?????
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
	
	mov ax, 4c00h
	int 21h
	
	code16_size=$-start
code16 ends

stack segment STACK use32
	stk_start db 256 dup(0)
	stack_size=$-stk_start
stack ends
end start
