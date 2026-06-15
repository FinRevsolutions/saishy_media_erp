class AppConstants {
  static const appName    = 'SAISHY Media ERP';
  static const appVersion = '1.0.0';

  // ── Company Details (Edit before APK build) ────────────
  static const companyName    = 'SAISHY Media Services';
  static const companyAddress = 'Your Address Here, City, State - PIN';
  static const companyPhone   = '+91-XXXXXXXXXX';
  static const companyEmail   = 'info@saishymedia.com';
  static const companyGstin   = 'XX-XXXXXXXXXXXXXXXXX';

  // ── Secure Storage Keys ────────────────────────────────
  static const keyAuthToken   = 'auth_token';
  static const keyUserData    = 'user_data';
  static const keyUserName    = 'saved_username';
  static const keyScriptUrl   = 'apps_script_url';

  // ── Shared Pref Keys ──────────────────────────────────
  static const keyLastSync    = 'last_sync_ts';

  // ── RO/Invoice Config ─────────────────────────────────
  static const roPrefix       = 'RO';
  static const invoicePrefix  = 'INV';
  static const tradeDiscount  = 0.15;  // 15%

  // ── Sync ──────────────────────────────────────────────
  static const syncIntervalMinutes = 15;
  static const maxOfflineDays      = 30;
}
