program AT24C512 pozwala za zapis/odczyt popularnych pamięci EEPROM /również AT24C256/128/64/ na CA80 podłaczonych wg schematu na pliku PDF /port PC.0 jako SDA i PC.4 jako SCL/,
adres AO zapis, A1 odczyt. 
Jeśli masz inny adres, np. A2/A3 musisz zmienić wiersz 14 w pliku ASM - "zap_EEP" wpisując tam A2.

Jesli nie wiesz jaki masz adres Twojej EEOROM, wykorzystaj program "SKANER_I2C", podłaczając pamięc jak wyżej.