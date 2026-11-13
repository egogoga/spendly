import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/format.dart';
import '../data/models.dart';
import '../theme.dart';

/// Белая (или любая другая) карточка со скруглёнными углами.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
      child: child,
    );
  }
}

/// Квадратик с иконкой категории.
class CategoryTile extends StatelessWidget {
  const CategoryTile(this.category, {super.key, this.size = 40});

  final SpendCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final info = category.info;
    return IconTile(icon: info.icon, tint: info.tint, size: size);
  }
}

/// Квадратик с любой иконкой (для целей и т. п.).
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.tint, this.size = 40});

  final IconData icon;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, size: size * 0.5, color: AppColors.ink),
    );
  }
}

/// Полоска прогресса (лимиты, цели).
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.track = AppColors.track,
    this.height = 8,
  });

  final double value; // от 0 до 1
  final Color color;
  final Color track;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(color: track, borderRadius: radius),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0).toDouble(),
            heightFactor: 1,
            child: DecoratedBox(decoration: BoxDecoration(color: color, borderRadius: radius)),
          ),
        ),
      ),
    );
  }
}

/// Строка траты в списке: иконка, название, категория и время, сумма.
class ExpenseRow extends StatelessWidget {
  const ExpenseRow({super.key, required this.expense, this.showPhrase = false});

  final Expense expense;
  final bool showPhrase;

  @override
  Widget build(BuildContext context) {
    final info = expense.category.info;
    final phrase = expense.phrase;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryTile(expense.category),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.title, style: AppText.body(15, weight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '${info.title} · ${formatTime(expense.date)}',
                  style: AppText.body(13, color: AppColors.muted),
                ),
                if (showPhrase && phrase != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.mic_none, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          phrase,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.mono(11.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(formatRub(expense.amount), style: AppText.body(15, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Белая карточка-список с тонкими разделителями между строками.
class RowsCard extends StatelessWidget {
  const RowsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: ColoredBox(
        color: AppColors.divider,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 1),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Переключатель «День / Неделя / Месяц» и «Вход / Регистрация».
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Material(
                color: i == selected ? AppColors.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onChanged(i),
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        labels[i],
                        style: AppText.body(
                          14,
                          weight: FontWeight.w600,
                          color: i == selected ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Главная кнопка — салатовая, во всю ширину.
class AccentButton extends StatelessWidget {
  const AccentButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: loading ? () {} : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: const Color(0xFFE6E3DA),
          disabledForegroundColor: AppColors.muted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: AppText.body(16, weight: FontWeight.w600),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.ink),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconData != null) ...[
                    Icon(iconData, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}

/// Второстепенная кнопка — с чёрной обводкой.
class OutlineAppButton extends StatelessWidget {
  const OutlineAppButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: AppText.body(15, weight: FontWeight.w600),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconData != null) ...[
              Icon(iconData, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

/// Оформление полей ввода по макету.
InputDecoration appInputDecoration(
  String hint, {
  Color fill = AppColors.surface,
  Widget? prefixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: AppText.body(15, color: AppColors.mutedStrong),
    filled: true,
    fillColor: fill,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    prefixIcon: prefixIcon,
    border: border(AppColors.line),
    enabledBorder: border(AppColors.line),
    focusedBorder: border(AppColors.ink, 1.5),
  );
}

/// Пунктирная линия (разделитель в «чеке»).
class DashedLinePainter extends CustomPainter {
  const DashedLinePainter({this.color = AppColors.line});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    const dash = 6.0;
    const gap = 5.0;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + dash, size.width), y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) => oldDelegate.color != color;
}

/// Нижнее меню. В середине оставлено место под кнопку микрофона
/// (сама кнопка — MicButton, её показывает Scaffold).
class SpendlyNavBar extends StatelessWidget {
  const SpendlyNavBar({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Главная',
                  active: index == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'История',
                  active: index == 1,
                  onTap: () => onTap(1),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('Сказать', style: AppText.body(11, weight: FontWeight.w600)),
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.insert_chart_outlined,
                  activeIcon: Icons.insert_chart,
                  label: 'Статистика',
                  active: index == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.track_changes,
                  activeIcon: Icons.track_changes,
                  label: 'Цели',
                  active: index == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.ink : AppColors.mutedStrong;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 30,
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(active ? activeIcon : icon, size: 22, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                style: AppText.body(
                  11,
                  weight: active ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Круглая чёрная кнопка микрофона в центре нижнего меню.
class MicButton extends StatelessWidget {
  const MicButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Сказать трату',
      child: Material(
        color: AppColors.ink,
        shape: const CircleBorder(side: BorderSide(color: AppColors.paper, width: 5)),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          child: const SizedBox(
            width: 66,
            height: 66,
            child: Icon(Icons.mic, color: AppColors.accent, size: 28),
          ),
        ),
      ),
    );
  }
}
