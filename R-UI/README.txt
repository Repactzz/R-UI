R-UI — Version 1.0.3
World of Warcraft: Forever | Interface 16001

INSTALLATION
1. WoW Forever vollständig beenden.
2. ZIP entpacken.
3. Den Ordner R-UI in folgenden Ordner kopieren:
   World of Warcraft\_forever_\Interface\AddOns\
4. Die Datei R-UI.toc muss sich direkt im Ordner
   AddOns\R-UI\ befinden (keine doppelte Verschachtelung).
5. Spiel starten und R-UI in der Addon-Liste aktivieren.
6. Gruppenrahmen im Bearbeitungsmodus auf Raid-/kompakte Gruppenrahmen
   stellen (wie im Screenshot). Einer Gruppe beitreten.

ANZEIGE
- Dunkler Hintergrund, blauer Mana-Füllstand und weißer Text:
  aktuelles Mana | Prozent (z. B. 1200 | 80%).
- Nur party1 bis party4, niemals der eigene Charakter.
- Keine Anzeige bei Mitgliedern ohne Mana bzw. offline.
- Keine Schlachtzugsanzeige. Keine Änderungen an Klickaktionen.
- Ist der native Ressourcenbalken sichtbar und ausreichend hoch,
  wird dessen Platz genutzt. Andernfalls liegt die Anzeige am unteren
  Rand des HP-Balkens. So werden dicht stehende Rahmen nicht überlappt.
- Wenn der Client die Prozentanzeige nicht gestattet, erscheint --%.
  Neu erstellte Rahmen werden nach Verlassen des Kampfs eingerichtet.

CHATBEFEHLE
/rui             Hilfe
/rui on          Aktivieren
/rui off         Deaktivieren
/rui height 13   Höhe des eigenen Balkens (8–24 UI-Einheiten; begrenzt auf
                 30 % des HP-Balkens, mindestens 8; bei geschützter Höhe
                 zuletzt bekannte Höhe oder fester Einstellungswert)
/rui reset       Standardwerte
/rui status      Zahl erkannter Rahmen und sichtbarer Anzeigen
