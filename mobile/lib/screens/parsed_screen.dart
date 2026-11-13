import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/expense_store.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/phrase_parser.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'listening_screen.dart';

/// Экран «Проверьте траты»: что распознано во фразе.
/// Можно поправить категорию и сумму, убрать лишнее и сохранить.
class ParsedScreen extends StatefulWidget {
  const ParsedScreen({super.key, required this.phrase});

  final String phrase;

  @override
  State<ParsedScreen> createState() => _ParsedScreenState();
}

class _ParsedScreenState extends State<ParsedScreen> {
  List<ParsedExpense>? _items;
  String? _error;
  bool _saving = false;

  TextStyle get _quoteStyle => AppText.body(19, weight: FontWeight.w500, height: 1.42);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await SpendlyApi.instance.parsePhrase(widget.phrase);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось разобрать фразу: $e');
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _items = null;
    });
    _load();
  }

  Future<void> _save() async {
    final items = _items;
    if (items == null || items.isEmpty) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final expenses = [
      for (var i = 0; i < items.length; i++)
        Expense(
          id: '${now.microsecondsSinceEpoch}-$i',
          title: items[i].title,
          category: items[i].category,
          amount: items[i].amount,
          date: now,
          phrase: items[i].phrase.isEmpty ? null : '«${items[i].phrase}»',
        ),
    ];

    try {
      await SpendlyApi.instance.saveExpenses(expenses);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить: $e')),
      );
      return;
    }

    ExpenseStore.instance.addAll(expenses);
    if (!mounted) return;
    final n = expenses.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Сохранено: $n ${pluralRu(n, 'трата', 'траты', 'трат')}')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _pickCategory(ParsedExpense item) async {
    final picked = await showModalBottomSheet<SpendCategory>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  'Категория: ${item.title.toLowerCase()}',
                  style: AppText.body(17, weight: FontWeight.w600),
                ),
              ),
              for (final category in SpendCategory.values)
                Material(
                  color: category == item.category ? AppColors.paper : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(sheetContext).pop(category),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          CategoryTile(category, size: 36),
                          const SizedBox(width: 12),
                          Expanded(child: Text(category.info.title, style: AppText.body(15))),
                          if (category == item.category) const Icon(Icons.check, color: AppColors.ink),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => item.category = picked);
    }
  }

  Future<void> _editAmount(ParsedExpense item) async {
    final controller = TextEditingController(text: '${item.amount}');
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Сумма: ${item.title.toLowerCase()}', style: AppText.body(18, weight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: AppText.body(18),
          decoration: appInputDecoration('Сумма в рублях', fill: AppColors.paper),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              int.tryParse(controller.text.replaceAll(RegExp(r'\D'), '')),
            ),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
    if (value != null && value > 0 && mounted) {
      setState(() => item.amount = value);
    }
  }

  void _remove(ParsedExpense item) {
    setState(() => _items?.remove(item));
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final count = items?.length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  IconButton.filled(
                    tooltip: 'Назад',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.ink,
                      fixedSize: const Size(44, 44),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Проверьте траты',
                      textAlign: TextAlign.center,
                      style: AppText.body(17, weight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                children: [
                  Text('Вы сказали', style: AppText.body(13, color: AppColors.muted)),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: _quoteStyle,
                      children: [
                        const TextSpan(text: '«'),
                        for (final s in PhraseParser.segments(widget.phrase))
                          TextSpan(
                            text: s.text,
                            style: s.isAmount ? _quoteStyle.copyWith(backgroundColor: AppColors.accent) : null,
                          ),
                        const TextSpan(text: '»'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_error != null)
                    _MessageCard(
                      title: 'Что-то пошло не так',
                      text: _error!,
                      actionLabel: 'Попробовать ещё раз',
                      onAction: _retry,
                    )
                  else if (items == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(color: AppColors.ink)),
                    )
                  else if (items.isEmpty)
                    const _MessageCard(
                      title: 'Не нашёл ни одной суммы',
                      text: 'Попробуйте сказать иначе, например: «кофе за двести» или «косарь на продукты».',
                    )
                  else ...[
                    _Receipt(
                      items: items,
                      onPickCategory: _pickCategory,
                      onEditAmount: _editAmount,
                      onRemove: _remove,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 16, color: AppColors.muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Нажмите на сумму или категорию, чтобы исправить',
                            style: AppText.body(13, color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AccentButton(
                    label: count == 0 ? 'Сохранить' : 'Сохранить $count ${pluralRu(count, 'трату', 'траты', 'трат')}',
                    icon: Icons.check,
                    loading: _saving,
                    onPressed: count == 0 ? null : _save,
                  ),
                  const SizedBox(height: 8),
                  OutlineAppButton(
                    label: 'Сказать заново',
                    icon: Icons.mic_none,
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(builder: (_) => const ListeningScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Белая карточка в виде чека со списком распознанных трат.
class _Receipt extends StatelessWidget {
  const _Receipt({
    required this.items,
    required this.onPickCategory,
    required this.onEditAmount,
    required this.onRemove,
  });

  final List<ParsedExpense> items;
  final ValueChanged<ParsedExpense> onPickCategory;
  final ValueChanged<ParsedExpense> onEditAmount;
  final ValueChanged<ParsedExpense> onRemove;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, e) => sum + e.amount);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(dayLabel(DateTime.now()), style: AppText.body(14, weight: FontWeight.w500)),
                ),
                Text(
                  'нашёл ${items.length} ${pluralRu(items.length, 'трату', 'траты', 'трат')}',
                  style: AppText.mono(12),
                ),
              ],
            ),
          ),
          for (final item in items)
            _ReceiptRow(
              item: item,
              onPickCategory: () => onPickCategory(item),
              onEditAmount: () => onEditAmount(item),
              onRemove: () => onRemove(item),
            ),
          const _TicketDivider(),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(child: Text('Итого', style: AppText.body(15, weight: FontWeight.w500))),
                Text(formatRub(total), style: AppText.display(24)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.item,
    required this.onPickCategory,
    required this.onEditAmount,
    required this.onRemove,
  });

  final ParsedExpense item;
  final VoidCallback onPickCategory;
  final VoidCallback onEditAmount;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final info = item.category.info;
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.track)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryTile(item.category, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppText.body(16, weight: FontWeight.w600)),
                if (item.source.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('из «${item.source}»', style: AppText.mono(12)),
                ],
                const SizedBox(height: 6),
                Material(
                  color: info.tint,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: onPickCategory,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(info.title, style: AppText.body(13, weight: FontWeight.w500)),
                          const SizedBox(width: 2),
                          const Icon(Icons.expand_more, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onEditAmount,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(formatRub(item.amount), style: AppText.display(19)),
                ),
              ),
              IconButton(
                tooltip: 'Убрать',
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Пунктир с полукруглыми вырезами по краям — как у отрывного чека.
class _TicketDivider extends StatelessWidget {
  const _TicketDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -27,
            top: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: AppColors.paper, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: -27,
            top: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: AppColors.paper, shape: BoxShape.circle),
            ),
          ),
          const Positioned(
            left: 8,
            right: 8,
            top: 10,
            child: SizedBox(height: 2, child: CustomPaint(painter: DashedLinePainter())),
          ),
        ],
      ),
    );
  }
}

/// Карточка с сообщением (ошибка или «ничего не нашёл»).
class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.title, required this.text, this.actionLabel, this.onAction});

  final String title;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.body(16, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(text, style: AppText.body(14, color: AppColors.muted, height: 1.4)),
          if (label != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(label)),
          ],
        ],
      ),
    );
  }
}
