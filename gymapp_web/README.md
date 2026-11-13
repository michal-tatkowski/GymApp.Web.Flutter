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

Kod potwierdzający e-mail i kod resetu hasła: lokalne API bez SMTP nie wysyła maili, tylko wypisuje je do swojego logu (konsola / Seq) — stamtąd przepisz 6 cyfr.

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
flutter test integration_test   # na uruchomionym emulatorze/telefonie: cała aplikacja z prawdziwymi pluginami (CI: job integration-android)
```

## Podpis wydania (Android)

Bez klucza wydanie jest podpisane kluczem debug — działa do testów, Google Play go odrzuci. Klucz tworzysz raz i **trzymasz w bezpiecznym miejscu (z kopią)**: bez niego nie wydasz aktualizacji (chyba że włączysz Play App Signing — wtedy to klucz przesyłania i da się go zresetować).

```bash
keytool -genkey -v -keystore ~/gymapp-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Potem `android/key.properties` (jest w `.gitignore`, nigdy go nie commituj):

```properties
storeFile=C:/Users/<ty>/gymapp-upload.jks
storePassword=<hasło z keytool>
keyAlias=upload
keyPassword=<hasło z keytool>
```

`flutter build appbundle` sam go użyje; bez pliku wraca do klucza debug.

## Raporty błędów (Sentry)

Wyłączone, dopóki build nie dostanie DSN — lokalne uruchomienia i testy niczego nie wysyłają. Załóż projekt Flutter w sentry.io i buduj z:

```bash
flutter build appbundle --dart-define=API_BASE_URL=https://api.example.com/api/ --dart-define=SENTRY_DSN=<DSN projektu>
```

Wysyłane są tylko błąd i informacje o urządzeniu/aplikacji (`sendDefaultPii = false`, bez zrzutów ekranu) — tak opisuje to polityka prywatności. Ustaw w Sentry retencję 90 dni. Sentry wymaga Androida 8.0+ (`minSdk 26`).

## Polityka prywatności

Treść jest w aplikacji (Ustawienia → Polityka prywatności, link też przy rejestracji) i w [`../docs/privacy-policy.md`](../docs/privacy-policy.md). Sklepy wymagają publicznego URL — np. włącz GitHub Pages z folderu `docs/`. Przed publikacją uzupełnij administratora i e-mail kontaktowy (`privacyController`, `privacyContact` w `privacy_policy_screen.dart` i w pliku `.md`).

## Wydanie do Google Play

Podpisany pakiet `.aab` buduje GitHub Actions (`.github/workflows/release.yml`): **Actions → „Release (Google Play)” → Run workflow** (wybór ścieżki: internal / alpha / beta / production) albo tag `v1.2.3`. `versionCode` rośnie sam (numer uruchomienia), `versionName` z `pubspec.yaml` albo z tagu. Build sprawdza, że jest podpisany kluczem uploadu (nie debug) i że API jest po `https`.

**1. Raz, w GitHubie** (repo → Settings → Secrets and variables → Actions):

| Nazwa | Rodzaj | Wartość |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | secret | plik klucza w base64: `base64 -w0 gymapp-upload.jks` (PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("gymapp-upload.jks"))`) |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | secret | jak w `key.properties` (alias: `upload`) |
| `API_BASE_URL` | variable | `https://api.twojadomena.pl/api/` (wdrożenie API: `GymApp.API/deploy/README.md`) |
| `SENTRY_DSN` | secret, opcjonalnie | raporty awarii |
| `PLAY_SERVICE_ACCOUNT_JSON` | secret, opcjonalnie | klucz konta usługi — automatyczne wgrywanie (pkt 3) |

**2. Raz, w Play Console** (konto dewelopera: jednorazowo 25 USD):
1. Utwórz aplikację, pakiet `pl.tatkowski.gymapp`, włącz **Play App Signing** (Twój klucz to wtedy tylko klucz uploadu — da się go zresetować).
2. Uruchom workflow, pobierz artefakt (`app-release.aab`) i **pierwszy raz wgraj ręcznie**: Testowanie → Testy wewnętrzne → Utwórz wersję. Google nie przyjmuje pierwszego pakietu przez API.
3. Dodaj testerów (lista e-maili) i wyślij im link do testów.
4. Karta sklepu: teksty i zrzuty są w `fastlane/metadata/android/{pl-PL,en-US}/` (tytuł, krótki i pełny opis, `images/phoneScreenshots/`). Brakuje jeszcze **grafiki promocyjnej 1024×500** (ikona 512×512: `assets/icon`).
5. Formularze: polityka prywatności (URL), **Bezpieczeństwo danych**, klasyfikacja treści, grupa docelowa, reklamy: brak.

**3. Automatyczne wgrywanie (opcjonalnie):** Google Cloud → konto usługi → klucz JSON; w Play Console → Użytkownicy i uprawnienia → zaproś e-mail konta usługi z uprawnieniami do wydań. JSON wklej jako `PLAY_SERVICE_ACCOUNT_JSON` — od tej pory workflow sam wrzuca wersję na wybraną ścieżkę (notatki do wersji: `fastlane/whatsnew/`).

**Zrzuty ekranu** (po zmianach w UI): emulator + działające API + konto z historią (np. z symulacji) —
```bash
SCREENSHOT_EMAIL=… SCREENSHOT_PASSWORD=… tool/store_screenshots.sh
```
Ekran 1080×1920 (Play: maks. proporcje 2:1), czysty pasek stanu, po polsku i po angielsku.

## Do zrobienia przed publikacją
- Ikona i ekran startowy są gotowe (`assets/icon`, konfiguracja `flutter_launcher_icons` / `flutter_native_splash`) — przy zmianie grafiki uruchom oba generatory.
- Klucz wydania (wyżej) i konto w Google Play / App Store. Kroki: „Wydanie do Google Play”.
- Administrator i kontakt w polityce prywatności + jej publiczny URL.
- Produkcyjny adres API po `https` i DSN Sentry.
- Formularz „Bezpieczeństwo danych” w Google Play (zgodnie z polityką: e-mail, dane o zdrowiu/fitness, raporty awarii; usuwanie konta w aplikacji).
