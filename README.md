# jukebox

Projekt końcowy z przedmiotu **Architektura Komputerów** (II rok informatyki, Uniwersytet Śląski). Założeniem tego projektu jest stworzenie programu syntezującego melodię odczytaną z dowolnego, prostego formatu plików. Program w całości napisany jest w asemblerze procesora **Intel 8086** w notacji **TASM** oraz nie wykorzystuje żadnych zewnętrznych bibliotek. 

Jako dodatkowe założenie postanowiliśmy zaimplementować możliwość odczytu wielościeżkowych plików w formacie *.mid*.

## Algorytm działania

1. Analiza całego pliku
    - Wstępne sprawdzenie czy plik zaczyna się od **MThd** (0x4D546864), oraz czy kończy się ciągiem **0x00FF2F00**
    - Odnalezienie i zapisanie adresów każdego z **MTrk** (0x4D54726B)
2. Wielościeżkowe odczytanie informacji z pliku *.mid*
    - Wyszukiwanie eventu *note on* (0x9) i odczytanie jego atrybutów

## Objaśnienie plików MIDI

**MIDI** to uniwersalny format do zapisywania jedno- bądź wielościeżkowych sekwencji melodycznych. Współcześnie jest szeroko stosowany jako podstawowe narzędzie profesjonalnych muzyków do zapisywania swoich melodii, które potem mogą być otwarzane przez wirtualne instrumenty **VST** (a także fizyczne **syntezatory**) a następnie nagrane. Łatwą edycję plików MIDI unożliwia oprogramowanie **DAW** które poza możliwością edycji sekwencji na bierząco pracując z instrumentem wirtualnym, pozwala na zrealizowanie całego utworu muzycznego, łącznie z miksem i masteringiem. 

### Ogólny opis

Plik **.mid** składa się z co najmniej jednej **ścieżki** (ang. *MIDI Track*), a ścieżka słada się ze **zdarzeń MIDI** (ang. *MIDI Event*) oraz / bądź **meta zdarzeń** (ang. *Meta Event*). Instrukcja odtwarzania dźwięku odbywa się na zasadzie zdarzenia *wciśnięcia klawisza* oraz *puszczenia klawisza* tak jak to się odbywa w prawdziwym instrumencie klawiszowym (dźwięk odtwarzany jest tylko od momentu wciśnięcia do momentu puszczenia klawisza). Każde zdarzenie przechowuje informacje: czas od poprzedniego zdarzenia, rodzaj zdarzenia, kanał MIDI (w którym zapisany jest instrument), nutę oraz głośność nuty (ang. *velocity*). Czas między kolejnymi zdarzeniami w ścieżce to **czas delta** (ang. *delta time*), który może być zarówno wartością nuty (długością jej trwania) jak i pauzą między nutami. Tak w skrócie można opisać sposób przechowywania melodii w ścieżce.

### Nagłówek pliku

