StkSeg SEGMENT PARA STACK 'STACK'
    DB      200h DUP (?)
StkSeg  ENDS
DataS   SEGMENT WORD 'DATA'
DataS Ends
Code    SEGMENT WORD 'CODE'
        ASSUME  CS:Code, DS:DataS
main:
    mov ax, 3508h
    int 21h
    mov AH,4Ch
    int 21h
Code    ENDS
        END main
