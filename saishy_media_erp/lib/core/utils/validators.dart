class AppValidators {
  static String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  static String? username(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter username';
    if (v.trim().length < 3) return 'Username must be at least 3 characters';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Enter password';
    if (v.length < 3) return 'Password too short';
    return null;
  }

  static String? mobile(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter mobile number';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter valid 10-digit mobile';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final re = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!re.hasMatch(v.trim())) return 'Enter valid email';
    return null;
  }

  static String? gstin(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter GSTIN';
    final re = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    if (!re.hasMatch(v.trim().toUpperCase())) return 'Enter valid 15-character GSTIN';
    return null;
  }

  static String? amount(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter amount';
    final d = double.tryParse(v.trim());
    if (d == null || d <= 0) return 'Enter valid amount';
    return null;
  }

  static String? positiveNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final d = double.tryParse(v.trim());
    if (d == null || d <= 0) return 'Enter a positive number';
    return null;
  }
}
