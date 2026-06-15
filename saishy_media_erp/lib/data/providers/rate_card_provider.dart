import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/connectivity_service.dart';
import '../models/media_rate_card_model.dart';

// ── Repository ─────────────────────────────────────────
class MediaRateCardRepository {
  static const String _sheet = 'RateCards';
  final _api  = ApiService();
  final _conn = ConnectivityService.instance;

  // In-memory cache (lightweight — no SQLite table needed)
  List<MediaRateCardModel> _cache = [];

  Future<List<MediaRateCardModel>> getAll() async {
    if (_conn.isOnline) {
      try {
        final data = await _api.getRecords(_sheet);
        _cache = data
            .map(MediaRateCardModel.fromJson)
            .where((r) => r.isActive)
            .toList();
        return _cache;
      } catch (_) {}
    }
    return _cache;
  }

  Future<List<MediaRateCardModel>> getForMediaHouse(String mediaHouseId) async {
    final all = await getAll();
    return all.where((r) => r.mediaHouseId == mediaHouseId).toList();
  }

  Future<MediaRateCardModel?> getRateFor(
      String mediaHouseId, String rateType) async {
    final rates = await getForMediaHouse(mediaHouseId);
    try {
      return rates.firstWhere((r) => r.rateType == rateType);
    } catch (_) {
      return null;
    }
  }

  Future<MediaRateCardModel> create(MediaRateCardModel model) async {
    final m = model.copyWith(id: model.id.isEmpty ? const Uuid().v4() : model.id);
    if (_conn.isOnline) {
      await _api.createRecord(_sheet, m.toJson());
    }
    _cache = [..._cache.where((r) => r.id != m.id), m];
    return m;
  }

  Future<MediaRateCardModel> update(MediaRateCardModel model) async {
    if (_conn.isOnline) {
      await _api.updateRecord(_sheet, model.id, model.toJson());
    }
    _cache = _cache.map((r) => r.id == model.id ? model : r).toList();
    return model;
  }

  Future<void> delete(String id) async {
    if (_conn.isOnline) {
      await _api.deleteRecord(_sheet, id);
    }
    _cache = _cache.where((r) => r.id != id).toList();
  }

  /// Upsert a full rate card set for a media house (replace all)
  Future<void> saveRatesForMediaHouse(
      String mediaHouseId, String mediaHouseName,
      List<MediaRateCardModel> rates) async {
    // Delete existing
    final existing = await getForMediaHouse(mediaHouseId);
    for (final e in existing) {
      await delete(e.id);
    }
    // Create new
    for (final rate in rates) {
      await create(rate.copyWith(
        mediaHouseId: mediaHouseId,
        mediaHouseName: mediaHouseName,
      ));
    }
  }
}

// ── Notifier ──────────────────────────────────────────
class MediaRateCardNotifier extends AsyncNotifier<List<MediaRateCardModel>> {
  late MediaRateCardRepository _repo;

  @override
  Future<List<MediaRateCardModel>> build() async {
    _repo = ref.read(rateCardRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<bool> saveForMediaHouse(
      String mediaHouseId, String mediaHouseName,
      List<MediaRateCardModel> rates) async {
    try {
      await _repo.saveRatesForMediaHouse(mediaHouseId, mediaHouseName, rates);
      state = await AsyncValue.guard(() => _repo.getAll());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      state = AsyncData(
        (state.valueOrNull ?? []).where((r) => r.id != id).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ── Providers ─────────────────────────────────────────
final rateCardRepositoryProvider =
    Provider<MediaRateCardRepository>((_) => MediaRateCardRepository());

final rateCardProvider =
    AsyncNotifierProvider<MediaRateCardNotifier, List<MediaRateCardModel>>(
  MediaRateCardNotifier.new,
);

/// Get all rate cards for a specific media house
final rateCardsForMediaHouseProvider =
    Provider.family<List<MediaRateCardModel>, String>((ref, mediaHouseId) {
  final all = ref.watch(rateCardProvider).valueOrNull ?? [];
  return all.where((r) => r.mediaHouseId == mediaHouseId).toList();
});

/// Auto-fill: get the rate for a specific media house + rate type
final autoFillRateProvider =
    Provider.family<double?, ({String mediaHouseId, String rateType})>(
        (ref, args) {
  final cards = ref.watch(rateCardsForMediaHouseProvider(args.mediaHouseId));
  try {
    return cards.firstWhere((c) => c.rateType == args.rateType).ratePerUnit;
  } catch (_) {
    return null;
  }
});

/// Get the unit for a specific media house (first card's unit)
final autoFillUnitProvider = Provider.family<String?, String>((ref, mediaHouseId) {
  final cards = ref.watch(rateCardsForMediaHouseProvider(mediaHouseId));
  return cards.isEmpty ? null : cards.first.unit;
});
