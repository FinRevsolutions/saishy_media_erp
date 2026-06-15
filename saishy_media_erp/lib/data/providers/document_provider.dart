import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/connectivity_service.dart';
import '../models/document_model.dart';

class DocumentRepository {
  final _api = ApiService();
  final _local = LocalDbService.instance;
  final _conn = ConnectivityService.instance;

  Future<List<DocumentModel>> getAll() async {
    if (_conn.isOnline) {
      try {
        final data = await _api.getRecords(ApiConstants.sheetDocuments);
        final models = data.map(DocumentModel.fromJson).toList();
        await _local.cacheDocuments(models);
        return models;
      } catch (_) {}
    }
    return _local.getCachedDocuments();
  }

  Future<DocumentModel> uploadDocument({
    required String referenceNumber,
    required String referenceType,
    required String documentType,
    required String fileName,
    required String base64Data,
    required String mimeType,
    required String uploadedBy,
    String? description,
  }) async {
    final docId = const Uuid().v4();
    
    String fileUrl = '';
    String driveFileId = '';
    
    if (_conn.isOnline) {
      try {
        // We can pass a folder ID or empty string for default
        final res = await _api.uploadFile(
          fileName: fileName,
          base64Data: base64Data,
          mimeType: mimeType,
          folderId: '', // Root or default configuration in Apps Script
        );
        fileUrl = res['url']?.toString() ?? '';
        driveFileId = res['id']?.toString() ?? '';
      } catch (_) {
        // Fallback fileUrl if upload fails but we need to proceed
        fileUrl = 'offline_pending_upload';
      }
    } else {
      fileUrl = 'offline_pending_upload';
    }

    final doc = DocumentModel(
      id: docId,
      referenceNumber: referenceNumber,
      referenceType: referenceType,
      documentType: documentType,
      fileUrl: fileUrl,
      driveFileId: driveFileId.isNotEmpty ? driveFileId : null,
      fileName: fileName,
      fileSizeBytes: (base64Data.length * 0.75).toInt(), // approximate size
      mimeType: mimeType,
      description: description,
      uploadedBy: uploadedBy,
      uploadedAt: DateTime.now(),
    );

    if (_conn.isOnline && fileUrl != 'offline_pending_upload') {
      await _api.createRecord(ApiConstants.sheetDocuments, doc.toJson());
      await _local.cacheDocuments([doc]);
    } else {
      // Offline queue will handle this later or SQLite cache shows it
      await _local.cacheDocuments([doc]);
      // Also add to custom pending table if needed, or simply cache it locally
    }

    return doc;
  }
}

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

  Future<bool> upload({
    required String referenceNumber,
    required String referenceType,
    required String documentType,
    required String fileName,
    required String base64Data,
    required String mimeType,
    required String uploadedBy,
    String? description,
  }) async {
    try {
      final doc = await _repo.uploadDocument(
        referenceNumber: referenceNumber,
        referenceType: referenceType,
        documentType: documentType,
        fileName: fileName,
        base64Data: base64Data,
        mimeType: mimeType,
        uploadedBy: uploadedBy,
        description: description,
      );
      state = AsyncData([doc, ...state.valueOrNull ?? []]);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((_) => DocumentRepository());

final documentProvider = AsyncNotifierProvider<DocumentNotifier, List<DocumentModel>>(
  DocumentNotifier.new,
);
