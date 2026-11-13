import 'package:flutter/material.dart';

import '../data/expense_store.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// История трат: поиск, фильтр по категориям, группировка по дням.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  SpendCategory? _filter; // null — показать все
  String _query = '';

  bool _matches(Expense e) {
    final filter = _filter;
    if (filter != null && e.category != filter) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return e.title.toLowerCase().contains(q) ||
        (e.phrase ?? '').toLowerCase().contains(q) ||
        e.category.info.title.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final store = ExpenseStore.instance;
    final now = DateTime.now();
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final groups = _groupByDay(store.items.where(_matches).toList());
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 56),
            children: [
              Row(
                children: [
                  Expanded(child: Text('История', style: AppText.display(24))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      '${monthNominative(now)} ${now.year}',
                      style: AppText.body(14, weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                style: AppText.body(15),
                decoration: appInputDecoration(
                  'Шаурма, такси, «косарь»…',
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'Все',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final category in SpendCategory.values)
                      _FilterChip(
                        label: category.info.title,
                        selected: _filter == category,
                        onTap: () => setState(() => _filter = category),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (groups.isEmpty)
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Column(
                    children: [
                      Text('Здесь пока пусто', style: AppText.body(15, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        'Скажите, например: «полтос на автобус»',
                        textAlign: TextAlign.center,
                        style: AppText.body(13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              for (final group in groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(dayLabel(group.day), style: AppText.body(15, weight: FontWeight.w600)),
                      ),
                      Text(
                        formatRub(group.total),
                        style: AppText.body(14, weight: FontWeight.w500, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                RowsCard(
                  children: [for (final e in group.items) ExpenseRow(expense: e, showPhrase: true)],
                ),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DayGroup {
  _DayGroup(this.day);

  final DateTime day;
  final List<Expense> items = [];

  int get total => items.fold<int>(0, (sum, e) => sum + e.amount);
}

/// Траты уже отсортированы (новые сверху), поэтому достаточно
/// начинать новую группу, когда меняется день.
List<_DayGroup> _groupByDay(List<Expense> items) {
  final groups = <_DayGroup>[];
  for (final e in items) {
    if (groups.isEmpty || !isSameDay(groups.last.day, e.date)) {
      groups.add(_DayGroup(e.date));
    }
    groups.last.items.add(e);
  }
  return groups;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.ink : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                label,
                style: AppText.body(
                  14,
                  weight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
