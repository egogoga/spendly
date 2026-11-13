import 'package:flutter/material.dart';

import '../data/expense_store.dart';
import '../data/format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'parsed_screen.dart';

/// Главный экран: сводка, ввод текстом и последние траты.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenHistory});

  final VoidCallback onOpenHistory;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _examples = ['косарь на продукты', 'метро 70', 'полтос на чай'];

  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _input.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Напишите, на что потратили, например: «такси 430»')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => ParsedScreen(phrase: text)))
        .then((_) => _input.clear());
  }

  @override
  Widget build(BuildContext context) {
    final store = ExpenseStore.instance;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final recent = store.items.take(3).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 56),
            children: [
              _Header(),
              const SizedBox(height: 14),
              _SummaryCard(
                today: store.todayTotal,
                week: store.weekTotal,
                month: store.monthTotal,
                limit: store.monthLimit,
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Что купили? Напишите или скажите',
                      style: AppText.body(15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            style: AppText.body(15),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            decoration: appInputDecoration(
                              'Например: такси 430 и кофе 200',
                              fill: AppColors.paper,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Разобрать фразу',
                          onPressed: _submit,
                          icon: const Icon(Icons.arrow_forward),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            foregroundColor: AppColors.accent,
                            fixedSize: const Size(48, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final example in _examples)
                          ActionChip(
                            label: Text('«$example»'),
                            labelStyle: AppText.body(13),
                            backgroundColor: AppColors.paper,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                            onPressed: () {
                              _input.text = example;
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text('Последние траты', style: AppText.body(17, weight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: widget.onOpenHistory,
                    child: Text(
                      'Все траты',
                      style: AppText.body(14, weight: FontWeight.w500, color: AppColors.link),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (recent.isEmpty)
                Text('Пока пусто — скажите первую трату', style: AppText.body(14, color: AppColors.muted))
              else
                RowsCard(children: [for (final e in recent) ExpenseRow(expense: e)]),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatWeekdayDate(DateTime.now()), style: AppText.body(13, color: AppColors.muted)),
              const SizedBox(height: 2),
              Text(greeting(), style: AppText.display(22)),
            ],
          ),
        ),
        IconButton.filled(
          tooltip: 'Профиль',
          onPressed: () {},
          icon: const Icon(Icons.person_outline),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.accent,
            fixedSize: const Size(44, 44),
          ),
        ),
      ],
    );
  }
}

/// Тёмная карточка: сколько потрачено сегодня, за неделю, за месяц и лимит.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.today,
    required this.week,
    required this.month,
    required this.limit,
  });

  final int today;
  final int week;
  final int month;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final share = limit == 0 ? 0.0 : (month / limit).clamp(0.0, 1.0).toDouble();
    return AppCard(
      color: AppColors.ink,
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Потрачено сегодня', style: AppText.body(13, color: AppColors.onDarkMuted)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${formatNumber(today)} ', style: AppText.display(40, color: Colors.white)),
                  TextSpan(text: '₽', style: AppText.display(40, color: AppColors.accent)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'За неделю', value: formatRub(week))),
              Expanded(child: _MiniStat(label: 'За месяц', value: formatRub(month))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Лимит на месяц · ${(share * 100).round()}%',
                  style: AppText.body(12, color: AppColors.onDarkMuted),
                ),
              ),
              Text(
                '${formatNumber(month)} из ${formatRub(limit)}',
                style: AppText.body(12, color: AppColors.onDarkMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(value: share, color: AppColors.accent, track: AppColors.darkTrack),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body(12, color: AppColors.onDarkMuted)),
        const SizedBox(height: 2),
        Text(value, style: AppText.body(16, weight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}
