import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';

/// 記録入力・編集用ボトムシート
class RecordEditSheet extends StatefulWidget {
  final DateTime date;

  const RecordEditSheet({super.key, required this.date});

  static Future<void> show(BuildContext context, DateTime date) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordEditSheet(date: date),
    );
  }

  @override
  State<RecordEditSheet> createState() => _RecordEditSheetState();
}

class _RecordEditSheetState extends State<RecordEditSheet> {
  late TextEditingController _cardioController;
  late TextEditingController _strengthController;
  late TextEditingController _otherController;
  late TextEditingController _memoController;
  late TextEditingController _weightController;
  late TextEditingController _bodyFatController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<WorkoutProvider>();
    final record = provider.getRecord(widget.date);

    _cardioController = TextEditingController(
      text: record != null && record.cardioMinutes > 0
          ? record.cardioMinutes.toString()
          : '',
    );
    _strengthController = TextEditingController(
      text: record != null && record.strengthMinutes > 0
          ? record.strengthMinutes.toString()
          : '',
    );
    _otherController = TextEditingController(
      text: record != null && record.otherMinutes > 0
          ? record.otherMinutes.toString()
          : '',
    );
    _memoController = TextEditingController(text: record?.memo ?? '');
    _weightController = TextEditingController(
      text: record?.weightKg != null ? _formatNum(record!.weightKg!) : '',
    );
    _bodyFatController = TextEditingController(
      text: record?.bodyFatPercent != null ? _formatNum(record!.bodyFatPercent!) : '',
    );
  }

  String _formatNum(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _cardioController.dispose();
    _strengthController.dispose();
    _otherController.dispose();
    _memoController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  int _parseMinutes(String text) {
    if (text.trim().isEmpty) return 0;
    return int.tryParse(text.trim()) ?? 0;
  }

  double? _parseDouble(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.trim());
  }

  Future<void> _save() async {
    final provider = context.read<WorkoutProvider>();
    await provider.saveRecord(
      date: widget.date,
      cardioMinutes: _parseMinutes(_cardioController.text),
      strengthMinutes: _parseMinutes(_strengthController.text),
      otherMinutes: _parseMinutes(_otherController.text),
      memo: _memoController.text.trim(),
      weightKg: _parseDouble(_weightController.text),
      bodyFatPercent: _parseDouble(_bodyFatController.text),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final provider = context.read<WorkoutProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('記録を削除'),
        content: const Text('この日の記録を削除しますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteRecord(widget.date);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final existing = provider.getRecord(widget.date);
    final dateLabel = DateFormat('yyyy年M月d日 (E)', 'ja_JP').format(widget.date);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (existing != null && existing.hasRecord)
                      IconButton(
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildMinuteField(
                  label: '有酸素運動',
                  icon: Icons.directions_run,
                  color: AppColors.cardio,
                  controller: _cardioController,
                ),
                const SizedBox(height: 14),
                _buildMinuteField(
                  label: '筋トレ',
                  icon: Icons.fitness_center,
                  color: AppColors.strength,
                  controller: _strengthController,
                ),
                const SizedBox(height: 14),
                _buildMinuteField(
                  label: 'その他',
                  icon: Icons.sports_gymnastics,
                  color: AppColors.other,
                  controller: _otherController,
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                const Text(
                  '体組成(任意)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDecimalField(
                  label: '体重',
                  icon: Icons.monitor_weight_outlined,
                  color: AppColors.weight,
                  controller: _weightController,
                  suffix: 'kg',
                ),
                const SizedBox(height: 14),
                _buildDecimalField(
                  label: '体脂肪率',
                  icon: Icons.percent,
                  color: AppColors.bodyFat,
                  controller: _bodyFatController,
                  suffix: '%',
                ),
                const SizedBox(height: 20),
                const Text(
                  'メモ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _memoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '今日の宅トレの感想や気づきなど',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('保存する', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinuteField({
    required String label,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          width: 100,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0',
              suffixText: '分',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecimalField({
    required String label,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String suffix,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          width: 100,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '-',
              suffixText: suffix,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}
