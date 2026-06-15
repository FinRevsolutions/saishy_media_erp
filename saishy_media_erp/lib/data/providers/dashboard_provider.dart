import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/services/connectivity_service.dart';
import '../models/document_model.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/local_db_service.dart';

// ── Dashboard Data ─────────────────────────────────────
class DashboardStats {
  final int totalClients;
  final int totalMediaHouses;
  final int totalROs;
  final int monthlyROs;
  final int pendingPublications;
  final int pendingBills;
  final double outstandingAmount;
  final double monthlyRevenue;
  final double totalRevenue;
  final List<Map<String, dynamic>> chartData;
  final List<Map<String, dynamic>> recentROs;
  final Map<String, int> statusDistribution;

  const DashboardStats({
    this.totalClients = 0,
    this.totalMediaHouses = 0,
    this.totalROs = 0,
    this.monthlyROs = 0,
    this.pendingPublications = 0,
    this.pendingBills = 0,
    this.outstandingAmount = 0,
    this.monthlyRevenue = 0,
    this.totalRevenue = 0,
    this.chartData = const [],
    this.recentROs = const [],
    this.statusDistribution = const {},
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalClients:       int.tryParse(json['total_clients']?.toString() ?? '') ?? 0,
    totalMediaHouses:   int.tryParse(json['total_media_houses']?.toString() ?? '') ?? 0,
    totalROs:           int.tryParse(json['total_ros']?.toString() ?? '') ?? 0,
    monthlyROs:         int.tryParse(json['monthly_ros']?.toString() ?? '') ?? 0,
    pendingPublications:int.tryParse(json['pending_publications']?.toString() ?? '') ?? 0,
    pendingBills:       int.tryParse(json['pending_bills']?.toString() ?? '') ?? 0,
    outstandingAmount:  double.tryParse(json['outstanding_amount']?.toString() ?? '') ?? 0,
    monthlyRevenue:     double.tryParse(json['monthly_revenue']?.toString() ?? '') ?? 0,
    totalRevenue:       double.tryParse(json['total_revenue']?.toString() ?? '') ?? 0,
    chartData:          (json['chart_data'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    recentROs:          (json['recent_ros'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    statusDistribution: (json['status_distribution'] as Map? ?? {})
        .map((k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0)),
  );
}

// ── Dashboard Notifier ─────────────────────────────────
class DashboardNotifier extends AsyncNotifier<DashboardStats> {
  final _api  = ApiService();
  final _conn = ConnectivityService.instance;

  @override
  Future<DashboardStats> build() async {
    return _load();
  }

  Future<DashboardStats> _load() async {
    if (!_conn.isOnline) return const DashboardStats();
    final data = await _api.getDashboard();
    return DashboardStats.fromJson(data);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

// ── Document Repository ────────────────────────────────
class DocumentRepository {
  final _api   = ApiService();
  final _local = LocalDbService.instance;
  final _conn  = ConnectivityService.instance;

  Future<List<DocumentModel>> getAll() async {
    if (_conn.isOnline) {
      try {
        final data   = await _api.getRecords(ApiConstants.sheetDocuments);
        final models = data.map(DocumentModel.fromJson).toList();
        await _local.cacheDocuments(models);
        return models;
      } catch (_) {}
    }
    return _local.getCachedDocuments();
  }

  Future<DocumentModel> create(DocumentModel doc) async {
    final model = doc.copyWith(id: doc.id.isEmpty ? const Uuid().v4() : doc.id);
    if (_conn.isOnline) {
      await _api.createRecord(ApiConstants.sheetDocuments, model.toJson());
    }
    return model;
  }

  Future<void> delete(String id) async {
    if (_conn.isOnline) {
      await _api.deleteRecord(ApiConstants.sheetDocuments, id);
    }
  }
}

// ── Document Notifier ──────────────────────────────────
class DocumentNotifier extends AsyncNotifier<List<DocumentModel>> {
  late DocumentRepository _repo;

  @override
  Future<List<DocumentModel>> build() async {
    _repo = ref.read(documentRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<bool> create(DocumentModel doc) async {
    try {
      final created = await _repo.create(doc);
      state = AsyncData([created, ...state.valueOrNull ?? []]);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      state = AsyncData((state.valueOrNull ?? []).where((d) => d.id != id).toList());
      return true;
    } catch (_) { return false; }
  }
}

// ── Connectivity Notifier ──────────────────────────────
class ConnectivityNotifier extends Notifier<bool> {
  @override
  bool build() {
    final conn = ConnectivityService.instance;
    conn.onlineStream.listen((online) {
      state = online;
    });
    return conn.isOnline;
  }
}

// ── Providers ─────────────────────────────────────────
final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardStats>(DashboardNotifier.new);

final documentRepositoryProvider =
    Provider<DocumentRepository>((_) => DocumentRepository());

final documentProvider =
    AsyncNotifierProvider<DocumentNotifier, List<DocumentModel>>(DocumentNotifier.new);

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);
