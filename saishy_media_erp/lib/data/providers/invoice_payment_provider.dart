import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/connectivity_service.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';

// ── Invoice Repository ─────────────────────────────────
class InvoiceRepository {
  final _api   = ApiService();
  final _local = LocalDbService.instance;
  final _conn  = ConnectivityService.instance;

  Future<List<InvoiceModel>> getAll() async {
    if (_conn.isOnline) {
      try {
        final data   = await _api.getRecords(ApiConstants.sheetInvoices);
        final models = data.map(InvoiceModel.fromJson).toList();
        await _local.cacheInvoices(models);
        return models;
      } catch (_) {}
    }
    return _local.getCachedInvoices();
  }

  Future<InvoiceModel> create(InvoiceModel invoice) async {
    if (_conn.isOnline) {
      await _api.createRecord(ApiConstants.sheetInvoices, invoice.toJson());
    }
    return invoice;
  }

  Future<InvoiceModel> update(InvoiceModel invoice) async {
    if (_conn.isOnline) {
      await _api.updateRecord(
          ApiConstants.sheetInvoices, invoice.invoiceNumber, invoice.toJson());
    }
    return invoice;
  }

  Future<String> getNextInvoiceNumber() async {
    if (_conn.isOnline) return _api.getNextNumber('INV');
    final now = DateTime.now();
    final ym  = '${now.year}${now.month.toString().padLeft(2,'0')}';
    final invs = await _local.getCachedInvoices();
    final seq  = invs.where((i) => i.invoiceNumber.contains('-$ym-')).length + 1;
    return 'INV-$ym-${seq.toString().padLeft(4,'0')}';
  }
}

// ── Payment Repository ─────────────────────────────────
class PaymentRepository {
  final _api   = ApiService();
  final _local = LocalDbService.instance;
  final _conn  = ConnectivityService.instance;

  Future<List<PaymentModel>> getAll() async {
    if (_conn.isOnline) {
      try {
        final data   = await _api.getRecords(ApiConstants.sheetPayments);
        final models = data.map(PaymentModel.fromJson).toList();
        await _local.cachePayments(models);
        return models;
      } catch (_) {}
    }
    return _local.getCachedPayments();
  }

  Future<PaymentModel> create(PaymentModel payment) async {
    final model = payment.copyWith(
        id: payment.id.isEmpty ? const Uuid().v4() : payment.id);
    if (_conn.isOnline) {
      await _api.createRecord(ApiConstants.sheetPayments, model.toJson());
    }
    return model;
  }
}

// ── Invoice Notifier ───────────────────────────────────
class InvoiceNotifier extends AsyncNotifier<List<InvoiceModel>> {
  late InvoiceRepository _repo;

  @override
  Future<List<InvoiceModel>> build() async {
    _repo = ref.read(invoiceRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<bool> create(InvoiceModel invoice) async {
    try {
      final created = await _repo.create(invoice);
      state = AsyncData([created, ...state.valueOrNull ?? []]);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> update(InvoiceModel invoice) async {
    try {
      final updated = await _repo.update(invoice);
      state = AsyncData(
        (state.valueOrNull ?? [])
            .map((i) => i.invoiceNumber == updated.invoiceNumber ? updated : i)
            .toList(),
      );
      return true;
    } catch (_) { return false; }
  }

  Future<String> getNextNumber() => _repo.getNextInvoiceNumber();
}

// ── Payment Notifier ───────────────────────────────────
class PaymentNotifier extends AsyncNotifier<List<PaymentModel>> {
  late PaymentRepository _repo;

  @override
  Future<List<PaymentModel>> build() async {
    _repo = ref.read(paymentRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<bool> create(PaymentModel payment) async {
    try {
      final created = await _repo.create(payment);
      state = AsyncData([created, ...state.valueOrNull ?? []]);
      return true;
    } catch (_) { return false; }
  }
}

// ── Providers ─────────────────────────────────────────
final invoiceRepositoryProvider =
    Provider<InvoiceRepository>((_) => InvoiceRepository());

final paymentRepositoryProvider =
    Provider<PaymentRepository>((_) => PaymentRepository());

final invoiceProvider =
    AsyncNotifierProvider<InvoiceNotifier, List<InvoiceModel>>(InvoiceNotifier.new);

final paymentProvider =
    AsyncNotifierProvider<PaymentNotifier, List<PaymentModel>>(PaymentNotifier.new);

final invoiceByNumberProvider =
    Provider.family<InvoiceModel?, String>((ref, number) {
  final invs = ref.watch(invoiceProvider).valueOrNull ?? [];
  try { return invs.firstWhere((i) => i.invoiceNumber == number); }
  catch (_) { return null; }
});

final pendingInvoicesProvider = Provider<List<InvoiceModel>>((ref) {
  final invs = ref.watch(invoiceProvider).valueOrNull ?? [];
  return invs.where((i) => i.status != 'Paid').toList();
});

final outstandingAmountProvider = Provider<double>((ref) {
  final invs = ref.watch(invoiceProvider).valueOrNull ?? [];
  return invs.fold<double>(0, (sum, i) => sum + i.balanceAmount);
});
