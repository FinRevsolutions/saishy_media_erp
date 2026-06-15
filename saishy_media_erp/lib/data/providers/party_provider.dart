import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/connectivity_service.dart';
import '../models/party_model.dart';
import 'package:uuid/uuid.dart';

// ── Repository ────────────────────────────────────────
class PartyRepository {
  final _api   = ApiService();
  final _local = LocalDbService.instance;
  final _conn  = ConnectivityService.instance;

  Future<List<PartyModel>> getAll() async {
    if (_conn.isOnline) {
      try {
        final data = await _api.getRecords(ApiConstants.sheetClients);
        final models = data.map(PartyModel.fromJson).where((p) => p.isActive).toList();
        await _local.cacheParties(models);
        return models;
      } catch (_) {}
    }
    return _local.getCachedParties();
  }

  Future<PartyModel> create(PartyModel party) async {
    final model = party.copyWith(id: party.id.isEmpty ? const Uuid().v4() : party.id);
    if (_conn.isOnline) {
      await _api.createRecord(ApiConstants.sheetClients, model.toJson());
      await _local.upsertParty(model, synced: true);
    } else {
      await _local.upsertParty(model, synced: false);
    }
    return model;
  }

  Future<PartyModel> update(PartyModel party) async {
    if (_conn.isOnline) {
      await _api.updateRecord(ApiConstants.sheetClients, party.id, party.toJson());
      await _local.upsertParty(party, synced: true);
    } else {
      await _local.upsertParty(party, synced: false);
    }
    return party;
  }

  Future<void> delete(String id) async {
    if (_conn.isOnline) {
      await _api.deleteRecord(ApiConstants.sheetClients, id);
    }
    final cached = await _local.getCachedParties();
    final party  = cached.firstWhere((p) => p.id == id, orElse: () => PartyModel(id: id, name: '', address: '', mobile: ''));
    await _local.upsertParty(party.copyWith(isActive: false), synced: _conn.isOnline);
  }
}

// ── Notifier ──────────────────────────────────────────
class PartyNotifier extends AsyncNotifier<List<PartyModel>> {
  late PartyRepository _repo;

  @override
  Future<List<PartyModel>> build() async {
    _repo = ref.read(partyRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<bool> create(PartyModel party) async {
    try {
      final created = await _repo.create(party);
      state = AsyncData([...state.valueOrNull ?? [], created]);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> update(PartyModel party) async {
    try {
      final updated = await _repo.update(party);
      state = AsyncData(
        (state.valueOrNull ?? []).map((p) => p.id == updated.id ? updated : p).toList(),
      );
      return true;
    } catch (_) { return false; }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      state = AsyncData((state.valueOrNull ?? []).where((p) => p.id != id).toList());
      return true;
    } catch (_) { return false; }
  }
}

// ── Providers ─────────────────────────────────────────
final partyRepositoryProvider = Provider<PartyRepository>((_) => PartyRepository());

final partyProvider = AsyncNotifierProvider<PartyNotifier, List<PartyModel>>(
  PartyNotifier.new,
);

final partySearchProvider = Provider.family<List<PartyModel>, String>((ref, query) {
  final parties = ref.watch(partyProvider).valueOrNull ?? [];
  if (query.isEmpty) return parties;
  final q = query.toLowerCase();
  return parties.where((p) =>
    p.name.toLowerCase().contains(q) ||
    p.mobile.contains(q) ||
    (p.contactPerson?.toLowerCase().contains(q) ?? false)
  ).toList();
});
