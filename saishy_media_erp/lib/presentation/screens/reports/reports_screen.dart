import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/providers/invoice_payment_provider.dart';
import '../../../data/providers/dashboard_provider.dart';
import '../../../core/services/api_service.dart';
import '../../widgets/common_widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate   = DateTime.now();
  bool _loading = false;
  Map<String, dynamic>? _reportData;
  String _currentType = 'revenue';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      final types = ['revenue', 'outstanding', 'client_wise', 'media_wise', 'monthly_summary'];
      if (!_tabController.indexIsChanging) {
        setState(() => _currentType = types[_tabController.index]);
        _loadReport();
      }
    });
    _loadReport();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      final from = DateFormat('yyyy-MM-dd').format(_fromDate);
      final to   = DateFormat('yyyy-MM-dd').format(_toDate);
      final data = await ApiService().getReports(type: _currentType, from: from, to: to);
      setState(() => _reportData = data);
    } catch (_) {
      setState(() => _reportData = null);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Revenue'),
            Tab(text: 'Outstanding'),
            Tab(text: 'Client Wise'),
            Tab(text: 'Media Wise'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date filter
          Container(
            color: AppColors.surfaceDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded, color: AppColors.textMuted, size: 16),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _pickDate(true),
                  child: Text(DateFormat('dd MMM yy').format(_fromDate), style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                const Text(' — ', style: TextStyle(color: AppColors.textMuted)),
                GestureDetector(
                  onTap: () => _pickDate(false),
                  child: Text(DateFormat('dd MMM yy').format(_toDate), style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh_rounded, size: 18), onPressed: _loadReport),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Generating report...')
                : _reportData == null
                    ? const EmptyStateWidget(title: 'Could not load report', subtitle: 'Check your internet connection', icon: Icons.cloud_off_rounded)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRevenueReport(),
                          _buildOutstandingReport(),
                          _buildClientWiseReport(),
                          _buildMediaWiseReport(),
                          _buildMonthlyReport(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() { if (isFrom) _fromDate = d; else _toDate = d; });
      _loadReport();
    }
  }

  Widget _buildRevenueReport() {
    final data = _reportData ?? {};
    return ListView(padding: const EdgeInsets.all(16), children: [
      _statCard('Total Invoiced',   AppFormatters.currency(double.tryParse(data['total_invoiced']?.toString() ?? '0') ?? 0),   Icons.receipt_long_rounded,   AppColors.primary),
      const SizedBox(height: 10),
      _statCard('Total Collected',  AppFormatters.currency(double.tryParse(data['total_collected']?.toString() ?? '0') ?? 0),  Icons.check_circle_rounded,   AppColors.success),
      const SizedBox(height: 10),
      _statCard('Outstanding',      AppFormatters.currency(double.tryParse(data['total_outstanding']?.toString() ?? '0') ?? 0), Icons.warning_rounded,         AppColors.error),
      const SizedBox(height: 10),
      _statCard('Invoice Count',    '${data['invoice_count'] ?? 0}',                                                           Icons.numbers_rounded,         AppColors.info),
    ]);
  }

  Widget _buildOutstandingReport() {
    final list = (_reportData as List? ?? []);
    if (list.isEmpty) return const EmptyStateWidget(title: 'No Outstanding Invoices', icon: Icons.check_circle_outline_rounded);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final item = list[i] as Map;
        final balance = double.tryParse(item['balance']?.toString() ?? '0') ?? 0;
        final daysOverdue = int.tryParse(item['days_overdue']?.toString() ?? '0') ?? 0;
        return ErpCard(
          borderColor: daysOverdue > 30 ? AppColors.error.withOpacity(0.3) : AppColors.borderDark,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(item['invoice_number']?.toString() ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700))),
              if (daysOverdue > 0) Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text('$daysOverdue days overdue', style: const TextStyle(color: AppColors.error, fontSize: 10)),
              ),
            ]),
            Text(item['party_name']?.toString() ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: [
              const Spacer(),
              const Text('Balance: ', style: TextStyle(color: AppColors.error, fontSize: 12)),
              Text(AppFormatters.currency(balance), style: const TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildClientWiseReport() {
    final list = (_reportData as List? ?? []);
    if (list.isEmpty) return const EmptyStateWidget(title: 'No Data', icon: Icons.people_outline_rounded);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final item = list[i] as Map;
        return ErpCard(child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: AppColors.primary.withOpacity(0.12), child: Text((item['party_name']?.toString() ?? '?')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['party_name']?.toString() ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${item['count'] ?? 0} invoices', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(AppFormatters.currency(double.tryParse(item['total']?.toString() ?? '0') ?? 0), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Paid: ${AppFormatters.currency(double.tryParse(item['paid']?.toString() ?? '0') ?? 0)}', style: const TextStyle(color: AppColors.success, fontSize: 11)),
          ]),
        ]));
      },
    );
  }

  Widget _buildMediaWiseReport() {
    final list = (_reportData as List? ?? []);
    if (list.isEmpty) return const EmptyStateWidget(title: 'No Data', icon: Icons.newspaper_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final item = list[i] as Map;
        return ErpCard(child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.newspaper_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['media_house_name']?.toString() ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${item['ro_count'] ?? 0} ROs', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ])),
          Text(AppFormatters.currency(double.tryParse(item['total']?.toString() ?? '0') ?? 0), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
        ]));
      },
    );
  }

  Widget _buildMonthlyReport() {
    final list = (_reportData as List? ?? []);
    if (list.isEmpty) return const EmptyStateWidget(title: 'No Data', icon: Icons.calendar_month_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final item = list[i] as Map;
        return ErpCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Text(item['month']?.toString() ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Column(children: [
              const Text('Invoiced', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              Text(AppFormatters.currency(double.tryParse(item['invoiced']?.toString() ?? '0') ?? 0), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ])),
            Expanded(child: Column(children: [
              const Text('Collected', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              Text(AppFormatters.currency(double.tryParse(item['collected']?.toString() ?? '0') ?? 0), style: const TextStyle(color: AppColors.success, fontSize: 12)),
            ])),
            Expanded(child: Column(children: [
              const Text('ROs', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              Text('${item['ros'] ?? 0}', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
            ])),
          ]),
        ]));
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }
}
