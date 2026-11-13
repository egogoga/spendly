import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

/// Экран входа и регистрации.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _signup = false;
  bool _loading = false;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final api = SpendlyApi.instance;
      if (_signup) {
        await api.register(_name.text.trim(), _email.text.trim(), _password.text);
      } else {
        await api.login(_email.text.trim(), _password.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeShell()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не получилось войти: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.graphic_eq, color: AppColors.ink, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Text('Spendly', style: AppText.display(22, weight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 18),
              const _HowItWorksCard(),
              const SizedBox(height: 18),
              Text('Учёт трат голосом', style: AppText.display(24)),
              const SizedBox(height: 6),
              Text(
                'Просто скажите, сколько и на что потратили, — Spendly сам разнесёт всё по категориям.',
                style: AppText.body(15, color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 18),
              SegmentedTabs(
                labels: const ['Вход', 'Регистрация'],
                selected: _signup ? 1 : 0,
                onChanged: (i) => setState(() => _signup = i == 1),
              ),
              const SizedBox(height: 16),
              if (_signup) ...[
                _LabeledField(label: 'Имя', hint: 'Как к вам обращаться', controller: _name),
                const SizedBox(height: 12),
              ],
              _LabeledField(
                label: 'Электронная почта',
                hint: 'you@example.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Пароль',
                hint: 'Не меньше 8 символов',
                controller: _password,
                obscure: true,
              ),
              const SizedBox(height: 20),
              AccentButton(
                label: _signup ? 'Создать аккаунт' : 'Войти',
                onPressed: _submit,
                loading: _loading,
              ),
              if (!_signup)
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  child: Text(
                    'Забыли пароль?',
                    style: AppText.body(14, weight: FontWeight.w500, color: AppColors.link),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Ваши траты привязаны к аккаунту и видны только вам.',
                    textAlign: TextAlign.center,
                    style: AppText.body(12, color: AppColors.muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Тёмная карточка «как это работает»: фраза → запись о трате.
class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    final phraseStyle = AppText.body(16, weight: FontWeight.w500, color: Colors.white);
    return AppCard(
      color: AppColors.ink,
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: Color(0xFF2A2A26), shape: BoxShape.circle),
                child: const Icon(Icons.mic, size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: phraseStyle,
                    children: [
                      const TextSpan(text: '«Оставил '),
                      TextSpan(
                        text: 'пятихатку',
                        style: phraseStyle.copyWith(
                          color: AppColors.ink,
                          backgroundColor: AppColors.accent,
                        ),
                      ),
                      const TextSpan(text: ' на шаурму»'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Row(
              children: [
                const Icon(Icons.arrow_downward, size: 16, color: AppColors.onDarkFaint),
                const SizedBox(width: 6),
                Text('превращается в запись', style: AppText.mono(12, color: AppColors.onDarkFaint)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const CategoryTile(SpendCategory.food, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Шаурма', style: AppText.body(14, weight: FontWeight.w600)),
                      Text('Еда вне дома · сегодня', style: AppText.body(12, color: AppColors.muted)),
                    ],
                  ),
                ),
                Text(formatRub(500), style: AppText.display(16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Поле ввода с подписью сверху.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscure = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body(13, weight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: AppText.body(15),
          decoration: appInputDecoration(hint),
        ),
      ],
    );
  }
}
