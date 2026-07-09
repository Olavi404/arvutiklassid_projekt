# Loogiline disain – Arvutiklasside kasutuse andmebaas

## Miks need tabelid?

Süsteem peab kirjeldama nelja põhilist asja: **millist klassi** kasutatakse, **kes** kasutab,
**mis liiki tegevuse** jaoks ja **millal**. Sellest tulenevad neli baastabelit:

- `classroom` – füüsiline arvutiklass koos mahtuvuse ja arvutite arvuga.
- `user_or_group` – broneeringu tegija (õpetaja või grupp/kursus), tüüp eristatakse ENUM-iga,
  et vältida eraldi tabelite dubleerimist (õpetajatel ja gruppidel on samad väljad: nimi, e-mail).
- `lesson_type` – lookup-tabel tunni tüübi jaoks (loeng, praktikum, eksam jne), et vältida
  vabateksti duplikaate ja võimaldada hõlpsalt uusi tüüpe lisada ilma struktuuri muutmata.
- `booking` – keskne faktitabel, mis seob eelneva kolme tabeli kokku ühe broneeringu kohta
  (klass + korraldaja + tüüp + kuupäev/kellaajad + osalejate arv + staatus).

## N..M seose lahendus

Reaalsuses võib ühes broneeringus (nt ühistunnis) osaleda **mitu** gruppi/õpetajat lisaks
korraldajale, ja üks grupp/õpetaja võib osaleda **paljudes** broneeringutes. See on
klassikaline N..M seos `booking` ja `user_or_group` vahel. Lahendasin selle vahetabeliga
`booking_participant (booking_id, participant_id)`, kus liitprimaarvõti (composite PK)
tagab, et sama osaleja ei saa sama broneeringu külge topelt lisatud. Korraldaja ise
(`organizer_id`) jääb `booking` tabelisse 1..N seosena, kuna igal broneeringul on täpselt
üks vastutav korraldaja, aga lisaosalejad käivad läbi vahetabeli.

## Ärireeglid ja nende rakenduskoht

| # | Reegel | Kus rakendub |
|---|--------|---------------|
| 1 | `end_time > start_time` (broneering ei tohi lõppeda enne, kui algab) | **CHECK constraint** tabelis `booking` (`chk_booking_time`) |
| 2 | `participants_count >= 0` (osalejate arv ei saa olla negatiivne) | **CHECK constraint** tabelis `booking` (`chk_booking_participants`) |
| 3 | Osalejate arv ei tohi ületada klassi mahtuvust (`participants_count <= classroom.capacity`) | **TRIGGER** (`trg_booking_capacity_insert` / `_update`), kuna CHECK ei saa MariaDB-s viidata teisele tabelile |
| 4 | Sama klassi kaks broneeringut ei tohi samal kuupäeval ajaliselt kattuda | **Rakenduse tase** (Node.js API, funktsioon `checkOverlap()` enne INSERT/UPDATE-t), kuna tegemist on kompleksse ajavahemike ristumise kontrolliga, mis on loetavam ja hooldatavam rakenduskoodis |

## Võtmed

- Kõik tabelid kasutavad `AUTO_INCREMENT` pealevõtit (PK).
- Välisvõtmed (`FK`): `booking.classroom_id → classroom.id`, `booking.organizer_id → user_or_group.id`,
  `booking.lesson_type_id → lesson_type.id`, `booking_participant.booking_id → booking.id`,
  `booking_participant.participant_id → user_or_group.id`.
- `booking_participant` kasutab liitvõtit `(booking_id, participant_id)` PK-na, mis ühtlasi
  välistab duplikaadid.
