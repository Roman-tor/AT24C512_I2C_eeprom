  ; program skanuje szynę I2C i wyszukuje podlaczone urządzenia
  ; na CA80 wyświetla "adres" do zapisu /CYF4, CYF3/ i odczytu /CYF1, CYF0/
  ; interfejs I2C podlaczony do:
  ; SDA - /PC0/ do pinu 18 złacza uzytkownika /port 8255 na płytce MIK89
  ; SCL - /PC4/ do pinu 22 złącza użytkwnika j.w.
  ; lub /SDA-14a, SCL 13a dla ZU64 / 
  ; +5V - do pinu 48 zlacza uzytkownika j.w.
  ; GND - do pinu 50 zlacza uzytkownika j.w.
CTRL:   equ 0E3h  ; slowo kontrolne portu uzytkownika /E3/
port_A: equ CTRL-3
port_B: equ CTRL-2
port_C: equ CTRL-1

  ORG 0EA00h
   skan:
  rst 10h
  defb 80h
     skan11:
  ld a, CTRL ; tu wpisujemy port jesli zlacze uzytkownik to E3
  
  ld H, 1 ; licznik urzadzen
  ld L, #E ; poczatkowy adres /odczyt/, bedzie zwiekszany o 2
            ; az do znalezienia urzadzenia

      skan1:
  call start_I2C
  push HL
  call zap_bajt
  cp 0 ; rej. B=0, wszystkie proby
  jr z, skan_d ; dalej
       ; znaleziono urzadzenie
  ld A, L
  rst 18h ; wysw. rej. A
  defb 23h ; PWYSW
  inc A
  rst 18h
  defb 20h
  ld a, H
  rst 18h
  defb 17h ; wysw. nr pamieci /1-7/
  rst 8; CF czekaj na wcisniecie klawisza
  inc L
  inc L
  inc H ; licznik urzadzen /nr pamieci /od 1 do max 8/ w moim przypadku 
  jr skan1 ; wyszukaj nastepne urzadzenie

     skan_d:
  inc L
  inc L
  ld A, L
  cp 0A0h
  jr c, sk2
  nop ;inc H; nr pamieci /1-8/  
 sk2:
  cp 0FEh ; ostatni mozliwy adres "odczytu"
  jr nz, skan1
   ; nie znaleziono urzadzenia
  ld hl, brak
  call 1D4h
  defb 60h
  rst 8 ; CF czekaj na wcisniecie klawisza
  jr skan ; jeszcze raz
    ;na CA80
     brak:  defb  78h, 5ch, 54h, 6, 79h, 58h, 0FFh ;"koniec"
       ; na LCD /przy szukaniu programow
  defb 0DDh, 0E2h ; marker nazwy programu dla szukania w EEPROM
  defm " SKANER I2C portP3", 255 ; koniec napisu

     ZAP_BAJT: ; wpis bajtu do EEPROM, w E dana do zapisu
            ; ustawia bity P0-P7 na PCF8574
            ;PC4/SCL, PA0/SDA, jesli PA, PC jako WEJSCIE
            ; WYJ: 0 -  brak urzadzenia, w rej. L adres urzadzenia
 ld E, L
    zap1:
 LD D, 08H  ;ilosc bitów
     ZAP:
 LD A, E  ; odtworzenie danej do wpisu
 RLCA     ; przesuń na lewo /na znacznik C/
 LD E, A  ; zapamiętanie
 JR C, ZAPJEDYNKE  ; wyslij "1"
     ;wyslanie "0"
 LD A, 80H   ; PA i PC jako WYJ/ RES SDA i RES SCL
 OUT (CTRL), A  ; ustawia dane "0" na SDA
   ZEGAR:
 CALL CLK
 DEC D  ; czy 8. bit?
 JR NZ, ZAP
   ACK:
 LD A, 89H  ; PA/9b/ PC WEJ, poczatek 9. cyklu SCL "1" /PC->89
 OUT (CTRL), A
 NOP
 ld b, 0FFh ; ilosc prób sprawdz. ACK
    ACK_0:
 dec b
 jr z, skan_d
 IN A, (port_c) ; odczyt portu PA
 BIT 0H, A ; testuj bit 0 (SDA=0 potwierdzenie, SDA=1 brak
 JR NZ, ACK_0 ; czekaj aż ACK
 LD A, 90H
 OUT (CTRL), A  ;PA WEJ, PC WYJ, koniec 9. cyklu SCL /SDA "1" SCL "0"
 call stop
 RET

     ZAPJEDYNKE:
 LD A, 81H  ;  PA /90/ WEJ/SDA/, PC WYJ/SCL/ PC/81
 OUT (CTRL), A ; ustawia dane "1" na SDA
 JR ZEGAR

    CLK:  ; port C.4 /
 LD A, 10H                  ; ld a, 9
 OUT (port_C), A ; SET SCL  ; out (CTRL), A
 XOR A   ; RES SCL          ; nop dec A
 clk1:
 OUT (port_C), A            ; out (ctrl), A
 RET                        ; ret

    SCLH:  ; SCL /Port PC4/ na H
 LD A, 10H            ; ld A, 8
 OUT (port_C), A      ; out (ctrl), a
 RET                  ; ret

   SCLL:  ; SCL na L                  ; ld A, 8    
 XOR A  ; ustaw SCL /port PC4/ na L   ; jr clk1
 OUT (port_C), A
 RET

     start_I2C: ; procedura START dla pamieci typu 24Cxxx, I2C
 ld a, 89h ; konfiguracja portów  PA/9b/, PB i PC WEJ pc89
 out (CTRL), a
 ld a, 88h ; PA/8A i PB WYJ, PC0-3 - WYJ, PC4-7 WEJ  Pc/88
 out (CTRL), a
 ld a, 80h ;PA, PB, PC jako WYJ
 out (CTRL),a
 ret
     stop: ; procedura STOP dla pamięci typu 24Cxxx, I2C
 ld a, 80h ; Pa /80 , Pc 80
 out (CTRL), a
 ld a, 88h ; Pa /88  Pc 88
 out (CTRL), a
 ld a, 89h ; PA/89/ - WEJ, PB I PC WYJ Pc 90
 out (CTRL) ,a
 halt
 halt
 halt
 ret
