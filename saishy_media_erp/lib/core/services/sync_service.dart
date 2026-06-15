import 'dart:convert';
import 'api_service.dart';
import 'local_db_service.dart';
import 'connectivity_service.dart';
import '../constants/api_constants.dart';
import '../../data/models/party_model.dart';
import '../../data/models/media_house_model.dart';
import '../../data/models/agency_mapping_model.dart';
import '../../data/models/release_order_model.dart';
import '../../data/models/publication_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/document_model.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  final _api = ApiService();
  final _local = LocalDbService.instance;
  final _connectivity = ConnectivityService.instance;

  bool _isSyncing = false;

  // ── Full Sync (pull from server) ──────────────────────
  Future<void> syncAll() async {
    if (!_connectivity.isOnline || _isSyncing) return;
    _isSyncing = true;

    try {
      await Future.wait([
        _syncParties(),
        _syncMediaHouses(),
        _syncAgencyMappings(),
        _syncReleaseOrders(),
        _syncPublications(),
        _syncInvoices(),
        _syncPayments(),
        _syncDocuments(),
      ]);

      await _pushPendingChanges();
    } catch (_) {
      // Silent fail – will retry on next trigger
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncParties() async {
    try {
      final data = await _api.getRecords(ApiConstants.sheetClients);
      final models = data.map(PartyModel.fromJson).toList();
      await _local.cacheParties(models);
    } catch (_) {}
  }

  Future<void> _syncMediaHouses() async {
    try {
      final data = await _api.getRecords(ApiConstants.sheetMediaHouses);
      final models = data.map(MediaHouseModel.fromJson).toList();
      await _local.cacheMediaHouses(models);
    } catch (_) {}
  }

  Future<void> _syncAgencyMappings() async {
    try {
      final data = await _api.getRecords(ApiConstants.sheetAgencyMappings);
      final models = data.map(AgencyMappingModel.fromJson).toList();
      await _local.cacheAgencyMappings(models);
    } catch (_) {}
  }

  Future<void> _syncReleaseOrders() async {
    try {
      final data = await _api.getRecords(ApiConstants.sheetReleaseOrders);
      final models = data.map(ReleaseOrderModel.fromJson).toList();
      await _local.cacheReleaseOrders(models);
    } catch (_) {}
  }

  Future<void> _syncPublications() async {
    try {
      final data = await _api.getRecords(ApiConstants.sheetPublications);
      final models = data.map(PublicationModel.fromJson).toList();
      await _local.cachePublications(models);
    } catch (_) {}
  }

  Future<void> _syncInvoices() async {
    try {
      final data = await _api.getRecords(ApiConstants.sheetInvoices);
      final models = data.map(InvoiceModel.fromJson).toList();
      await _local.cacheInvoices(models);
    } catch (_) {}
  }

  Future<void> _syncPayments() async {
    try {
      final data = await _api.getRecords(ApiConstants.sheetPayments);
      final models = data.map(PaymentModel.fromJson).toList();
      await _local.cachePayments(models);
    } catch (_) {}
  }

  Future<void> _syncDocuments() async {
    try {
      final data = await _api.getRecords(ApiConstants.sheetDocuments);
      final models = data.map(DocumentModel.fromJson).toList();
      await _local.cacheDocuments(models);
    } catch (_) {}
  }

  // ── Push Offline Drafts ────────────────────────────────
  Future<void> _pushPendingChanges() async {
    final pending = await _local.getPendingSync();
    if (pending.isEmpty) return;

    final syncedIds = <int>[];

    for (final item in pending) {
      try {
        final id = item['id'] as int;
        final table = item['table_name'] as String;
        final recordId = item['record_id'] as String;
        final action = item['action'] as String;
        final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;

        final sheet = _tableToSheet(table);
        if (sheet == null) { syncedIds.add(id); continue; }

        if (action == 'upsert') {
          try {
            await _api.createRecord(sheet, data);
          } catch (_) {
            await _api.updateRecord(sheet, recordId, data);
          }
        } else if (action == 'delete') {
          await _api.deleteRecord(sheet, recordId);
        }

        syncedIds.add(id);
      } catch (_) {
        // Leave in queue for next sync attempt
      }
    }

    if (syncedIds.isNotEmpty) {
      await _local.clearPendingSync(syncedIds);
    }
  }

  String? _tableToSheet(String table) {
    const map = {
      'parties': ApiConstants.sheetClients,
      'media_houses': ApiConstants.sheetMediaHouses,
      'agency_mappings': ApiConstants.sheetAgencyMappings,
      'release_orders': ApiConstants.sheetReleaseOrders,
      'publications': ApiConstants.sheetPublications,
      'invoices': ApiConstants.sheetInvoices,
      'payments': ApiConstants.sheetPayments,
      'documents': ApiConstants.sheetDocuments,
    };
    return map[table];
  }

  // ── Sync Master Data Only (lighter) ───────────────────
  Future<void> syncMasterData() async {
    if (!_connectivity.isOnline) return;
    await Future.wait([
      _syncParties(),
      _syncMediaHouses(),
      _syncAgencyMappings(),
    ]);
  }
}
