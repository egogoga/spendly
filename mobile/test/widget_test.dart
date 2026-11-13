// Проверки демо-разборщика фраз. Запуск: flutter test
import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/data/models.dart';
import 'package:spendly/data/phrase_parser.dart';

void main() {
  test('пятихатка и «сотка с полтосом»', () {
    final items = PhraseParser.parse('Оставил пятихатку на шаурму и сотку с полтосом на кофе');
    expect(items.length, 2);
    expect(items[0].title, 'Шаурма');
    expect(items[0].amount, 500);
    expect(items[0].category, SpendCategory.food);
    expect(items[1].title, 'Кофе');
    expect(items[1].amount, 150);
    expect(items[1].source, 'сотку с полтосом');
  });

  test('косарь и числа словами', () {
    final items = PhraseParser.parse('косарь сто двадцать на продукты');
    expect(items.single.amount, 1120);
    expect(items.single.category, SpendCategory.groceries);
  });

  test('цифры и несколько трат через «и»', () {
    final items = PhraseParser.parse('такси 430 и кофе 200');
    expect(items.map((e) => e.amount).toList(), [430, 200]);
  });

  test('пять косарей = 5000', () {
    expect(PhraseParser.parse('отложил пять косарей').single.amount, 5000);
  });

  test('фраза без суммы ничего не даёт', () {
    expect(PhraseParser.parse('купил что-то вкусное'), isEmpty);
  });

  test('подсветка суммы целиком', () {
    final amounts = PhraseParser.segments('сотку с полтосом на кофе')
        .where((s) => s.isAmount)
        .map((s) => s.text)
        .toList();
    expect(amounts, ['сотку с полтосом']);
  });
}
