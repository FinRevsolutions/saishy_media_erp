import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/local_db_service.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlCtrl     = TextEditingController();
  final _companyCtrl = TextEditingController();
  bool _loadingUrl   = false;
  bool _clearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _urlCtrl.text     = prefs.getString(AppConstants.keyScriptUrl) ?? '';
    _companyCtrl.text = prefs.getString('company_name') ?? AppConstants.companyName;
    setState(() {});
  }

  Future<void> _saveUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) { _showSnack('Enter a valid URL', AppColors.error); return; }
    setState(() => _loadingUrl = true);
    await ApiService().updateBaseUrl(url);
    setState(() => _loadingUrl = false);
    _showSnack('API URL saved', AppColors.success);
  }

  Future<void> _clearCache() async {
    final ok = await ConfirmDialog.show(context, title: 'Clear Local Cache', message: 'All offline cached data will be deleted. Data on Google Sheets is unaffected.', confirmLabel: 'Clear', isDanger: true);
    if (!ok) return;
    setState(() => _clearingCache = true);
    await LocalDbService.instance.clearAllCaches();
    setState(() => _clearingCache = false);
    _showSnack('Cache cleared', AppColors.success);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() { _urlCtrl.dispose(); _companyCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.15), AppColors.cardDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              CircleAvatar(radius: 28, backgroundColor: AppColors.primary.withOpacity(0.2), child: Text(user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U', style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w700))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.fullName ?? 'Unknown', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text(user?.role.label ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 11))),
              ])),
              IconButton(icon: const Icon(Icons.logout_rounded, color: AppColors.error), onPressed: () async {
                final ok = await ConfirmDialog.show(context, title: 'Logout', message: 'Are you sure you want to logout?', confirmLabel: 'Logout', isDanger: true);
                if (ok && mounted) { await ref.read(authStateProvider.notifier).logout(); context.go('/login'); }
              }),
            ]),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // API Configuration
          _buildSectionHeader('API Configuration', Icons.cloud_outlined),
          const SizedBox(height: 8),
          ErpCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Google Apps Script URL', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextField(controller: _urlCtrl, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              decoration: const InputDecoration(hintText: 'https://script.google.com/macros/s/.../exec', hintStyle: TextStyle(fontSize: 11), border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _loadingUrl ? null : _saveUrl,
              child: _loadingUrl ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save API URL'),
            )),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.info.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.info.withOpacity(0.2))),
              child: const Text('Deploy the Google Apps Script, then paste the Web App URL here.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11))),
          ])),
          const SizedBox(height: 20),

          // Company Settings
          _buildSectionHeader('Company Details', Icons.business_rounded),
          const SizedBox(height: 8),
          ErpCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _settingTile('Company Name',    AppConstants.companyName,    Icons.business_rounded),
            _settingTile('Address',         AppConstants.companyAddress, Icons.location_on_outlined),
            _settingTile('Phone',           AppConstants.companyPhone,   Icons.phone_outlined),
            _settingTile('Email',           AppConstants.companyEmail,   Icons.email_outlined),
            _settingTile('GSTIN',           AppConstants.companyGstin,   Icons.receipt_outlined),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.warning.withOpacity(0.2))),
              child: const Text('Edit company details in lib/core/constants/app_constants.dart before building APK.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11))),
          ])),
          const SizedBox(height: 20),

          // Data Management
          _buildSectionHeader('Data & Cache', Icons.storage_rounded),
          const SizedBox(height: 8),
          ErpCard(child: Column(children: [
            ListTile(
              leading: const Icon(Icons.sync_rounded, color: AppColors.primary),
              title: const Text('Sync All Data', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Re-sync from Google Sheets', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              contentPadding: EdgeInsets.zero,
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              onTap: () { _showSnack('Syncing...', AppColors.info); },
            ),
            const Divider(color: AppColors.borderDark, height: 1),
            ListTile(
              leading: Icon(Icons.delete_sweep_rounded, color: _clearingCache ? AppColors.textMuted : AppColors.error),
              title: Text('Clear Local Cache', style: TextStyle(color: _clearingCache ? AppColors.textMuted : AppColors.error)),
              subtitle: const Text('Delete all offline cached data', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              contentPadding: EdgeInsets.zero,
              trailing: _clearingCache
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              onTap: _clearingCache ? null : _clearCache,
            ),
          ])),
          const SizedBox(height: 20),

          // App Info
          _buildSectionHeader('About', Icons.info_outline_rounded),
          const SizedBox(height: 8),
          ErpCard(child: Column(children: [
            _settingTile('App Name',     AppConstants.appName,    Icons.apps_rounded),
            _settingTile('Version',      AppConstants.appVersion, Icons.new_releases_outlined),
            _settingTile('Platform',     'Android',               Icons.android_rounded),
            _settingTile('Database',     'Google Sheets + SQLite', Icons.table_chart_outlined),
          ])),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: AppColors.primary, size: 16),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _settingTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
