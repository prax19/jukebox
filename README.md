# jukebox

Projekt końcowy z przedmiotu **Architektura Komputerów** (II rok informatyki, Uniwersytet Śląski). Założeniem tego projektu jest stworzenie programu syntezującego melodię odczytaną z dowolnego, prostego formatu plików. Program w całości napisany jest w asemblerze procesora **Intel 8086** w notacji **TASM** oraz nie wykorzystuje żadnych zewnętrznych bibliotek. 

Jako dodatkowe założenie postanowiliśmy zaimplementować możliwość odczytu wielościeżkowych plików w formacie *.mid* oraz skorzystać z syntezatora karty dźwiękowej *ADlib*, którego emulacja jest wspierana przez DOSBoxa.

## Objaśnienie plików MIDI

**MIDI** to uniwersalny format do zapisywania jedno- bądź wielościeżkowych sekwencji melodycznych. Współcześnie jest szeroko stosowany jako podstawowe narzędzie profesjonalnych muzyków do zapisywania swoich melodii, które potem mogą być otwarzane przez wirtualne instrumenty **VST** (a także fizyczne **syntezatory**) a następnie nagrane. Łatwą edycję plików MIDI unożliwia oprogramowanie **DAW** które poza możliwością edycji sekwencji na bierząco pracując z instrumentem wirtualnym, pozwala na zrealizowanie całego utworu muzycznego, łącznie z miksem i masteringiem. 

Plik **.mid** składa się z co najmniej jednej **ścieżki** (ang. *MIDI Track*), a ścieżka słada się ze **zdarzeń MIDI** (ang. *MIDI Event*) oraz / bądź **meta zdarzeń** (ang. *Meta Event*). Instrukcja odtwarzania dźwięku odbywa się na zasadzie zdarzenia *wciśnięcia klawisza* oraz *puszczenia klawisza* tak jak to się odbywa w prawdziwym instrumencie klawiszowym (dźwięk odtwarzany jest tylko od momentu wciśnięcia do momentu puszczenia klawisza). Każde zdarzenie przechowuje informacje: czas od poprzedniego zdarzenia, rodzaj zdarzenia, kanał MIDI (w którym zapisany jest instrument), nutę oraz głośność nuty (ang. *velocity*). Czas między kolejnymi zdarzeniami w ścieżce to **czas delta** (ang. *delta time*), który może być zarówno wartością nuty (długością jej trwania) jak i pauzą między nutami. Tak w skrócie można opisać sposób przechowywania melodii w ścieżce.

Więcej informacji na temat struktury plików MIDI można bez problemu odnaleźć [w internecie](https://web.archive.org/web/20141227205754/http://www.sonicspot.com:80/guide/midifiles.html) oraz [w oficjalnej specyfikacji](https://midi.org/specifications/file-format-specifications/standard-midi-files).

## Sposób działania

By zrozumieć strukturę pliku MIDI warto przejrzeć przewodnik jak [ten](https://web.archive.org/web/20141227205754/http://www.sonicspot.com:80/guide/midifiles.html), bądź sięgnąć po oprogramowanie jak np aplikacja [MIDIopsy](https://github.com/jeffbourdier/MIDIopsy), która potrafi odczytać i wypunktować bajt po bajcie poszczególne elementy.

### Analiza pliku

Program rozpoczyna działanie od nagłówka **MThd** po którym następują podstawowe informacje o pliku MIDI jak na przykład ilość ścieżek. Program pobiera te informacje oraz zapisuje w zmiennych. Cały nagłówek ma **14 bajtów**, na 15 bajcie zawsze zaczyna się pierwsza ścieżka programu.

Każda ścieżka rozpoczyna się od ciągu **MTrk**, po którym 4 następne bajty przechowują informację o tym ile bajtów zawiera dany track. W celu szybkiego odnajdowania ścieżek, program zapisuje adresy (indeks bajtu pliku MIDI) każdego tracku w zmiennej, a te adresy odnajduje poprzez odczytane długości ścieżki znajdujące się w nagłówku tracku. 

Po odnalezieniu adresów tylu ścieżek, ile zostało podanych w nagłówku pliku można przejść do właściwego odczytu. Program w tym momencie pyta o numer ścieżki, która ma być odtworzona.

### Odczyt zapisu nutowego

Program znając już położenie początku ścieżki, przenosi się do odpowiedniego bajtu programu, pomija kolejne 8 bajtów (by wskaźnik znalazł się nad początkiem pierwszego zdarzenia) oraz rozpoczyna odczyt. 

Każde zdarzenie zaczyna się od czasu delta, więc program wywołuje przerwanie odpowiedzialne za opóźnienie na odpowiedni czas. Gdy czas delta wynosi 0, zdarzenie wykonuje się natychmiastowo. Następny bajt odnosi się do rodzaju zdarzenia. Wyróżniamy **meta events** oraz **track events**. 
- Meta events nie odnoszą się bezpośrednio do ścieżki, a do całego pliku MIDI, dlatego ich długość nie jest z góry narzucona. Mogą one przechowywać na przykład dane tekstowe, ale również ustawienia tempa utworu. Pierwszy bajt meta eventu to **0xFF**, drugi określa typ zdarzenia. Długość meta eventu znajduje się w jego trzecim bajcie, a w czwartym i następnym dane które przechowuje.
- Track events to stricte zdarzenia ścieżki. Zawierają informacje związane bezpośrednio z symulowaniem zachowania kontrolera MIDI, więc umożliwiają nam one na przykład zapisać w pliku MIDI zmianę parametrów syntezatora. Najważniejszym jednak ich zadaniem jest "naciskanie" wirtualnych klawiszy syntezatora, gdyż *Note On* oraz *Note off* są właśnie zdarzeniami ścieżki. Pierwszy bajt zawiera numer zdarzenia (4 starsze bity) oraz numer *kanału MIDI* (4 młodsze bity) a kolejne dwa to parametry. W przypadku zdarzań wciśnięcia/puszczenia klawisza, pierwszy parametr mówi o numerze *nuty midi* (1 - 127), a drugi o parametrze velocity (głośność, którą można bezpośrednio odnieść do mocy wciśnięcia klawisza kontrolera).

Trudnością w odczycie plików midi jest z pewnością zmienna długość zdarzeń oraz w wielu przypadkach czasu delta. W przypadku track eventów należało przygotować przedefiniowane funkcje, które działały w określony sposób by pominąć odpowiednią ilość bajtów przed kolejnym zdarzeniem i odpowiednio je rozpoznać. W przypadku meta eventów sprawa jest prostrza - wystarczy odczytać bajt zawierający długość. Czas delta natomiast wymagał rozpoznania kolejnych bajtów jako jedna, [wielobajtowa zmienna](http://www.ccarh.org/courses/253/handout/vlv/). Sam odczyt nie jest niczym skomplikowanym gdyż wymaga jedynie sprawdzenia czy najstarszy bit w bajcie jest równy 1, jeżeli tak - wartość składa się jeszcze z co najmniej jednego bajtu, jeżeli natomiast nie - delta time już nie zawiera więcej bajtów. Należy zatem odczyt prowadzić z bardzo dużą precyzją. Najmniejszy błąd w tej swerze powoduje "wykolejenie się" wskaźnika ze ścieżki co skutkuje odczytaniem błędnych bajtów i odegraniem nieprawidłowych wartości.

Każde kolejne zdarzenie następuje po poprzednim w pętli aż do wystąpienia meta evetnu **0x2F**, który mówi nam o końcu ścieżki.
