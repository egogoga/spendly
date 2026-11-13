import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'theme.dart';

/// Точка входа: отсюда Flutter запускает приложение.
void main() {
  runApp(const SpendlyApp());
}

class SpendlyApp extends StatelessWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      theme: buildSpendlyTheme(),
      // В браузере на широком экране показываем приложение «телефонной» ширины.
      // На телефоне ширина экрана меньше 460 точек, поэтому там это ни на что не влияет.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFE4E1D8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: child,
          ),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}
