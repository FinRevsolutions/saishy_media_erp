import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/connectivity_service.dart';
import '../models/media_house_model.dart';
import '../models/agency_mapping_model.dart';

// ── Media House Repository ─────────────────────────────
class MediaHouseRepository {
  final _api   = ApiService();
  final _local = LocalDbService.instance;
  final _conn  = ConnectivityService.instance;

  Future<List<MediaHouseModel>> getAll() async {
    if (_conn.isOnline) {
      try {
        final data   = await _api.getRecords(ApiConstants.sheetMediaHouses);
        final models = data.map(MediaHouseModel.fromJson).where((m) => m.isActive).toList();
        await _local.cacheMediaHouses(models);
        return models;
      } catch (_) {}
    }
    return _local.getCachedMediaHouses();
  }

  Future<MediaHouseModel> create(MediaHouseModel model) async {
    final m = model.copyWith(id: model.id.isEmpty ? const Uuid().v4() : model.id);
    if (_conn.isOnline) {
      await _api.createRecord(ApiConstants.sheetMediaHouses, m.toJson());
    }
    await _local.cacheMediaHouses([m]);
    return m;
  }

  Future<MediaHouseModel> update(MediaHouseModel model) async {
    if (_conn.isOnline) {
      await _api.updateRecord(ApiConstants.sheetMediaHouses, model.id, model.toJson());
    }
    await _local.cacheMediaHouses([model]);
    return model;
  }

  Future<void> delete(String id) async {
    if (_conn.isOnline) {
      await _api.deleteRecord(ApiConstants.sheetMediaHouses, id);
    }
  }
}

// ── Agency Mapping Repository ──────────────────────────
class AgencyMappingRepository {
  final _api   = ApiService();
  final _local = LocalDbService.instance;
  final _conn  = ConnectivityService.instance;

  Future<List<AgencyMappingModel>> getAll() async {
    if (_conn.isOnline) {
      try {
        final data   = await _api.getRecords(ApiConstants.sheetAgencyMappings);
        final models = data.map(AgencyMappingModel.fromJson).toList();
        await _local.cacheAgencyMappings(models);
        return models;
      } catch (_) {}
    }
    return _local.getCachedAgencyMappings();
  }

  Future<AgencyMappingModel> create(AgencyMappingModel model) async {
    final m = model.copyWith(id: model.id.isEmpty ? const Uuid().v4() : model.id);
    if (_conn.isOnline) {
      await _api.createRecord(ApiConstants.sheetAgencyMappings, m.toJson());
    }
    await _local.cacheAgencyMappings([m]);
    return m;
  }

  Future<AgencyMappingModel> update(AgencyMappingModel model) async {
    if (_conn.isOnline) {
      await _api.updateRecord(ApiConstants.sheetAgencyMappings, model.id, model.toJson());
    }
    await _local.cacheAgencyMappings([model]);
    return model;
  }

  Future<void> delete(String id) async {
    if (_conn.isOnline) {
      await _api.deleteRecord(ApiConstants.sheetAgencyMappings, id);
    }
  }

  Future<String?> getAgencyNameForMediaHouse(String mediaHouseId) async {
    final mapping = await _local.getMappingForMediaHouse(mediaHouseId);
    return mapping?.agencyName;
  }
}

// ── Media House Notifier ───────────────────────────────
class MediaHouseNotifier extends AsyncNotifier<List<MediaHouseModel>> {
  late MediaHouseRepository _repo;

  @override
  Future<List<MediaHouseModel>> build() async {
    _repo = ref.read(mediaHouseRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<bool> create(MediaHouseModel model) async {
    try {
      final created = await _repo.create(model);
      state = AsyncData([...state.valueOrNull ?? [], created]);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> update(MediaHouseModel model) async {
    try {
      final updated = await _repo.update(model);
      state = AsyncData(
        (state.valueOrNull ?? []).map((m) => m.id == updated.id ? updated : m).toList(),
      );
      return true;
    } catch (_) { return false; }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      state = AsyncData((state.valueOrNull ?? []).where((m) => m.id != id).toList());
      return true;
    } catch (_) { return false; }
  }
}

// ── Agency Mapping Notifier ────────────────────────────
class AgencyMappingNotifier extends AsyncNotifier<List<AgencyMappingModel>> {
  late AgencyMappingRepository _repo;

  @override
  Future<List<AgencyMappingModel>> build() async {
    _repo = ref.read(agencyMappingRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<bool> create(AgencyMappingModel model) async {
    try {
      final created = await _repo.create(model);
      state = AsyncData([...state.valueOrNull ?? [], created]);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> update(AgencyMappingModel model) async {
    try {
      final updated = await _repo.update(model);
      state = AsyncData(
        (state.valueOrNull ?? []).map((m) => m.id == updated.id ? updated : m).toList(),
      );
      return true;
    } catch (_) { return false; }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      state = AsyncData((state.valueOrNull ?? []).where((m) => m.id != id).toList());
      return true;
    } catch (_) { return false; }
  }
}

// ── Providers ─────────────────────────────────────────
final mediaHouseRepositoryProvider =
    Provider<MediaHouseRepository>((_) => MediaHouseRepository());

final agencyMappingRepositoryProvider =
    Provider<AgencyMappingRepository>((_) => AgencyMappingRepository());

final mediaHouseProvider =
    AsyncNotifierProvider<MediaHouseNotifier, List<MediaHouseModel>>(
  MediaHouseNotifier.new,
);

final agencyMappingProvider =
    AsyncNotifierProvider<AgencyMappingNotifier, List<AgencyMappingModel>>(
  AgencyMappingNotifier.new,
);

final agencyForMediaHouseProvider =
    Provider.family<String, String>((ref, mediaHouseId) {
  final mappings = ref.watch(agencyMappingProvider).valueOrNull ?? [];
  final mapping  = mappings.firstWhere(
    (m) => m.mediaHouseId == mediaHouseId,
    orElse: () => AgencyMappingModel(
        id: '', mediaHouseId: '', mediaHouseName: '', agencyName: ''),
  );
  return mapping.agencyName;
});
