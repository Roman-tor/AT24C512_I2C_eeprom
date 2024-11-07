  ; zapis / odczyt pamieci AT24Cxxx -I2C, podlacz.-SCL-PC.4, SDA- PC.0 portu uzytkownika 8255
  ; PC.0  SDA-pin 18, PC.4 SCL-pin 22 dla ZU50 lub /SDA-14a, SCL 13a dla ZU64 /
CI:       EQU 0FFC6h; CI - pobranie znaku z klawiatury; czekanie az puszczony a nastepnie wcisniety
CSTS:     EQU 0FFC3h ; badanie, czy klawisz wcisniety? CY=1 wcisniety, A-kod tablicowy klawisza
CIM:      EQU 0184h ;                                    CY=0 klawisz puszczony
PRINT:    EQU 1D4h  ; wysw. komunikatu wg (HL) plus PWYS
PARAM:    EQU 01F4h ; pobiera bajty do hl, podac PWYS
EXPR:     EQU 0213h ; pob. liczb na stos, rej. C ile
PA:       EQU 0E0h ; port uzytkownika; jesli dolozymy nastepna plytke MIK 89_TURBO, zmieniamy E0 na
PB:       EQU PA+1                         ;wlasciwy adres /E4 lub E8/, wg zworki J3
PC:       EQU PA+2
CONTR:    EQU PA+3 ; slowo kontrolne
P_SDA:    EQU PC ; port podlaczenia linii DATA /do wyboru
zap_EEP:  EQU 0A0h ; taki "adres" zapisu ma pamiec AT24Cxxx, jesli zworki sa ustawione na 0, piny 1,2 i 3 do GND
                    ; A1 na odczyt
pocz_EEP:  EQU 0FEA2h ; tu zapamietany adres pocz. zapisu EEPROM

  ORG #C000
klaw_G:
   ld sp, 0FF66h
   ld hl,EEP_G ; wlaczenie obslugi klawisza "G" w NMI
   ld (CI+1),HL
zap_str:
  ld sp, 0FF66h
  ld hl,z_o
  call print
  defb 80h
zap_odcz:
  call CSTS ; pobierz klawisz, tylko 0 lub 1, reszta klawiszy ignorowana
  jr nc, zap_odcz ; nie wcisnieto zadnego klawisza
  cp 0
  jr z, zapis
  cp 1
  jp z, odczyt
  jr zap_odcz

zapis: ; zapis do EEPROM <CAod> <CAdo> i <EEPROMod>
    ; pobranie 3. parametrow, pamiec /8-64kB/
  rst 10h
  defb 40h ; czysc 4 cyfry
  ld hl, caod
  call pob_adr
  push hl ; na stosie adres pocz. obszaru w CA zapisu
  ld hl, cado
  call pob_adr
  push hl  ; koniec obszaru do zapisu
  ld hl, eeod
  call pob_adr
  push hl
  pop ix ; do obliczen, czy koniec strony podczas zapisu
  ld (pocz_EEP), hl ; zapamietanie - poczatek wpisu do EEPROM
  pop hl ; do /CA/
  pop de ; od /CA/
  sbc hl, de
  inc hl
  inc hl
  ld c, l
  ld b, h ; w BC ilosc bajtow do zapisu w EEPROM 24Cxxx
  ;
  push de
  ld e, zap_EEP ; "adres" pamieci, tu A0, jako 1. pamiec /piny 1,2,i 3 do GND
  ld hl, (pocz_EEP); poczatkowy adres zapisu w EEPROM
  call wpisz_adr
zap_EEPROM: ; zapis bajtow do EEPROM
  ;ld a, zap_EEP; np. A0 "adres" do zapisu pamieci EEPROM AT24Cxxx
  ;ld e, zap_EEP
  ;call wpisz_adr ; poczatek wpisu do EEPROM

  pop hl ; pocz. obszaru w CA do zapisu
 zap1:
  ld e, (hl)
  call zap_bajt
  call sprawdz ; BC=BC-1 i czy BC=0
  jr z, zakoncz
  inc hl
  inc ix
     ; sprawdzenie czy koniec strony zapisu EEPROM
  ld a, IXL ;dfb 0ddh, 7dh ;  ld ml. bity IX do A
  and 1Fh ; sprawdz mlodsze bity i 4. bit /koniec str. co 32/20h bajty
         ; 3Fh - co 64/40h bajty, 7Fh - co 128/80h bajtów, FF - co 256/FFh bajtów
  cp 0h
  jr nz, zap1
      ; koniec strony: 0,20, 40, itd, przystosowane do EEPROM DS3231 8- kB, 32 kB, 64kB
