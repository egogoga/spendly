import 'package:flutter/foundation.dart';

import 'format.dart';
import 'mock_data.dart';
import 'models.dart';

/// Хранилище трат в памяти приложения.
/// Экраны подписываются на него (ListenableBuilder) и обновляются,
/// когда пользователь сохраняет новые траты.
///
/// Сейчас данные тестовые и пропадают после перезапуска.
/// Когда появится сервер, сюда добавится загрузка трат через SpendlyApi.
class ExpenseStore extends ChangeNotifier {
  ExpenseStore._() {
    _sort();
  }

  static final ExpenseStore instance = ExpenseStore._();

  final List<Expense> _items = MockData.expenses();

  /// Все траты, новые сверху.
  List<Expense> get items => List.unmodifiable(_items);

  void addAll(Iterable<Expense> expenses) {
    _items.addAll(expenses);
    _sort();
    notifyListeners();
  }

  void _sort() => _items.sort((a, b) => b.date.compareTo(a.date));

  int get todayTotal {
    final now = DateTime.now();
    return _items
        .where((e) => isSameDay(e.date, now))
        .fold<int>(0, (sum, e) => sum + e.amount);
  }

  int get _allTotal => _items.fold<int>(0, (sum, e) => sum + e.amount);

  int get weekTotal => MockData.weekBefore + _allTotal;

  int get monthTotal => MockData.monthBefore + _allTotal;

  int get monthLimit => MockData.monthLimit;
}
