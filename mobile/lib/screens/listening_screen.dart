import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/format.dart';
import '../data/models.dart';
import '../data/phrase_parser.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'parsed_screen.dart';

/// Экран голосового ввода: слушает микрофон и показывает текст по ходу речи.
///
/// Распознавание делает сам телефон (Android / iOS) или браузер (Chrome, Edge)
/// через пакет speech_to_text. Если распознавание недоступно,
/// подставляется пример фразы, чтобы можно было пройти весь сценарий.
class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> with SingleTickerProviderStateMixin {
  static const String _demoPhrase = 'Оставил пятихатку на шаурму и сотку с полтосом на кофе';

  final SpeechToText _speech = SpeechToText();
  late final AnimationController _wave;

  String _committed = ''; // текст из прошлых «сессий» (до паузы)
  String _live = ''; // текст текущей сессии
  bool _available = false;
  bool _listening = false;
  bool _starting = true;
  String? _notice;
  double _level = 0.5; // громкость голоса от 0 до 1 — для анимации волны

  String get _text => [_committed, _live].where((s) => s.isNotEmpty).join(' ');

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();
    _init();
  }

  @override
  void dispose() {
    _wave.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    var ok = false;
    try {
      ok = await _speech.initialize(
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _listening = false;
            _notice = 'Не расслышал (${error.errorMsg}). Нажмите «Дальше», чтобы попробовать ещё раз.';
          });
        },
        onStatus: (status) {
          if (!mounted) return;
          setState(() => _listening = _speech.isListening);
        },
      );
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _available = ok;
      _starting = false;
      if (!ok) {
        _notice = 'Распознавание речи недоступно на этом устройстве — подставил пример фразы. '
            'Его можно поправить кнопкой «Текстом».';
        _committed = _demoPhrase;
      }
    });
    if (ok) await _start();
  }

  Future<void> _start() async {
    setState(() {
      _notice = null;
      _live = '';
    });
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _live = result.recognizedWords);
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() => _level = ((level + 2) / 12).clamp(0.0, 1.0).toDouble());
      },
      listenOptions: SpeechListenOptions(
        localeId: 'ru_RU',
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 6),
      ),
    );
    if (!mounted) return;
    setState(() => _listening = true);
  }

  Future<void> _togglePause() async {
    if (_listening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _listening = false);
    } else {
      setState(() {
        _committed = _text;
        _live = '';
      });
      await _start();
    }
  }

  Future<void> _done() async {
    if (_available && _speech.isListening) {
      await _speech.stop();
      // Даём телефону долю секунды, чтобы прислать окончательный текст.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;
    final text = _text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Я ничего не услышал. Скажите, например: «метро 70»')),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => ParsedScreen(phrase: text)),
    );
  }

  Future<void> _editAsText() async {
    if (_available && _speech.isListening) await _speech.stop();
    if (!mounted) return;
    setState(() => _listening = false);
    final controller = TextEditingController(text: _text);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Напишите или исправьте фразу', style: AppText.body(17, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 1,
              maxLines: 3,
              style: AppText.body(16),
              decoration: appInputDecoration('Например: такси 430 и кофе 200', fill: AppColors.paper),
            ),
            const SizedBox(height: 12),
            AccentButton(
              label: 'Разобрать',
              onPressed: () => Navigator.of(sheetContext).pop(controller.text.trim()),
            ),
          ],
        ),
      ),
    );
    if (!mounted || result == null || result.isEmpty) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => ParsedScreen(phrase: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    final segments = PhraseParser.segments(text);
    final recognized = PhraseParser.parse(text);
    final transcriptStyle = AppText.body(29, weight: FontWeight.w500, color: Colors.white, height: 1.34);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton.filled(
                      tooltip: 'Закрыть',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.darkSurface,
                        foregroundColor: Colors.white,
                        fixedSize: const Size(44, 44),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Голосовой ввод',
                        textAlign: TextAlign.center,
                        style: AppText.body(15, weight: FontWeight.w600, color: const Color(0xFFE8E6DF)),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _listening ? AppColors.accent : const Color(0xFF6E6C64),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _starting ? 'Включаю микрофон…' : (_listening ? 'Слушаю' : 'Пауза'),
                            style: AppText.body(
                              15,
                              weight: FontWeight.w600,
                              color: _listening ? AppColors.accent : const Color(0xFFE8E6DF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (text.isEmpty)
                        Text(
                          'Говорите, например: «оставил пятихатку на шаурму»',
                          style: transcriptStyle.copyWith(color: const Color(0xFF6E6C64), fontSize: 24),
                        )
                      else
                        Text.rich(
                          TextSpan(
                            children: [
                              for (final s in segments)
                                TextSpan(
                                  text: s.text,
                                  style: s.isAmount
                                      ? transcriptStyle.copyWith(
                                          color: AppColors.ink,
                                          backgroundColor: AppColors.accent,
                                        )
                                      : transcriptStyle,
                                ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: AnimatedBuilder(
                                  animation: _wave,
                                  builder: (context, _) => Opacity(
                                    opacity: _listening && _wave.value < 0.5 ? 1.0 : 0.0,
                                    child: Container(
                                      width: 3,
                                      height: 28,
                                      margin: const EdgeInsets.only(left: 4),
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_notice != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _notice!,
                          style: AppText.body(13, color: AppColors.onDarkFaint, height: 1.4),
                        ),
                      ],
                      if (recognized.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Уже понял', style: AppText.body(13, color: AppColors.onDarkFaint)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [for (final item in recognized) _RecognizedChip(item: item)],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 110,
                child: AnimatedBuilder(
                  animation: _wave,
                  builder: (context, _) => CustomPaint(
                    painter: _WavePainter(
                      t: _wave.value,
                      level: _level,
                      active: _listening,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ControlButton(
                      icon: _listening ? Icons.pause : Icons.mic,
                      label: _listening ? 'Пауза' : 'Дальше',
                      onPressed: _available ? _togglePause : null,
                    ),
                    _DoneButton(onPressed: _done),
                    _ControlButton(icon: Icons.keyboard, label: 'Текстом', onPressed: _editAsText),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
                child: Text(
                  'Говорите как обычно: «косарь», «пятихатка», «полтос» — я пойму.',
                  textAlign: TextAlign.center,
                  style: AppText.body(13, color: AppColors.onDarkFaint, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Плашка «Шаурма · 500 ₽» в блоке «Уже понял».
class _RecognizedChip extends StatelessWidget {
  const _RecognizedChip({required this.item});

  final ParsedExpense item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CategoryTile(item.category, size: 28),
          const SizedBox(width: 8),
          Text(item.title, style: AppText.body(14, color: Colors.white)),
          const SizedBox(width: 8),
          Text(formatRub(item.amount), style: AppText.mono(13, color: AppColors.accent)),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: AppColors.darkSurface,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                icon,
                size: 24,
                color: enabled ? Colors.white : const Color(0xFF6E6C64),
                semanticLabel: label,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppText.body(12, color: AppColors.onDarkFaint)),
      ],
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: const BoxDecoration(color: AppColors.darkSurface, shape: BoxShape.circle),
          child: Material(
            color: AppColors.accent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: const SizedBox(
                width: 80,
                height: 80,
                child: Icon(Icons.check, size: 34, color: AppColors.ink, semanticLabel: 'Готово'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Готово', style: AppText.body(13, weight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}

/// Рисует «звуковую волну» из 36 столбиков.
class _WavePainter extends CustomPainter {
  _WavePainter({required this.t, required this.level, required this.active, required this.color});

  final double t; // фаза анимации 0…1
  final double level; // громкость 0…1
  final bool active;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const count = 36;
    const barWidth = 4.0;
    const gap = 4.0;
    const totalWidth = count * barWidth + (count - 1) * gap;
    final startX = (size.width - totalWidth) / 2;
    final centerY = size.height / 2;

    for (var i = 0; i < count; i++) {
      final shape = (math.sin(i * 0.62) * math.cos(i * 0.21)).abs() * 0.85 + 0.15;
      final edge = math.min(1.0, math.min(i + 1, count - i) / 7);
      final pulse = active ? 0.45 + 0.55 * (0.5 + 0.5 * math.sin(2 * math.pi * t + i * 0.7)) : 0.25;
      final loudness = active ? 0.55 + 0.45 * level : 1.0;
      final height = math.max(4.0, (10 + 78 * shape * edge) * pulse * loudness);
      final paint = Paint()..color = color.withAlpha(((0.45 + 0.55 * edge) * 255).round());
      final x = startX + i * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, centerY - height / 2, barWidth, height),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.level != level ||
      oldDelegate.active != active ||
      oldDelegate.color != color;
}
