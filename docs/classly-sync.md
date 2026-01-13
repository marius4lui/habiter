# Classly Sync (Habiter)

Diese Skizze beschreibt, wie Habiter Classly-Daten einbindet.

## Backend (Classly)
- Endpunkte: `POST /api/token` (PAT holen), `GET /api/events`, `GET /api/subjects`.
- Auth: `Authorization: Bearer <token>`, Token ist klassen-gebunden, Scope `read:events`.
- Filter: `updated_since` (ISO), `limit` (max 500).

## Flutter-Client
- Service: `lib/services/classly_client.dart`
  - `issueToken(email, password, expiresInDays)` holt PAT via Login.
  - `fetchEvents(updatedSince, limit)` liefert `ClasslyEvent` inkl. Topics/Links.
  - `fetchSubjects()` liefert `ClasslySubject`.
- Abhängigkeit: `http` + `flutter_secure_storage` in `pubspec.yaml`.
- Token-Speicher: `ClasslySyncProvider` nutzt Secure Storage + `SharedPreferences`.
- UI: Settings-Screen hat Bereich "Classly Sync" (URL + E-Mail/Passwort, Token automatisch; optional manuell).

## Mapping-Idee
- HA → Aufgabe mit Fälligkeitsdatum.
- KA/TEST → Prüfung/Meilenstein, Topics als Checkliste.
- INFO → Notiz.
- `priority` → interne Priorität/Label, `subject_name` → Kategorie.

## Offene Punkte
- Hintergrund-Sync & UI-Anschluss (automatisch bei App-Start/Intervall).
- Konfliktregeln (Classly read-only, lokale Felder separat halten; Mapping in HabitProvider).
- Fehlermanagement (401/429/Timeouts) und Token-Rotation.
