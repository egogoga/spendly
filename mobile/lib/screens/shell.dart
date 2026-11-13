import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'goals_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'listening_screen.dart';
import 'stats_screen.dart';

/// Каркас после входа: четыре вкладки, нижнее меню и кнопка микрофона.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _openVoice() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ListeningScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack держит все вкладки в памяти, поэтому
      // при переключении не теряется прокрутка и введённый текст.
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenHistory: () => setState(() => _index = 1)),
          const HistoryScreen(),
          const StatsScreen(),
          const GoalsScreen(),
        ],
      ),
      floatingActionButton: MicButton(onPressed: _openVoice),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SpendlyNavBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
