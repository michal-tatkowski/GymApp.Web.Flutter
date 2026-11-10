# GymApp — aplikacja mobilna (Flutter)

Aplikacja treningowa na **Androida i iOS** (Flutter 3.47, Dart 3.13). Backend: [GymApp.API](https://github.com/michal-tatkowski/GymApp.API).
Identyfikator aplikacji: `pl.tatkowski.gymapp` (Android `applicationId`, iOS bundle id) — **nie zmieniać po pierwszej publikacji**.

Web (`flutter run -d chrome`) zostaje jako szybkie narzędzie do developmentu, ale docelowo to aplikacja mobilna.

## Uruchomienie

Najpierw API na komputerze (`GymApp.API`: `dotnet run --project Web.Api --launch-profile http`) — słucha na `0.0.0.0:5035`.

| Gdzie | Komenda | Adres API |
|---|---|---|
| **Emulator Androida** | `flutter run` | `http://10.0.2.2:5035` (domyślnie — tak emulator widzi komputer) |
| **Symulator iOS** (Mac) | `flutter run` | `http://localhost:5035` (domyślnie) |
| **Telefon** (ta sama sieć Wi-Fi) | `flutter run --dart-define=API_BASE_URL=http://<IP komputera>:5035/api/` | IP komputera, np. `192.168.1.20` (`ipconfig`) |
| Przeglądarka | `flutter run -d chrome` | `http://localhost:5035` |

Na Windowsie może być potrzebne otwarcie portu 5035 w zaporze, żeby telefon dosięgnął API.

`http` działa tylko lokalnie: na Androidzie wyłącznie w buildach debug (`src/debug/AndroidManifest.xml`), na iOS tylko dla sieci lokalnej (`NSAllowsLocalNetworking`). Wydanie łączy się z API po `https`:

```bash
flutter build appbundle --dart-define=API_BASE_URL=https://api.example.com/api/
```

## Przygotowanie środowiska (Android)

1. Android Studio → SDK Manager: Android SDK, **Android SDK Command-line Tools**, Platform-Tools.
2. `flutter doctor --android-licenses`
3. Device Manager → utwórz emulator (np. Pixel, obraz z Google Play) albo podłącz telefon z włączonym **debugowaniem USB**.
4. `flutter doctor` — sekcja Android bez błędów.

## Komendy

```bash
flutter pub get
flutter gen-l10n          # po zmianie lib/l10n/*.arb (źródło tekstów)
flutter analyze
flutter test
flutter build apk --debug # szybki test, że konfiguracja Androida się buduje (robi to też CI)
```

## Do zrobienia przed publikacją
- Ikona aplikacji i ekran startowy (teraz domyślne Fluttera) — np. `flutter_launcher_icons` + `flutter_native_splash`.
- Klucz podpisu wydania Androida (teraz release podpisywany kluczem debug) i konto w Google Play / App Store.
- Produkcyjny adres API po `https`.
