import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/connectivity_service.dart';
import '../models/release_order_model.dart';
import '../models/publication_model.dart';
import '../models/invoice_model.dart';

// ── RO Repository ─────────────────────────────────────
class ReleaseOrderRepository {
  final _api   = ApiService();
  final _local = LocalDbService.instance;
  final _conn  = ConnectivityService.instance;

  Future<List<ReleaseOrderModel>> getAll() async {
    if (_conn.isOnline) {
      try {
        final data   = await _api.getRecords(ApiConstants.sheetReleaseOrders);
        final models = data.map(ReleaseOrderModel.fromJson).toList();
        await _local.cacheReleaseOrders(models);
        return models;
      } catch (_) {}
    }
    return _local.getCachedReleaseOrders();
  }

  Future<ReleaseOrderModel> create(ReleaseOrderModel ro) async {
    if (_conn.isOnline) {
      await _api.createRecord(ApiConstants.sheetReleaseOrders, ro.toJson());
      await _local.upsertReleaseOrder(ro, synced: true);
    } else {
      await _local.upsertReleaseOrder(ro, synced: false);
    }
    return ro;
  }

  Future<ReleaseOrderModel> update(ReleaseOrderModel ro) async {
    if (_conn.isOnline) {
      await _api.updateRecord(ApiConstants.sheetReleaseOrders, ro.roNumber, ro.toJson());
      await _local.upsertReleaseOrder(ro, synced: true);
    } else {
      await _local.upsertReleaseOrder(ro, synced: false);
    }
    return ro;
  }

  Future<String> getNextRoNumber() async {
    if (_conn.isOnline) {
      return _api.getNextNumber('RO');
    }
    final now = DateTime.now();
    final ym  = '${now.year}${now.month.toString().padLeft(2,'0')}';
    final ros = await _local.getCachedReleaseOrders();
    final seq = ros.where((r) => r.roNumber.contains('-$ym-')).length + 1;
    return 'RO-$ym-${seq.toString().padLeft(4,'0')}-DRAFT';
  }
}

// ── Publication Repository ─────────────────────────────
class PublicationRepository {
  final _api   = ApiService();
  final _local = LocalDbService.instance;
  final _conn  = ConnectivityService.instance;

  Future<List<PublicationModel>> getAll() async {
    if (_conn.isOnline) {
      try {
        final data   = await _api.getRecords(ApiConstants.sheetPublications);
        final models = data.map(PublicationModel.fromJson).toList();
        await _local.cachePublications(models);
        return models;
      } catch (_) {}
    }
    return _local.getCachedPublications();
  }

  Future<PublicationModel> updateStatus(PublicationModel pub) async {
    if (_conn.isOnline) {
      await _api.updateRecord(ApiConstants.sheetPublications, pub.id, pub.toJson());
    }
    return pub;
  }

  Future<PublicationModel> create(PublicationModel pub) async {
    final model = pub.copyWith(id: pub.id.isEmpty ? const Uuid().v4() : pub.id);
    if (_conn.isOnline) {
      await _api.createRecord(ApiConstants.sheetPublications, model.toJson());
    }
    return model;
  }
}

// ── RO Notifier ───────────────────────────────────────
class ReleaseOrderNotifier extends AsyncNotifier<List<ReleaseOrderModel>> {
  late ReleaseOrderRepository _repo;

  @override
  Future<List<ReleaseOrderModel>> build() async {
    _repo = ref.read(roRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<bool> create(ReleaseOrderModel ro) async {
    try {
      final created = await _repo.create(ro);
      state = AsyncData([created, ...state.valueOrNull ?? []]);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> update(ReleaseOrderModel ro) async {
    try {
      final updated = await _repo.update(ro);
      state = AsyncData(
        (state.valueOrNull ?? [])
            .map((r) => r.roNumber == updated.roNumber ? updated : r)
            .toList(),
      );
      return true;
    } catch (_) { return false; }
  }

  Future<String> getNextNumber() => _repo.getNextRoNumber();
}

// ── Publication Notifier ───────────────────────────────
class PublicationNotifier extends AsyncNotifier<List<PublicationModel>> {
  late PublicationRepository _repo;

  @override
  Future<List<PublicationModel>> build() async {
    _repo = ref.read(publicationRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<bool> updateStatus(PublicationModel pub) async {
    try {
      final updated = await _repo.updateStatus(pub);
      state = AsyncData(
        (state.valueOrNull ?? [])
            .map((p) => p.id == updated.id ? updated : p)
            .toList(),
      );
      return true;
    } catch (_) { return false; }
  }

  Future<bool> create(PublicationModel pub) async {
    try {
      final created = await _repo.create(pub);
      state = AsyncData([created, ...state.valueOrNull ?? []]);
      return true;
    } catch (_) { return false; }
  }
}

// ── Providers ─────────────────────────────────────────
final roRepositoryProvider =
    Provider<ReleaseOrderRepository>((_) => ReleaseOrderRepository());

final publicationRepositoryProvider =
    Provider<PublicationRepository>((_) => PublicationRepository());

final releaseOrderProvider =
    AsyncNotifierProvider<ReleaseOrderNotifier, List<ReleaseOrderModel>>(
  ReleaseOrderNotifier.new,
);

final publicationProvider =
    AsyncNotifierProvider<PublicationNotifier, List<PublicationModel>>(
  PublicationNotifier.new,
);

final roByNumberProvider =
    Provider.family<ReleaseOrderModel?, String>((ref, roNumber) {
  final ros = ref.watch(releaseOrderProvider).valueOrNull ?? [];
  try {
    return ros.firstWhere((r) => r.roNumber == roNumber);
  } catch (_) { return null; }
});

final pendingPublicationsProvider = Provider<List<PublicationModel>>((ref) {
  final pubs = ref.watch(publicationProvider).valueOrNull ?? [];
  return pubs.where((p) => p.status != 'Published' && p.status != 'Billed' && p.status != 'Paid').toList();
});
