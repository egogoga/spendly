import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Цвета из макета «Чек и лайм».
class AppColors {
  AppColors._();

  static const Color paper = Color(0xFFF3F1EA); // фон экранов
  static const Color ink = Color(0xFF141414); // основной текст и тёмные карточки
  static const Color accent = Color(0xFFD4F53C); // салатовый акцент
  static const Color surface = Color(0xFFFFFFFF); // белые карточки
  static const Color muted = Color(0xFF5E5B53); // второстепенный текст
  static const Color mutedStrong = Color(0xFF6B675E); // неактивные пункты меню, подсказки в полях
  static const Color line = Color(0xFFE2DED3); // рамки полей
  static const Color divider = Color(0xFFECE9E1); // разделители в списках
  static const Color track = Color(0xFFEEEBE3); // фон полосок прогресса
  static const Color link = Color(0xFF2F55E4); // ссылки
  static const Color onDarkMuted = Color(0xFFB9B6AC); // подписи на тёмном фоне
  static const Color onDarkFaint = Color(0xFFA8A59B);
  static const Color darkSurface = Color(0xFF262622); // кнопки на тёмном экране
  static const Color darkTrack = Color(0xFF34332F);
  static const Color darkBorder = Color(0xFF3A3934);
  static const Color warning = Color(0xFF8A4210);
}

/// Безопасная загрузка шрифта из Google Fonts:
/// если шрифт не нашёлся, остаётся системный.
TextStyle _googleFont(String family, TextStyle base) {
  try {
    return GoogleFonts.getFont(family, textStyle: base);
  } catch (_) {
    return base;
  }
}

/// Стили текста. Пример: Text('Привет', style: AppText.body(15)).
class AppText {
  AppText._();

  /// Unbounded — крупные суммы и заголовки.
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.ink,
  }) {
    return _googleFont(
      'Unbounded',
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: -0.02 * size,
        height: 1.15,
      ),
    );
  }

  /// Onest — весь остальной интерфейс.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
  }) {
    return _googleFont(
      'Onest',
      TextStyle(fontSize: size, fontWeight: weight, color: color, height: height),
    );
  }

  /// JetBrains Mono — распознанные слова из фразы («пятихатку»).
  static TextStyle mono(double size, {Color color = AppColors.muted}) {
    return _googleFont('JetBrains Mono', TextStyle(fontSize: size, color: color));
  }
}

ThemeData buildSpendlyTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.ink,
    onPrimary: Colors.white,
    secondary: AppColors.accent,
    onSecondary: AppColors.ink,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.paper,
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
    ),
  );
}
