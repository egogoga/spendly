import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/format.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Статистика за день / неделю / месяц.
/// Пока данные тестовые (MockData.stats); потом их будет отдавать сервер.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsPeriod _period = StatsPeriod.month;

  @override
  Widget build(BuildContext context) {
    final data = MockData.stats(_period);
    final top = data.shares.first;
    final donutLabel = 'Доли категорий: '
        '${data.shares.map((s) => '${s.category.info.title} ${s.percent}%').join(', ')}';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 56),
        children: [
          Row(
            children: [
              Expanded(child: Text('Статистика', style: AppText.display(24))),
              IconButton.filled(
                tooltip: 'Выбрать даты',
                onPressed: () {},
                icon: const Icon(Icons.calendar_today_outlined, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.ink,
                  fixedSize: const Size(44, 44),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedTabs(
            labels: const ['День', 'Неделя', 'Месяц'],
            selected: _period.index,
            onChanged: (i) => setState(() => _period = StatsPeriod.values[i]),
          ),
          const SizedBox(height: 18),
          Text(data.title, style: AppText.body(13, color: AppColors.muted)),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(formatRub(data.total), style: AppText.display(34)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.south_east, size: 14),
                    const SizedBox(width: 4),
                    Text(data.change, style: AppText.body(13, weight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                Semantics(
                  label: donutLabel,
                  child: SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(size: const Size(132, 132), painter: _DonutPainter(data.shares)),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${top.percent}%', style: AppText.display(20)),
                            SizedBox(
                              width: 76,
                              child: Text(
                                top.category.info.title,
                                textAlign: TextAlign.center,
                                style: AppText.body(11, color: AppColors.muted, height: 1.2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (final share in data.shares)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.5),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: share.category.info.color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  share.category.info.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(13),
                                ),
                              ),
                              Text(formatRub(share.amount), style: AppText.body(13, weight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _BarsCard(data: data),
        ],
      ),
    );
  }
}

/// Кольцевая диаграмма долей категорий.
class _DonutPainter extends CustomPainter {
  _DonutPainter(this.shares);

  final List<CategoryShare> shares;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 24.0;
    const gap = 0.035; // зазор между сегментами, в радианах
    final total = shares.fold<int>(0, (sum, s) => sum + s.percent);
    if (total == 0) return;

    final arcRect = (Offset.zero & size).deflate(stroke / 2);
    var start = -math.pi / 2;
    for (final share in shares) {
      final sweep = 2 * math.pi * share.percent / total;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = share.category.info.color;
      canvas.drawArc(arcRect, start + gap / 2, math.max(0.0, sweep - gap), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.shares != shares;
}

/// Тёмная карточка «Динамика» со столбиками.
class _BarsCard extends StatelessWidget {
  const _BarsCard({required this.data});

  final StatsData data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.bars.fold<int>(1, (m, b) => math.max(m, b.value));
    return AppCard(
      color: AppColors.ink,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Динамика', style: AppText.body(15, weight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(data.barsTitle, style: AppText.body(12, color: AppColors.onDarkFaint)),
                  ],
                ),
              ),
              Text(
                data.barsNote,
                textAlign: TextAlign.right,
                style: AppText.body(12, color: AppColors.onDarkFaint, height: 1.35),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < data.bars.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _Bar(
                      bar: data.bars[i],
                      maxValue: maxValue,
                      isLast: i == data.bars.length - 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.bar, required this.maxValue, required this.isLast});

  final ChartBar bar;
  final int maxValue;
  final bool isLast; // последний столбик — «сегодня», он подсвечен

  @override
  Widget build(BuildContext context) {
    final height = bar.value > 0 ? math.max(6.0, bar.value / maxValue * 92) : 3.0;
    final color = isLast
        ? AppColors.accent
        : (bar.value > 0 ? const Color(0xFF6E6C64) : AppColors.darkBorder);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isLast) ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatNumber(bar.value), style: AppText.mono(11, color: AppColors.accent)),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          height: height,
          constraints: const BoxConstraints(maxWidth: 26),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 6),
        Text(bar.label, maxLines: 1, style: AppText.body(11, color: AppColors.onDarkFaint)),
      ],
    );
  }
}
