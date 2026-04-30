/// Legal pages hosted on GitHub Pages. Override at build time with `--dart-define=LEGAL_PRIVACY_URL=...` etc.
abstract final class AppLegalUrls {
  static const _pagesBase = 'https://toxicityfilms-del.github.io/reelboost-legal';

  static const privacyPolicy = String.fromEnvironment(
    'LEGAL_PRIVACY_URL',
    defaultValue: '$_pagesBase/privacy-policy.html',
  );

  static const termsOfUse = String.fromEnvironment(
    'LEGAL_TERMS_URL',
    defaultValue: '$_pagesBase/terms.html',
  );
}
