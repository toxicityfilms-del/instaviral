/// Public URLs for Privacy Policy and Terms. Host the contents of `docs/privacy-policy.md` and
/// `docs/terms.md` (or equivalent) at these URLs and update via `--dart-define` for production.
abstract final class AppLegalUrls {
  static const privacyPolicy = String.fromEnvironment(
    'LEGAL_PRIVACY_URL',
    defaultValue: 'https://reelboost.app/privacy-policy',
  );

  static const termsOfUse = String.fromEnvironment(
    'LEGAL_TERMS_URL',
    defaultValue: 'https://reelboost.app/terms',
  );
}
