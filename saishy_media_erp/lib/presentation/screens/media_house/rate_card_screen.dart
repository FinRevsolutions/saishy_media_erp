import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/media_house_model.dart';
import '../../../data/models/media_rate_card_model.dart';
import '../../../data/providers/rate_card_provider.dart';

class RateCardScreen extends ConsumerStatefulWidget {
  final MediaHouseModel mediaHouse;
  const RateCardScreen({super.key, required this.mediaHouse});

  @override
  ConsumerState<RateCardScreen> createState() => _RateCardScreenState();
}

class _RateCardScreenState extends ConsumerState<RateCardScreen> {
  final Map<String, TextEditingController> _rateControllers = {};
  String _selectedUnit = 'col×cm';
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final type in MediaRateCardModel.rateTypes) {
      _rateControllers[type] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  void _loadExisting() {
    final existing = ref.read(rateCardsForMediaHouseProvider(widget.mediaHouse.id));
    if (existing.isNotEmpty) {
      setState(() => _selectedUnit = existing.first.unit);
      for (final card in existing) {
        _rateControllers[card.rateType]?.text =
            card.ratePerUnit > 0 ? card.ratePerUnit.toStringAsFixed(2) : '';
      }
    }
  }

  @override
  void dispose() {
    for (final c in _rateControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final rates = <MediaRateCardModel>[];
    for (final entry in _rateControllers.entries) {
      final rate = double.tryParse(entry.value.text.trim());
      if (rate != null && rate > 0) {
        rates.add(MediaRateCardModel(
          id: const Uuid().v4(),
          mediaHouseId: widget.mediaHouse.id,
          mediaHouseName: widget.mediaHouse.name,
          rateType: entry.key,
          ratePerUnit: rate,
          unit: _selectedUnit,
        ));
      }
    }

    final ok = await ref.read(rateCardProvider.notifier).saveForMediaHouse(
      widget.mediaHouse.id,
      widget.mediaHouse.name,
      rates,
    );

    setState(() => _saving = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Rate card saved (${rates.length} rates)' : 'Failed to save rate card'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rate Card', style: TextStyle(fontSize: 16)),
            Text(widget.mediaHouse.name,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save Rates'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Unit selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rate Unit', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: MediaRateCardModel.units.map((unit) => GestureDetector(
                    onTap: () => setState(() => _selectedUnit = unit),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedUnit == unit ? AppColors.primary : AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _selectedUnit == unit ? AppColors.primary : AppColors.borderDark),
                      ),
                      child: Text(unit, style: TextStyle(
                        color: _selectedUnit == unit ? Colors.white : AppColors.textSecondary,
                        fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rate cards
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Text('Advertisement Rates', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ),
                const Divider(color: AppColors.borderDark, height: 1),
                ...MediaRateCardModel.rateTypes.map((type) => _RateRow(
                  type: type,
                  unit: _selectedUnit,
                  controller: _rateControllers[type]!,
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: Row(children: const [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.info, size: 16),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Rates auto-fill when you select this media house in a Release Order. Leave 0 or blank to skip a rate type.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              )),
            ]),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  final String type;
  final String unit;
  final TextEditingController controller;

  const _RateRow({required this.type, required this.unit, required this.controller});

  static const Map<String, IconData> _icons = {
    'Black & White': Icons.contrast_rounded,
    'Color':         Icons.palette_outlined,
    'Front Page':    Icons.first_page_rounded,
    'Jacket':        Icons.bookmark_border_rounded,
    'Pointer':       Icons.point_of_sale_rounded,
    'Government':    Icons.account_balance_outlined,
    'Classified':    Icons.format_list_bulleted_rounded,
    'Display':       Icons.aspect_ratio_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icons[type] ?? Icons.monetization_on_outlined, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(type, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.end,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('/$unit', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}
