import 'package:flutter/material.dart';

import 'format.dart';
import 'models.dart';

/// Тестовые данные для заготовки. Когда появится сервер,
/// всё это будет приходить из API (см. data/api.dart).
class MockData {
  MockData._();

  /// Сколько потрачено за неделю и за месяц ДО последних двух дней.
  /// Подробных трат за те дни в демо нет, поэтому берём готовые суммы.
  static const int weekBefore = 13510;
  static const int monthBefore = 19620;
  static const int monthLimit = 60000;

  static DateTime _at(int daysAgo, int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - daysAgo, hour, minute);
  }

  /// Траты за сегодня и вчера.
  static List<Expense> expenses() => [
        Expense(id: 't1', title: 'Подписка на музыку', category: SpendCategory.subs, amount: 299, date: _at(0, 21, 12)),
        Expense(id: 't2', title: 'Продукты к ужину', category: SpendCategory.groceries, amount: 751, date: _at(0, 19, 5)),
        Expense(id: 't3', title: 'Метро', category: SpendCategory.transport, amount: 70, date: _at(0, 18, 40), phrase: '«метро семьдесят»'),
        Expense(id: 't4', title: 'Шаурма', category: SpendCategory.food, amount: 500, date: _at(0, 13, 20), phrase: '«пятихатку на шаурму»'),
        Expense(id: 't5', title: 'Кофе', category: SpendCategory.cafe, amount: 150, date: _at(0, 13, 20), phrase: '«сотку с полтосом на кофе»'),
        Expense(id: 't6', title: 'Метро', category: SpendCategory.transport, amount: 70, date: _at(0, 8, 25)),
        Expense(id: 'y1', title: 'Такси', category: SpendCategory.transport, amount: 430, date: _at(1, 23, 40), phrase: '«такси четыреста тридцать»'),
        Expense(id: 'y2', title: 'Продукты', category: SpendCategory.groceries, amount: 1120, date: _at(1, 20, 10), phrase: '«косарь сто двадцать на продукты»'),
        Expense(id: 'y3', title: 'Аптека', category: SpendCategory.other, amount: 180, date: _at(1, 18, 30)),
        Expense(id: 'y4', title: 'Кофе', category: SpendCategory.cafe, amount: 220, date: _at(1, 9, 15)),
      ];

  static const List<Goal> goals = [
    Goal(
      title: 'Ноутбук для учёбы',
      icon: Icons.laptop_mac,
      tint: Color(0xFFDCE4FF),
      saved: 48000,
      target: 90000,
      deadline: 'к марту',
    ),
    Goal(
      title: 'Поездка летом',
      icon: Icons.beach_access,
      tint: Color(0xFFFDE2CC),
      saved: 12500,
      target: 60000,
      deadline: 'к июлю',
    ),
    Goal(
      title: 'Подушка безопасности',
      icon: Icons.savings,
      tint: Color(0xFFECF7BF),
      saved: 30000,
      target: 100000,
      deadline: 'без срока',
    ),
  ];

  static const List<CategoryLimit> limits = [
    CategoryLimit(category: SpendCategory.cafe, spent: 2860, limit: 4000),
  ];

  /// Статистика за период. Сервер будет отдавать её по запросу GET /stats?period=…
  static StatsData stats(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.day:
        return const StatsData(
          title: 'Сегодня',
          total: 1840,
          change: '6% ко вчера',
          shares: [
            CategoryShare(SpendCategory.groceries, 751, 41),
            CategoryShare(SpendCategory.food, 500, 27),
            CategoryShare(SpendCategory.subs, 299, 16),
            CategoryShare(SpendCategory.cafe, 150, 8),
            CategoryShare(SpendCategory.transport, 140, 8),
          ],
          barsTitle: 'По времени суток',
          barsNote: '6 трат',
          bars: [
            ChartBar('6–9', 70),
            ChartBar('9–12', 0),
            ChartBar('12–15', 650),
            ChartBar('15–18', 0),
            ChartBar('18–21', 821),
            ChartBar('21–24', 299),
          ],
        );
      case StatsPeriod.week:
        const values = [1260, 2140, 3480, 4920, 1710, 1950, 1840];
        return StatsData(
          title: 'Последние 7 дней',
          total: 17300,
          change: '4% к прошлой неделе',
          shares: const [
            CategoryShare(SpendCategory.groceries, 5980, 35),
            CategoryShare(SpendCategory.food, 4120, 24),
            CategoryShare(SpendCategory.transport, 2210, 13),
            CategoryShare(SpendCategory.cafe, 2150, 12),
            CategoryShare(SpendCategory.other, 1642, 9),
            CategoryShare(SpendCategory.subs, 1198, 7),
          ],
          barsTitle: 'По дням',
          barsNote: 'в среднем\n2 471 ₽ в день',
          bars: [
            for (var i = 0; i < 7; i++)
              ChartBar(weekdaysShort[_at(6 - i, 12, 0).weekday - 1], values[i]),
          ],
        );
      case StatsPeriod.month:
        return const StatsData(
          title: 'С начала месяца',
          total: 23410,
          change: '8% к прошлому месяцу',
          shares: [
            CategoryShare(SpendCategory.groceries, 8240, 35),
            CategoryShare(SpendCategory.food, 5310, 23),
            CategoryShare(SpendCategory.transport, 3120, 13),
            CategoryShare(SpendCategory.cafe, 2860, 12),
            CategoryShare(SpendCategory.other, 2383, 10),
            CategoryShare(SpendCategory.subs, 1497, 7),
          ],
          barsTitle: 'По дням месяца',
          barsNote: 'в среднем\n2 341 ₽ в день',
          bars: [
            ChartBar('1', 2380),
            ChartBar('2', 1590),
            ChartBar('3', 2140),
            ChartBar('4', 1260),
            ChartBar('5', 2140),
            ChartBar('6', 3480),
            ChartBar('7', 4920),
            ChartBar('8', 1710),
            ChartBar('9', 1950),
            ChartBar('10', 1840),
          ],
        );
    }
  }
}
