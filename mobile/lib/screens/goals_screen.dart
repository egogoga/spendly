import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/expense_store.dart';
import '../data/format.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Цели: лимит на месяц, лимиты по категориям и накопления.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ExpenseStore.instance;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final now = DateTime.now();
          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
          final monthProgress = now.day / daysInMonth;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 56),
            children: [
              Row(
                children: [
                  Expanded(child: Text('Цели', style: AppText.display(24))),
                  FilledButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Создание целей появится в следующей версии')),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Новая цель'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                      textStyle: AppText.body(14, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _MonthLimitCard(
                spent: store.monthTotal,
                limit: store.monthLimit,
                daysLeft: math.max(1, daysInMonth - now.day),
              ),
              const SizedBox(height: 14),
              for (final limit in MockData.limits) ...[
                _CategoryLimitCard(limit: limit, monthProgress: monthProgress),
                const SizedBox(height: 14),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Text('Копим', style: AppText.body(17, weight: FontWeight.w600)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                child: Text(
                  'пополняйте голосом: «отложил пять косарей на ноутбук»',
                  style: AppText.mono(11.5),
                ),
              ),
              for (final goal in MockData.goals) ...[
                _GoalCard(goal: goal),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MonthLimitCard extends StatelessWidget {
  const _MonthLimitCard({required this.spent, required this.limit, required this.daysLeft});

  final int spent;
  final int limit;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final left = math.max(0, limit - spent);
    final perDay = (left / daysLeft).round();
    final share = limit == 0 ? 0.0 : spent / limit;
    return AppCard(
      color: AppColors.ink,
      radius: 26,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Лимит на месяц', style: AppText.body(13, color: AppColors.onDarkMuted)),
              ),
              Text(
                'ещё $daysLeft ${pluralRu(daysLeft, 'день', 'дня', 'дней')}',
                style: AppText.body(13, color: AppColors.onDarkMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: [
              Text(formatRub(spent), style: AppText.display(30, color: Colors.white)),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('из ${formatRub(limit)}', style: AppText.body(15, color: AppColors.onDarkMuted)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(value: share, color: AppColors.accent, track: AppColors.darkTrack, height: 10),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: AppText.body(13, color: const Color(0xFFE8E6DF), height: 1.4),
              children: [
                TextSpan(text: 'Осталось ${formatRub(left)} — это примерно '),
                TextSpan(
                  text: '${formatRub(perDay)} в день',
                  style: AppText.body(13, weight: FontWeight.w600, color: AppColors.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLimitCard extends StatelessWidget {
  const _CategoryLimitCard({required this.limit, required this.monthProgress});

  final CategoryLimit limit;
  final double monthProgress;

  @override
  Widget build(BuildContext context) {
    final info = limit.category.info;
    final percent = (limit.progress * 100).round();
    final monthPercent = (monthProgress * 100).round();
    final ahead = limit.progress > monthProgress + 0.1;
    return AppCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryTile(limit.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.title, style: AppText.body(15, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${formatNumber(limit.spent)} из ${formatRub(limit.limit)} в месяц',
                      style: AppText.body(12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Text('$percent%', style: AppText.display(16)),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(value: limit.progress, color: info.color),
          if (ahead) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Месяц прошёл на $monthPercent%, а лимит потрачен на $percent%',
                    style: AppText.body(13, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              IconTile(icon: goal.icon, tint: goal.tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: AppText.body(15, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${formatNumber(goal.saved)} из ${formatRub(goal.target)} · ${goal.deadline}',
                      style: AppText.body(12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Text('${(goal.progress * 100).round()}%', style: AppText.display(16)),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(value: goal.progress, color: AppColors.ink),
        ],
      ),
    );
  }
}
