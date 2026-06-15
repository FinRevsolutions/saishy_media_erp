import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/document_model.dart';
import '../../../data/providers/document_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class DocumentVaultScreen extends ConsumerStatefulWidget {
  const DocumentVaultScreen({super.key});

  @override
  ConsumerState<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends ConsumerState<DocumentVaultScreen> {
  String _search = '';
  String _selectedType = 'All';

  final List<String> _docTypes = ['All', 'RO', 'Invoice', 'Cutting', 'Receipt', 'Other'];

  Future<void> _pickAndUpload(BuildContext context, String source) async {
    final user = ref.read(currentUserProvider);
    final userLabel = user?.fullName ?? 'Unknown';

    // Show Dialog to select reference
    final refController = TextEditingController();
    final descController = TextEditingController();
    String docType = 'Cutting';
    String refType = 'RO';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Document Details', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: docType,
                  dropdownColor: AppColors.cardDark,
                  decoration: const InputDecoration(labelText: 'Document Type'),
                  items: ['RO', 'Invoice', 'Cutting', 'Receipt', 'Other']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: AppColors.textPrimary))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setModalState(() {
                        docType = v;
                        if (v == 'RO' || v == 'Cutting') refType = 'RO';
                        if (v == 'Invoice' || v == 'Receipt') refType = 'Invoice';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Reference Number',
                    hintText: refType == 'RO' ? 'e.g. RO-202606-0001' : 'e.g. INV-202606-0001',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Description / Notes',
                    hintText: 'Optional notes about this file',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (refController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please enter reference number'),
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Upload'),
            ),
          ],
        );
      }),
    );

    if (result != true) return;

    final imagePicker = ImagePicker();
    String? base64Data;
    String? fileName;
    String? mimeType;

    if (source == 'camera') {
      final file = await imagePicker.pickImage(source: ImageSource.camera, imageQuality: 75);
      if (file != null) {
        final bytes = await file.readAsBytes();
        base64Data = base64Encode(bytes);
        fileName = file.name;
        mimeType = 'image/jpeg';
      }
    } else if (source == 'gallery') {
      final file = await imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (file != null) {
        final bytes = await file.readAsBytes();
        base64Data = base64Encode(bytes);
        fileName = file.name;
        mimeType = 'image/jpeg';
      }
    } else if (source == 'pdf') {
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (res != null && res.files.single.path != null) {
        final file = res.files.single;
        final bytes = await file.xFile.readAsBytes();
        base64Data = base64Encode(bytes);
        fileName = file.name;
        mimeType = 'application/pdf';
      }
    }

    if (base64Data == null || fileName == null || mimeType == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Uploading document to Drive/Sheets...'),
      behavior: SnackBarBehavior.floating,
    ));

    final ok = await ref.read(documentProvider.notifier).upload(
      referenceNumber: refController.text.trim(),
      referenceType: refType,
      documentType: docType,
      fileName: fileName,
      base64Data: base64Data,
      mimeType: mimeType,
      uploadedBy: userLabel,
      description: descController.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Document uploaded successfully' : 'Failed to upload document'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderDark, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Upload Document', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Camera Capture', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(context, 'camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
              title: const Text('Gallery Upload', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(context, 'gallery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.error),
              title: const Text('PDF Document', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(context, 'pdf');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Document Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(documentProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips and Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search by reference number or filename...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _docTypes.map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedType = type);
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: docsAsync.when(
              loading: () => const LoadingWidget(message: 'Loading Document Vault...'),
              error: (e, _) => EmptyStateWidget(title: 'Error', subtitle: e.toString(), icon: Icons.error_outline_rounded),
              data: (docs) {
                final filtered = docs.where((doc) {
                  final matchesSearch = doc.referenceNumber.toLowerCase().contains(_search.toLowerCase()) ||
                      (doc.fileName?.toLowerCase().contains(_search.toLowerCase()) ?? false);
                  final matchesType = _selectedType == 'All' || doc.documentType.toLowerCase() == _selectedType.toLowerCase();
                  return matchesSearch && matchesType;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No Documents Found',
                    subtitle: 'Use the camera or file picker to upload documents to Drive.',
                    icon: Icons.folder_open_rounded,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    return _DocumentTile(doc: doc)
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: index * 30), duration: 250.ms);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadOptions(context),
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Upload File'),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final DocumentModel doc;
  const _DocumentTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final dateStr = doc.uploadedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(doc.uploadedAt!) : 'Unknown';
    final sizeKb = doc.fileSizeBytes != null ? '${(doc.fileSizeBytes! / 1024).toStringAsFixed(1)} KB' : 'Unknown size';
    final icon = doc.isPdf
        ? Icons.picture_as_pdf_outlined
        : (doc.isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined);
    final iconColor = doc.isPdf
        ? AppColors.error
        : (doc.isImage ? AppColors.accent : AppColors.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.fileName ?? 'Unnamed File',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${doc.documentType} • Ref: ${doc.referenceNumber} • $sizeKb',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  'By ${doc.uploadedBy} on $dateStr',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
            color: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              if (v == 'view') {
                // Open file url
                Share.share('Check out this file on Google Drive: ${doc.fileUrl}');
              } else if (v == 'share') {
                Share.share('Document ${doc.fileName}: ${doc.fileUrl}');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'view',
                child: ListTile(
                  leading: Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textPrimary),
                  title: Text('Open Link', style: TextStyle(color: AppColors.textPrimary)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share_outlined, size: 18, color: AppColors.primary),
                  title: Text('Share Link', style: TextStyle(color: AppColors.primary)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
