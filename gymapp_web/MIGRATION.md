# Faza 1 — Refaktor architektury

## Jak uruchomić

```bash
cd gymapp_web
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:5035/api/
```

Dla Androida w emulatorze (host to `10.0.2.2`):
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5035/api/
```

Produkcja:
```bash
flutter run --dart-define=API_BASE_URL=https://api.gymapp.com/api/ \
            --dart-define=ENABLE_NETWORK_LOGS=false
```

## Co się zmieniło

### Nowa struktura katalogów

```
lib/
├── main.dart                        # minimalny entrypoint
├── app/
│   ├── app.dart                     # GymApp — MaterialApp.router
│   ├── config/app_config.dart       # stałe z --dart-define
│   └── theme/app_theme.dart         # Material 3 light/dark
├── core/                            # wspólna infrastruktura
│   ├── errors/
│   │   ├── failure.dart             # sealed class Failure (UI-friendly)
│   │   └── exceptions.dart          # mapowanie DioException → Failure
│   ├── logging/app_logger.dart      # `log.i/w/e` zamiast print()
│   ├── storage/secure_storage_keys.dart
│   └── network/
│       ├── dio_client.dart          # fabryka skonfigurowanego Dio
│       └── interceptors/
│           ├── logging_interceptor.dart
│           └── auth_interceptor.dart   # auto-Bearer + refresh flow
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_api.dart            # endpointy /Auth/*
│   │   │   ├── auth_local_storage.dart  # JWT w secure storage
│   │   │   ├── auth_repository.dart     # orkiestracja + mapping błędów
│   │   │   └── models/ (auth_tokens, auth_requests, user)
│   │   └── presentation/
│   │       ├── auth_providers.dart      # Riverpod: Dio, repo, AsyncNotifier
│   │       ├── auth_state.dart          # enum Authenticated/Unauthenticated
│   │       └── screens/ (login, register, splash)
│   ├── settings/presentation/settings_providers.dart
│   ├── home/home_menu.dart
│   └── (gym, social, profile, info, notifications)
├── routing/
│   ├── app_routes.dart              # stałe ścieżek
│   └── app_router.dart              # GoRouter + auth guard (redirect)
└── l10n/                            # bez zmian
```

### Kluczowe decyzje architektoniczne

1. **Dio zamiast http** — interceptory, timeout, retry, lepsza obsługa błędów.
2. **Auth interceptor z refresh token flow** — 401 → próba `POST /Auth/Refresh`
   → retry oryginalnego żądania. Serializacja równoległych refresh'y przez
   `Completer`. Jeśli refresh zawiedzie — automatyczny logout + przekierowanie.
3. **go_router z `redirect`** — centralny auth guard w jednym miejscu.
   Niezalogowany na protected route → `/login`. Zalogowany na `/login` → `/`.
4. **Riverpod `AsyncNotifier`** — nowoczesny pattern dla stanu async.
   Stan logowania = `AsyncValue<AuthState>`; ładowanie, błąd i sukces są
   naturalnie reprezentowane.
5. **`Failure` sealed class** — warstwa prezentacji nigdy nie widzi
   `DioException`. Repozytorium mapuje wszystko na `Failure` z przyjaznym
   komunikatem po polsku.
6. **`--dart-define` dla konfiguracji** — URL API nie jest zahardkodowany.

## Naprawione bugi

- ✅ `register_form.dart`: `if (result is bool && true)` → automatyczna
  nawigacja niezależnie od wyniku. Nowy `RegisterScreen` sprawdza faktyczny
  stan błędu.
- ✅ `login_form.dart`: `TextEditingController` bez `dispose()` → wyciek
  pamięci. Naprawione w `LoginScreen`.
- ✅ `login_api_service.dart:47`: `print(response)` → zastąpione `logger`.
- ✅ `e.toString()` jako komunikat dla użytkownika → teraz
  `Failure.message` z czytelnym tekstem.
- ✅ Brak walidacji formularza logowania → dodane.
- ✅ Brak timeoutów HTTP → 15s przez `Dio BaseOptions`.
- ✅ Mieszanie singleton `JwtTokenService` + Riverpod → jedna ścieżka
  przez `authLocalStorageProvider`.

## Kontrakt backendu

Interceptor oczekuje endpointu **`POST /Auth/Refresh`**:

```http
POST /api/Auth/Refresh
Content-Type: application/json

{ "refreshToken": "..." }
```
odpowiedź:
```json
{ "accessToken": "..." }
```

Jeśli backend jeszcze nie udostępnia refresh — aplikacja nadal działa,
tylko wygaśnięcie tokenu = wylogowanie użytkownika.

Login odpowiedź — obsługiwane formaty:
- `{"accessToken": "...", "refreshToken": "..."}` — preferowany
- `{"token": "..."}` — legacy
- `"raw jwt string"` — legacy

## Co dalej (faza 2)

1. **`freezed` + `json_serializable`** — immutable modele, `copyWith`,
   równość, serializacja. Wymaga `build_runner`.
2. **Retrofit** — type-safe API client generowany z interfejsu.
3. **Dodanie `intercept` dla Crashlytics/Sentry**.
4. **Refresh token rotation** (server-side) — każdy refresh zwraca nowy
   refresh token.
5. **Deep linking** w go_router — `/post/:id`, `/profile/:userId`.
6. **Shell route z bottom navigation bar** dla głównego flow.

## Gdzie co dopisywać (szybki przewodnik)

- **Nowy endpoint REST** → dodaj metodę w odpowiednim `*_api.dart`.
  Pamiętaj o `AuthOptions.skipAuth()` jeśli nie wymaga tokenu.
- **Nowy feature** → katalog `features/<nazwa>/` z podkatalogami
  `data/` i `presentation/`. Wzoruj się na `auth/`.
- **Nowy provider globalny** → `core/` tylko jeśli naprawdę
  współdzielone. W przeciwnym razie w `features/<x>/presentation/`.
- **Nowy ekran** → dodaj w `routing/app_routes.dart` + `app_router.dart`.
- **Stała konfiguracyjna** (klucze API, feature flags) →
  `app/config/app_config.dart` jako `String.fromEnvironment`.