K_STR_z64: ; koniec strony, wpisz nowy adres do EEprom
  PUSH BC
  PUSH HL
  CALL STOP
  PUSH IX
  POP HL
  LD E, zap_EEP
  CALL WPISZ_ADR
  POP HL
  POP BC
  JR ZAP1
;***********
odczyt: ; odczyt pamieci AT24Cxxx /8-64kB/
  rst 10h
  defb 40h ; czysc 4 cyfry
  ld hl, EEod
  call pob_adr
  ld (pocz_EEP), hl ; zapamietanie - poczatek odczytu w EEPROM
  ld hl, EEdo
  call pob_adr
  push hl  ; na stos - koniec obszaru do odczytu w EEPROM
  ld hl, CAod
  call pob_adr
  push hl
  pop ix ; poczatek zapisu w RAM CA odczytywanych bajtow

  pop hl ; do /w CA80/
  ld de, (pocz_EEP) ; od /EEPROM/
  sbc hl, de
  inc hl
  inc hl
  ld c, l
  ld b, h ; w BC ilosc bajtow do odczytu z EEPROM 24Cxxx
  ld e, zap_EEP ; bedzie wpis adresu, dlatego A0
  ld hl, (pocz_EEP); poczatkowy adres odczytu w EEPROM
  push bc  ; ilosc bajtow do odczytu
  CALL WPISZ_ADR ; start_I2C, wpis AO , wpis L, wpis H
  CALL start_I2C ; ponowny start_I2C
  LD E, zap_EEP+1 ; ustaw pamiec na odczyt np. A1
  call zap_bajt
  pop bc ; odtwórz ilosc bajtow do odczytu
czyt_bajty:
  CALL CZYT_BAJT; odczytuje bajt i zapisuje w RAM CA80 wg (IX)
  CALL M_ACK; wystaw ACK
  CALL SPRAWDZ ; czy BC = 0, koniec odczytu
  JR NZ, czyt_bajty
   ; koniec odczytu
  CALL RESET  ; zeruj pamiec 24Cxxx, wyswietl adres koncowy,

zakoncz:
  inc ix ; adres w EEPROM
  call STOP
  call reset
  ld hl, kon ; koniec
  call print
  defb 44h
  rst 8
  jp zap_str

  pob_adr:
  ;rst 10h
  ;defb 40h ; czysc 4 cyfry
  call print
  defb 44h
  call param ; pobierz adres "od"
  defb 40h
  ret

SPRAWDZ: ; zmniejsza BC o 1 - przy zapisie o odczycie pa. EEprom
  DEC BC
  XOR A
  CP C
  RET NZ
  CP B
  RET

wpisz_adr: ; wpis adresu poczatkowego zapisu
 ; przed wywolaniem w E adres pamieci np. A XXX R/W
            ; WEJ: E - "adres zapisu" pamieci EEprom /np. A0, A2, A4 itd
            ; HL - adres poczatku zapisu w EEprom
  PUSH BC
  CALL start_I2C
  CALL ZAP_BAJT
  LD E, H ; starszy bajt adresu w EEPROM
  CALL ZAP_BAJT
  LD E, L ; mLodszy bajt adresu
  CALL ZAP_BAJT
  POP BC
  RET

start_I2C: ; procedura START dla urzadzenia z I2C
  ld c, CONTR
 start_E:
  ld a, 9Bh ; konfiguracja portów  PA, PB i PC WEJ
  out (C), a
  nop
  ld a, 8Ah ; PA i PB WYJ, PC0-3 - WYJ, PC4-7 WEJ
  out (C), a
  nop
  ld a, 80h ;PA, PB, PC jako WYJ
  out (C),a
  ret

stop: ; procedura STOP dla urzadzenia /z komunikacja I2C/
  ld c, CONTR
  ld a, 8Ah
  out (C), a
  nop
  ld a, 9Bh
  out (C), a
  nop
  ld a, 90h ; PA - WEJ, PB i PC WYJ
  out (C),a
  halt
  halt
  halt
  ret

