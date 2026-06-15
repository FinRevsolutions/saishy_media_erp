import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../data/models/party_model.dart';
import '../../data/models/media_house_model.dart';
import '../../data/models/agency_mapping_model.dart';
import '../../data/models/release_order_model.dart';
import '../../data/models/publication_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/document_model.dart';

class LocalDbService {
  static final LocalDbService instance = LocalDbService._internal();
  LocalDbService._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<void> initialize() async {
    _db = await _open();
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'saishy_erp.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parties (
        id TEXT PRIMARY KEY, name TEXT, address TEXT, mobile TEXT,
        email TEXT, gst_applicable TEXT, gstin TEXT, contact_person TEXT,
        state TEXT, state_code TEXT, notes TEXT, is_active TEXT,
        created_at TEXT, updated_at TEXT, synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS media_houses (
        id TEXT PRIMARY KEY, name TEXT, edition TEXT, language TEXT,
        contact_person TEXT, mobile TEXT, email TEXT, gst_percentage TEXT,
        address TEXT, notes TEXT, is_active TEXT, created_at TEXT,
        synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS agency_mappings (
        id TEXT PRIMARY KEY, media_house_id TEXT, media_house_name TEXT,
        agency_name TEXT, agency_address TEXT, agency_gstin TEXT,
        agency_phone TEXT, agency_email TEXT, is_default TEXT,
        created_at TEXT, synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS release_orders (
        ro_number TEXT PRIMARY KEY, date TEXT, party_id TEXT, party_name TEXT,
        media_house_id TEXT, media_house_name TEXT, agency_name TEXT,
        publication_date TEXT, category TEXT, ad_width TEXT, ad_height TEXT,
        ad_unit TEXT, rate TEXT, gst_type TEXT, status TEXT, created_by TEXT,
        notes TEXT, is_draft TEXT, created_at TEXT, updated_at TEXT,
        synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS publications (
        id TEXT PRIMARY KEY, ro_number TEXT, party_name TEXT,
        media_house_name TEXT, agency_name TEXT, publication_date TEXT,
        status TEXT, published_edition TEXT, proof_url TEXT, epaper_url TEXT,
        cutting_url TEXT, notes TEXT, status_updated_at TEXT,
        status_updated_by TEXT, created_at TEXT, synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        invoice_number TEXT PRIMARY KEY, ro_number TEXT, party_id TEXT,
        party_name TEXT, party_gstin TEXT, party_address TEXT,
        media_house_id TEXT, media_house_name TEXT, publication_date TEXT,
        invoice_date TEXT, amount TEXT, trade_discount TEXT,
        taxable_amount TEXT, gst_type TEXT, cgst TEXT, sgst TEXT,
        gst_amount TEXT, total_amount TEXT, amount_paid TEXT, status TEXT,
        is_gst_invoice TEXT, created_by TEXT, notes TEXT, due_date TEXT,
        created_at TEXT, updated_at TEXT, synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY, invoice_number TEXT, party_id TEXT,
        party_name TEXT, amount_paid TEXT, invoice_total TEXT,
        payment_date TEXT, payment_mode TEXT, cheque_number TEXT,
        bank_name TEXT, transaction_id TEXT, status TEXT, received_by TEXT,
        notes TEXT, receipt_url TEXT, created_at TEXT, synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id TEXT PRIMARY KEY, reference_number TEXT, reference_type TEXT,
        document_type TEXT, file_url TEXT, drive_file_id TEXT,
        file_name TEXT, file_size_bytes TEXT, mime_type TEXT,
        description TEXT, uploaded_by TEXT, uploaded_at TEXT,
        synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_sync (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT, record_id TEXT, action TEXT,
        data TEXT, created_at TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
  }

  // ── Parties ────────────────────────────────────────────
  Future<void> cacheParties(List<PartyModel> parties) async {
    final d = await db;
    final batch = d.batch();
    for (final p in parties) {
      batch.insert('parties', {...p.toJson(), 'synced': 1},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<PartyModel>> getCachedParties() async {
    final d = await db;
    final rows = await d.query('parties', where: 'is_active != ?', whereArgs: ['false']);
    return rows.map(PartyModel.fromJson).toList();
  }

  Future<void> upsertParty(PartyModel party, {bool synced = false}) async {
    final d = await db;
    await d.insert('parties', {...party.toJson(), 'synced': synced ? 1 : 0},
        conflictAlgorithm: ConflictAlgorithm.replace);
    if (!synced) await _addPendingSync('parties', party.id, 'upsert', party.toJson());
  }

  // ── Media Houses ───────────────────────────────────────
  Future<void> cacheMediaHouses(List<MediaHouseModel> items) async {
    final d = await db;
    final batch = d.batch();
    for (final m in items) {
      batch.insert('media_houses', {...m.toJson(), 'synced': 1},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<MediaHouseModel>> getCachedMediaHouses() async {
    final d = await db;
    final rows = await d.query('media_houses', where: 'is_active != ?', whereArgs: ['false']);
    return rows.map(MediaHouseModel.fromJson).toList();
  }

  // ── Agency Mappings ────────────────────────────────────
  Future<void> cacheAgencyMappings(List<AgencyMappingModel> items) async {
    final d = await db;
    final batch = d.batch();
    for (final m in items) {
      batch.insert('agency_mappings', {...m.toJson(), 'synced': 1},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<AgencyMappingModel>> getCachedAgencyMappings() async {
    final d = await db;
    final rows = await d.query('agency_mappings');
    return rows.map(AgencyMappingModel.fromJson).toList();
  }

  Future<AgencyMappingModel?> getMappingForMediaHouse(String mediaHouseId) async {
    final d = await db;
    final rows = await d.query('agency_mappings',
        where: 'media_house_id = ?', whereArgs: [mediaHouseId], limit: 1);
    if (rows.isEmpty) return null;
    return AgencyMappingModel.fromJson(rows.first);
  }

  // ── Release Orders ─────────────────────────────────────
  Future<void> cacheReleaseOrders(List<ReleaseOrderModel> items) async {
    final d = await db;
    final batch = d.batch();
    for (final ro in items) {
      batch.insert('release_orders', {...ro.toJson(), 'synced': 1},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<ReleaseOrderModel>> getCachedReleaseOrders() async {
    final d = await db;
    final rows = await d.query('release_orders', orderBy: 'created_at DESC');
    return rows.map(ReleaseOrderModel.fromJson).toList();
  }

  Future<void> upsertReleaseOrder(ReleaseOrderModel ro, {bool synced = false}) async {
    final d = await db;
    await d.insert('release_orders', {...ro.toJson(), 'synced': synced ? 1 : 0},
        conflictAlgorithm: ConflictAlgorithm.replace);
    if (!synced) await _addPendingSync('release_orders', ro.roNumber, 'upsert', ro.toJson());
  }

  // ── Publications ───────────────────────────────────────
  Future<void> cachePublications(List<PublicationModel> items) async {
    final d = await db;
    final batch = d.batch();
    for (final pub in items) {
      batch.insert('publications', {...pub.toJson(), 'synced': 1},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<PublicationModel>> getCachedPublications() async {
    final d = await db;
    final rows = await d.query('publications', orderBy: 'publication_date DESC');
    return rows.map(PublicationModel.fromJson).toList();
  }

  // ── Invoices ───────────────────────────────────────────
  Future<void> cacheInvoices(List<InvoiceModel> items) async {
    final d = await db;
    final batch = d.batch();
    for (final inv in items) {
      batch.insert('invoices', {...inv.toJson(), 'synced': 1},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<InvoiceModel>> getCachedInvoices() async {
    final d = await db;
    final rows = await d.query('invoices', orderBy: 'invoice_date DESC');
    return rows.map(InvoiceModel.fromJson).toList();
  }

  // ── Payments ───────────────────────────────────────────
  Future<void> cachePayments(List<PaymentModel> items) async {
    final d = await db;
    final batch = d.batch();
    for (final pay in items) {
      batch.insert('payments', {...pay.toJson(), 'synced': 1},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<PaymentModel>> getCachedPayments() async {
    final d = await db;
    final rows = await d.query('payments', orderBy: 'payment_date DESC');
    return rows.map(PaymentModel.fromJson).toList();
  }

  // ── Documents ──────────────────────────────────────────
  Future<void> cacheDocuments(List<DocumentModel> items) async {
    final d = await db;
    final batch = d.batch();
    for (final doc in items) {
      batch.insert('documents', {...doc.toJson(), 'synced': 1},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<DocumentModel>> getCachedDocuments() async {
    final d = await db;
    final rows = await d.query('documents', orderBy: 'uploaded_at DESC');
    return rows.map(DocumentModel.fromJson).toList();
  }

  // ── Pending Sync Queue ─────────────────────────────────
  Future<void> _addPendingSync(
      String table, String recordId, String action, Map<String, dynamic> data) async {
    final d = await db;
    await d.insert('pending_sync', {
      'table_name': table,
      'record_id': recordId,
      'action': action,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSync() async {
    final d = await db;
    return d.query('pending_sync', orderBy: 'id ASC');
  }

  Future<void> clearPendingSync(List<int> ids) async {
    final d = await db;
    if (ids.isEmpty) return;
    final placeholders = ids.map((_) => '?').join(',');
    await d.rawDelete('DELETE FROM pending_sync WHERE id IN ($placeholders)', ids);
  }

  Future<void> clearAllCaches() async {
    final d = await db;
    final tables = [
      'parties', 'media_houses', 'agency_mappings', 'release_orders',
      'publications', 'invoices', 'payments', 'documents'
    ];
    final batch = d.batch();
    for (final t in tables) batch.delete(t);
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final d = _db;
    if (d != null) {
      await d.close();
      _db = null;
    }
  }
}
