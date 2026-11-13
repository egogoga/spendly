import 'package:flutter/material.dart';

/// Категории трат. Коды (name: groceries, food, …) совпадают с тем,
/// что приложение отправляет на сервер и получает от него.
enum SpendCategory { groceries, food, transport, cafe, subs, other }

/// Как категория выглядит в интерфейсе.
class CategoryInfo {
  const CategoryInfo({
    required this.title,
    required this.color,
    required this.tint,
    required this.icon,
  });

  final String title;
  final Color color; // цвет в графиках
  final Color tint; // светлый фон плашки с иконкой
  final IconData icon;
}

extension SpendCategoryInfo on SpendCategory {
  CategoryInfo get info {
    switch (this) {
      case SpendCategory.groceries:
        return const CategoryInfo(
          title: 'Продукты',
          color: Color(0xFF2F55E4),
          tint: Color(0xFFDCE4FF),
          icon: Icons.shopping_bag_outlined,
        );
      case SpendCategory.food:
        return const CategoryInfo(
          title: 'Еда вне дома',
          color: Color(0xFFC3E62B),
          tint: Color(0xFFECF7BF),
          icon: Icons.restaurant_outlined,
        );
      case SpendCategory.transport:
        return const CategoryInfo(
          title: 'Транспорт',
          color: Color(0xFF141414),
          tint: Color(0xFFE0DDD3),
          icon: Icons.directions_bus_outlined,
        );
      case SpendCategory.cafe:
        return const CategoryInfo(
          title: 'Кафе и кофе',
          color: Color(0xFFF08A3C),
          tint: Color(0xFFFDE2CC),
          icon: Icons.local_cafe_outlined,
        );
      case SpendCategory.subs:
        return const CategoryInfo(
          title: 'Подписки',
          color: Color(0xFFA48BF0),
          tint: Color(0xFFE9E2FD),
          icon: Icons.autorenew,
        );
      case SpendCategory.other:
        return const CategoryInfo(
          title: 'Другое',
          color: Color(0xFFCFC9BA),
          tint: Color(0xFFEFECE4),
          icon: Icons.local_offer_outlined,
        );
    }
  }
}

/// Превращает код категории с сервера ('food') в значение SpendCategory.
SpendCategory categoryFromCode(String? code) {
  for (final category in SpendCategory.values) {
    if (category.name == code) return category;
  }
  return SpendCategory.other;
}

/// Сохранённая трата.
class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.phrase,
  });

  final String id;
  final String title;
  final SpendCategory category;
  final int amount; // в рублях
  final DateTime date;
  final String? phrase; // фраза, из которой трата распознана (если вводили голосом)

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category.name,
        'amount': amount,
        'date': date.toIso8601String(),
        if (phrase != null) 'phrase': phrase,
      };
}

/// Трата, которую распознали во фразе, но ещё не сохранили.
/// Пользователь может поправить категорию и сумму перед сохранением.
class ParsedExpense {
  ParsedExpense({
    required this.title,
    required this.category,
    required this.amount,
    required this.source,
    required this.phrase,
  });

  String title;
  SpendCategory category;
  int amount;
  final String source; // слова, из которых взята сумма: «сотку с полтосом»
  final String phrase; // кусок фразы про эту трату: «сотку с полтосом на кофе»

  factory ParsedExpense.fromJson(Map<String, dynamic> json) {
    return ParsedExpense(
      title: json['title'] as String? ?? 'Покупка',
      category: categoryFromCode(json['category'] as String?),
      amount: (json['amount'] as num?)?.round() ?? 0,
      source: json['source'] as String? ?? '',
      phrase: json['phrase'] as String? ?? '',
    );
  }
}

/// Цель накопления.
class Goal {
  const Goal({
    required this.title,
    required this.icon,
    required this.tint,
    required this.saved,
    required this.target,
    required this.deadline,
  });

  final String title;
  final IconData icon;
  final Color tint;
  final int saved;
  final int target;
  final String deadline;

  double get progress => target == 0 ? 0 : saved / target;
}

/// Лимит трат на категорию в месяц.
class CategoryLimit {
  const CategoryLimit({required this.category, required this.spent, required this.limit});

  final SpendCategory category;
  final int spent;
  final int limit;

  double get progress => limit == 0 ? 0 : spent / limit;
}

/// Доля категории в статистике.
class CategoryShare {
  const CategoryShare(this.category, this.amount, this.percent);

  final SpendCategory category;
  final int amount;
  final int percent;
}

/// Один столбик графика «Динамика».
class ChartBar {
  const ChartBar(this.label, this.value);

  final String label;
  final int value;
}

enum StatsPeriod { day, week, month }

/// Всё, что нужно экрану статистики за выбранный период.
class StatsData {
  const StatsData({
    required this.title,
    required this.total,
    required this.change,
    required this.shares,
    required this.barsTitle,
    required this.barsNote,
    required this.bars,
  });

  final String title;
  final int total;
  final String change;
  final List<CategoryShare> shares;
  final String barsTitle;
  final String barsNote;
  final List<ChartBar> bars;
}