ZAP_BAJT: ; wpis bajtu do EEPROM, w E dana do zapisu
          ; PC4/SCL, PC0/SDA, jesli PA, PC jako WEJSCIE
  push bc
  push de
  ;ld a, (CONTR) ; rej. C - wybór portu - E3 (zlacze uzytk.) lub E7 (dodatkowe)
  ld C, CONTR
  LD D, 08H  ;ilosc bitów
 ZAP:
  LD A, E  ; odtworzenie danej do wpisu
  RLCA     ; przesun na lewo /na znacznik C/
  LD E, A  ; zapamietanie
  JR C, ZAPJEDYNKE  ; wyslij "1"
  ;wyslanie "0"
  LD A, 80H   ; PA i PC jako WYJ/ RES SDA i RES SCL stan niski
  OUT (C), A  ; ustawia dane "0" na SDA
 ZEGAR:
  CALL CLK
  DEC D  ; czy 8. bit?
  JR NZ, ZAP
   ; ACK:  ; info dla SLAVE, ze koniec bajtu
  LD A, 9BH  ; PA PC WEJ, poczatek 9. cyklu SCL "1"
  OUT (C), A
  NOP
  push bc
  ld b, 0FFh ; ilosc prób sprawdz. ACK
 ACK_0:
  dec b
  jp z, blad_ack
  IN A, (P_SDA) ; odczyt portu 
  BIT 0H, A ; testuj bit 0 (SDA=0 potwierdzenie, SDA=1 brak
  JR NZ, ACK_0 ; czekaj az ACK
  pop bc
  LD A, 90H
  OUT (C), A  ;PA WEJ, PC WYJ, koniec 9. cyklu SCL /SDA "1" SCL "0"
  pop de
  pop bc
  RET

 ZAPJEDYNKE:
  LD A, 90H  ;  PA WEJ/SDA/, PC WYJ/SCL/
  OUT (C), A ; ustawia dane "1" na SDA
  JR ZEGAR

 CLK:  ; port C.4 /
  dec c          ; E2-port PC zlacze systemowe lub E6-zlacze uzytk.
  LD A, 10H
  OUT (C), A ; SET SCL
  XOR A   ; RES SCL
  OUT (C), A
  inc c ; C = E3 lub E7
  RET

CZYT_BAJT: ; odczyt bajtu i zapis do RAM wg (IX)
  push bc
  ld C, contr
 ;    CZYT1:
  LD A, 90H ; PA WEJ, PC WYJ SDA "1" SCL "0"
  OUT (C), A
  ld d, 8; D - il. bitów = 8, E - jako bufor do odbieranych bitów = 0
  CZYT:    ; mo¿e byæ tylko ld d, 8  bo rej E "idzie" od zera
  CALL SCLH ; ustaw SCL na H
  nop
  nop    ; opoznienie
  IN A, (P_SDA) ; odczyt portu
  rrca ; przesun na CY
  rl e  ; przesuñ CY na bit 0 rej. E
  CALL SCLL ; ustaw SCL na L
  DEC D
  JR NZ, CZYT  ; czy ostatni bit?
  LD (IX+0H), E  ; zapisanie w pamiêci
  INC IX  ; ustaw RAM na zapis nastêpnego bajtu
  pop bc
  RET
 SCLH:  ; SCL /Port PC4/ na H
 LD A, 10H
 OUT (C), A
 RET

   SCLL:  ; SCL na L
 XOR A  ; ustaw SCL /port PC4/ na L
 OUT (C), A
 RET

M_ACK: ; Master /CA80/ wystawia ACK /"0"/ na SDA
  push bc
  ld c, contr ; np. E3,E8 lub EC
;m_ack1:
  LD A, 80H ; PA, PB, PC - WYJ, stan L
  OUT (C), A ; ustaw SDA na L /czytaj nastêpne bajty
  CALL CLK
  NOP ; opoznienie
  pop bc
  RET

RESET: ; reset pamieci AT24C16/512
  ld C, CONTR
  CALL start_I2C
  LD A, 90H
  OUT (C), A
  LD B, 9H ; 9. cykli zegara
     RES2:
  CALL CLK
  DEC B
  JR NZ, RES2
  CALL start_I2C
  NOP
  NOP
  CALL STOP
  RET

blad_ACK: ; jesli po 255 probach EEPROM sie nie zglosi
  push de ; ochrona E
  ld hl, no_ack ;  "no_ACK"
  call PRINT ; wyœw. "no ACK" na ca80
  defb 44h ; PWYSW
   ld a, CONTR
  ld L, a  ; "adres pamieci"
  pop de ; odtworzenie E
  ld H, e  ; port podlaczenia pamieci
  rst 20h ; wysw. rej. HL
  defb 40h
  rst 8 ; CF czekaj na klawisz
  jp zap_str

EEP_G: ; jesli klawisz "G", to skok do pocz. programu
   call CIM
   push AF
   cp 10H ; klawisz "G"
   jp z, zap_str
   pop AF
   ret
  ; napisy na CA80
z_o: defb 0bfh,5bh,77h,73h,86h,5ch,5eh,39h,255; "0 zap 1 odc"
caod: defb 39h,77h,5ch,5eh, 255
cado: defb 39h,77h,5eh,5ch, 255
eeod: defb 79h,79h,5ch,5eh, 255
eedo: defb 79h,79h,5eh,5ch, 255
kon:  defb 0,79h,54h,5eh, 255
no_ack: defb 54h,77h, 39h, 78h, 255 ; "no ACK" dla ca80
kon_CA: EQU ($-1)

