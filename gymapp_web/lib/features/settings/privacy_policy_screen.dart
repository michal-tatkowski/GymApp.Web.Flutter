import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Fill these in before publishing — the stores reject a policy without a
/// reachable controller. Keep `docs/privacy-policy.md` (the copy hosted at a
/// public URL for the store listing) in sync with the text below.
const privacyController = '[NAZWA / IMIĘ I NAZWISKO ADMINISTRATORA]';
const privacyContact = '[ADRES E-MAIL KONTAKTOWY]';
const privacyUpdated = '2026-11-12';

typedef PolicySection = ({String title, String body});

/// Shown from Settings and from the sign-up screen (before an account exists).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));

  static List<PolicySection> sections(String languageCode) => languageCode == 'pl' ? _pl : _en;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final sections = PrivacyPolicyScreen.sections(Localizations.localeOf(context).languageCode);
    return Scaffold(
      appBar: AppBar(title: Text(t.privacyPolicy)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(t.privacyUpdated(privacyUpdated), style: text.bodySmall),
            for (final s in sections) ...[
              const SizedBox(height: 20),
              Text(s.title, style: text.titleMedium),
              const SizedBox(height: 6),
              Text(s.body, style: text.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

const _pl = <PolicySection>[
  (
    title: '1. Administrator danych',
    body: 'Administratorem danych jest $privacyController. Kontakt w sprawach danych osobowych: $privacyContact.',
  ),
  (
    title: '2. Jakie dane przetwarzamy',
    body: '• Konto: adres e-mail i hasło (przechowywane wyłącznie jako skrót kryptograficzny).\n'
        '• Profil (opcjonalnie): pseudonim, imię, nazwisko, płeć, wzrost, waga, data urodzenia.\n'
        '• Treningi: wykonane ćwiczenia, serie, powtórzenia, ciężary i daty, plany treningowe, własne ćwiczenia, ulubione ćwiczenia, cele, pomiary masy ciała i obwodów ciała.\n'
        '• Raporty błędów (jeśli są włączone w danej wersji aplikacji): model urządzenia, wersja systemu i aplikacji oraz przebieg błędu — bez adresu e-mail i bez treści treningów.',
  ),
  (
    title: '3. Cel i podstawa prawna',
    body: 'Dane konta, profilu i treningów przetwarzamy, aby świadczyć usługę: prowadzić konto, zapisywać i synchronizować treningi oraz liczyć statystyki (art. 6 ust. 1 lit. b RODO). '
        'Raporty błędów służą poprawianiu stabilności aplikacji — to nasz prawnie uzasadniony interes (art. 6 ust. 1 lit. f RODO).',
  ),
  (
    title: '4. Gdzie i jak długo',
    body: 'Dane konta i treningów są przechowywane na serwerze aplikacji do czasu usunięcia konta. Raporty błędów są usuwane po 90 dniach. '
        'Na telefonie aplikacja przechowuje tokeny logowania (w zaszyfrowanym magazynie systemu), ustawienia, przypomnienia, treningi zapisane offline, które czekają na wysłanie, oraz zdjęcia sylwetki — te nigdy nie opuszczają telefonu i są usuwane przy wylogowaniu.',
  ),
  (
    title: '5. Odbiorcy',
    body: 'Nie sprzedajemy danych i nie wyświetlamy reklam. Dane mogą być powierzane wyłącznie dostawcom technicznym: firmie hostingowej serwera oraz dostawcy raportów błędów (Sentry), na podstawie umów powierzenia.',
  ),
  (
    title: '6. Twoje prawa',
    body: 'Masz prawo dostępu do danych, ich sprostowania (profil edytujesz w aplikacji), usunięcia, ograniczenia przetwarzania, przenoszenia oraz sprzeciwu. '
        'Konto i wszystkie dane usuniesz w aplikacji: Ustawienia → Usuń konto — dzieje się to od razu i nieodwracalnie. '
        'Przysługuje Ci też skarga do Prezesa Urzędu Ochrony Danych Osobowych.',
  ),
  (
    title: '7. Zmiany',
    body: 'O istotnych zmianach tej polityki poinformujemy w aplikacji. Data ostatniej aktualizacji jest podana na górze.',
  ),
];

const _en = <PolicySection>[
  (
    title: '1. Data controller',
    body: 'The data controller is $privacyController. Contact for personal data matters: $privacyContact.',
  ),
  (
    title: '2. What we process',
    body: '• Account: email address and password (stored only as a cryptographic hash).\n'
        '• Profile (optional): nickname, first and last name, gender, height, weight, date of birth.\n'
        '• Training: exercises done, sets, reps, weights and dates, workout plans, custom exercises, favorite exercises, goals, body weight and body measurements.\n'
        '• Crash reports (when enabled in a given app build): device model, OS and app version and the error trace — without your email and without workout content.',
  ),
  (
    title: '3. Purpose and legal basis',
    body: 'Account, profile and training data are processed to provide the service: run your account, save and sync workouts and compute statistics (Art. 6(1)(b) GDPR). '
        'Crash reports are used to make the app more stable — our legitimate interest (Art. 6(1)(f) GDPR).',
  ),
  (
    title: '4. Where and how long',
    body: 'Account and training data are stored on the app server until you delete your account. Crash reports are deleted after 90 days. '
        'On the phone the app keeps sign-in tokens (in the system\'s encrypted storage), settings, reminders, workouts saved offline that are waiting to be sent, and progress photos — these never leave the phone and are deleted when you log out.',
  ),
  (
    title: '5. Recipients',
    body: 'We do not sell data and show no ads. Data may be entrusted only to technical providers: the server hosting company and the crash reporting provider (Sentry), under data processing agreements.',
  ),
  (
    title: '6. Your rights',
    body: 'You have the right to access, rectify (edit your profile in the app), erase, restrict, port and object to the processing of your data. '
        'Delete your account and all data in the app: Settings → Delete account — it happens immediately and cannot be undone. '
        'You may also lodge a complaint with a data protection authority.',
  ),
  (
    title: '7. Changes',
    body: 'We will announce significant changes to this policy in the app. The last update date is shown at the top.',
  ),
];
