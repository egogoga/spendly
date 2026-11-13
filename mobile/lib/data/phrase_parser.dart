import 'models.dart';

/// Кусок фразы с пометкой: это сумма или обычные слова.
/// Нужен, чтобы подсвечивать суммы в тексте.
class PhraseSegment {
  const PhraseSegment(this.text, this.isAmount);

  final String text;
  final bool isAmount;
}

class _Keyword {
  const _Keyword(this.stem, this.title, this.category);

  final String stem; // начало слова: «шаурм» подходит к «шаурма», «шаурму»
  final String title;
  final SpendCategory category;
}

/// ДЕМО-разбор фраз прямо в приложении.
///
/// Нужен только для того, чтобы заготовка работала без сервера.
/// В настоящем приложении фразу разбирает GigaChat на сервере
/// (см. SpendlyApi.parsePhrase), а этот класс останется для подсветки сумм.
///
/// Понимает: цифры («такси 430»), числа словами («четыреста тридцать»)
/// и сленг: пятихатка = 500, сотка = 100, полтос = 50, косарь = 1000,
/// а также сочетания («сотку с полтосом» = 150, «пять косарей» = 5000).
class PhraseParser {
  PhraseParser._();

  static const Map<String, int> _numbers = {
    'один': 1, 'одна': 1, 'одну': 1, 'два': 2, 'две': 2, 'три': 3, 'четыре': 4,
    'пять': 5, 'шесть': 6, 'семь': 7, 'восемь': 8, 'девять': 9, 'десять': 10,
    'одиннадцать': 11, 'двенадцать': 12, 'тринадцать': 13, 'четырнадцать': 14,
    'пятнадцать': 15, 'шестнадцать': 16, 'семнадцать': 17, 'восемнадцать': 18,
    'девятнадцать': 19, 'двадцать': 20, 'тридцать': 30, 'сорок': 40,
    'пятьдесят': 50, 'шестьдесят': 60, 'семьдесят': 70, 'восемьдесят': 80,
    'девяносто': 90, 'сто': 100, 'двести': 200, 'триста': 300, 'четыреста': 400,
    'пятьсот': 500, 'шестьсот': 600, 'семьсот': 700, 'восемьсот': 800,
    'девятьсот': 900,
  };

  static const List<_Keyword> _keywords = [
    _Keyword('шаурм', 'Шаурма', SpendCategory.food),
    _Keyword('шаверм', 'Шаверма', SpendCategory.food),
    _Keyword('бургер', 'Бургер', SpendCategory.food),
    _Keyword('пицц', 'Пицца', SpendCategory.food),
    _Keyword('обед', 'Обед', SpendCategory.food),
    _Keyword('ужин', 'Ужин', SpendCategory.food),
    _Keyword('суши', 'Суши', SpendCategory.food),
    _Keyword('ролл', 'Роллы', SpendCategory.food),
    _Keyword('столов', 'Столовая', SpendCategory.food),
    _Keyword('доставк', 'Доставка еды', SpendCategory.food),
    _Keyword('кофе', 'Кофе', SpendCategory.cafe),
    _Keyword('капучин', 'Капучино', SpendCategory.cafe),
    _Keyword('латте', 'Латте', SpendCategory.cafe),
    _Keyword('чай', 'Чай', SpendCategory.cafe),
    _Keyword('кафе', 'Кафе', SpendCategory.cafe),
    _Keyword('метро', 'Метро', SpendCategory.transport),
    _Keyword('такси', 'Такси', SpendCategory.transport),
    _Keyword('автобус', 'Автобус', SpendCategory.transport),
    _Keyword('трамва', 'Трамвай', SpendCategory.transport),
    _Keyword('электричк', 'Электричка', SpendCategory.transport),
    _Keyword('проезд', 'Проезд', SpendCategory.transport),
    _Keyword('бензин', 'Бензин', SpendCategory.transport),
    _Keyword('самокат', 'Самокат', SpendCategory.transport),
    _Keyword('продукт', 'Продукты', SpendCategory.groceries),
    _Keyword('магазин', 'Магазин', SpendCategory.groceries),
    _Keyword('молок', 'Молоко', SpendCategory.groceries),
    _Keyword('хлеб', 'Хлеб', SpendCategory.groceries),
    _Keyword('овощ', 'Овощи', SpendCategory.groceries),
    _Keyword('фрукт', 'Фрукты', SpendCategory.groceries),
    _Keyword('подписк', 'Подписка', SpendCategory.subs),
    _Keyword('музык', 'Музыка', SpendCategory.subs),
    _Keyword('вещ', 'Вещи', SpendCategory.other),
    _Keyword('одежд', 'Одежда', SpendCategory.other),
    _Keyword('обув', 'Обувь', SpendCategory.other),
    _Keyword('книг', 'Книги', SpendCategory.other),
    _Keyword('аптек', 'Аптека', SpendCategory.other),
    _Keyword('лекарств', 'Лекарства', SpendCategory.other),
    _Keyword('кино', 'Кино', SpendCategory.other),
    _Keyword('подар', 'Подарок', SpendCategory.other),
    _Keyword('стрижк', 'Стрижка', SpendCategory.other),
  ];

  static final RegExp _wordRe = RegExp(r'[0-9a-zа-я]+');
  static final RegExp _digitsRe = RegExp(r'^(\d+)(к|k|тыс|р|руб)?$');
  static final RegExp _chunkRe = RegExp(r'[,;.!?]|\s+и\s+|\s+а\s+|\s+плюс\s+|\s+еще\s+');
  static final RegExp _tokenRe = RegExp(r'\S+|\s+');
  static final RegExp _notLetterRe = RegExp(r'[^0-9a-zа-я]');
  // «10 000», «10 000» (неразрывный пробел), «10.000» — одно число.
  static final RegExp _groupedDigitsRe = RegExp(r'(?<!\d)\d{1,3}(?:[   .]\d{3})+(?!\d)');
  static final RegExp _groupSeparatorRe = RegExp(r'[   .]');
  // «тыс.», «руб.», «р.» — точка после сокращения не конец фразы.
  static final RegExp _abbreviationRe = RegExp(r'(?<![а-яa-z])(тыс|руб|р)\.');

  static String _normalize(String s) => s.toLowerCase().replaceAll('ё', 'е');

  /// Готовит фразу к разбору: «10 000» → «10000», «10 тыс. руб.» → «10 тыс руб».
  static String _prepare(String phrase) {
    var s = _normalize(phrase);
    s = s.replaceAllMapped(_groupedDigitsRe, (m) => m[0]!.replaceAll(_groupSeparatorRe, ''));
    s = s.replaceAllMapped(_abbreviationRe, (m) => m[1]!);
    return s;
  }

  /// «Оставил пятихатку на шаурму и сотку с полтосом на кофе» →
  /// [Шаурма, 500 ₽], [Кофе, 150 ₽].
  static List<ParsedExpense> parse(String phrase) {
    final result = <ParsedExpense>[];
    for (final chunk in _prepare(phrase).split(_chunkRe)) {
      final item = _parseChunk(chunk.trim());
      if (item != null) result.add(item);
    }
    return result;
  }

  static ParsedExpense? _parseChunk(String chunk) {
    if (chunk.isEmpty) return null;
    final words = _wordRe.allMatches(chunk).map((m) => m.group(0)!).toList();

    double total = 0; // уже набранные тысячи
    double current = 0; // число, которое набирается сейчас
    var first = -1; // где начинаются слова суммы
    var last = -1; // где заканчиваются

    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      final digits = _digitsRe.firstMatch(w);
      final slang = _slangValue(w);
      var matched = true;

      if (digits != null) {
        final n = int.parse(digits.group(1)!);
        final suffix = digits.group(2);
        if (suffix == 'к' || suffix == 'k' || suffix == 'тыс') {
          total += n * 1000;
        } else {
          current += n;
        }
      } else if (_numbers.containsKey(w)) {
        current += _numbers[w]!;
      } else if (w == 'полтора' || w == 'полторы') {
        current += 1.5;
      } else if (_isThousand(w)) {
        total += (current == 0 ? 1 : current) * 1000;
        current = 0;
      } else if (slang != null) {
        if (slang == 100 && current > 0 && current < 10) {
          current *= 100; // «две сотки» = 200
        } else {
          current += slang;
        }
      } else {
        matched = false;
      }

      if (matched) {
        if (first < 0) first = i;
        last = i;
      }
    }

    final amount = (total + current).round();
    if (amount <= 0 || first < 0) return null;

    var title = 'Покупка';
    var category = SpendCategory.other;
    for (var i = 0; i < words.length; i++) {
      if (i >= first && i <= last) continue;
      final keyword = _findKeyword(words[i]);
      if (keyword != null) {
        title = keyword.title;
        category = keyword.category;
        break;
      }
    }

    return ParsedExpense(
      title: title,
      category: category,
      amount: amount,
      source: words.sublist(first, last + 1).join(' '),
      phrase: chunk,
    );
  }

  static bool _isThousand(String w) =>
      w.startsWith('тысяч') || w.startsWith('косар') || w.startsWith('тыщ') || w == 'тыс';

  static int? _slangValue(String w) {
    if (w.startsWith('пятихат') || w.startsWith('пятисотк')) return 500;
    if (w.startsWith('сотк') || w.startsWith('сотн') || w.startsWith('стольник')) return 100;
    if (w.startsWith('полтос') || w.startsWith('полтин')) return 50;
    if (w.startsWith('чирик') || w.startsWith('червонц') || w == 'червонец') return 10;
    return null;
  }

  static _Keyword? _findKeyword(String w) {
    for (final keyword in _keywords) {
      if (w.startsWith(keyword.stem)) return keyword;
    }
    return null;
  }

  /// Похоже ли слово на сумму: цифры, число словами или сленг.
  static bool isAmountWord(String raw) {
    final w = _normalize(raw).replaceAll(_notLetterRe, '');
    if (w.isEmpty) return false;
    return _digitsRe.hasMatch(w) ||
        _numbers.containsKey(w) ||
        w == 'полтора' ||
        w == 'полторы' ||
        _isThousand(w) ||
        _slangValue(w) != null;
  }

  /// Делит текст на куски «сумма / не сумма» для подсветки.
  /// «сотку с полтосом» подсвечивается целиком.
  static List<PhraseSegment> segments(String text) {
    final tokens = _tokenRe.allMatches(text).map((m) => m.group(0)!).toList();
    final flags = List<bool>.filled(tokens.length, false);

    for (var i = 0; i < tokens.length; i++) {
      if (tokens[i].trim().isEmpty) continue;
      flags[i] = isAmountWord(tokens[i]);
    }
    // Связка «с» между двумя суммами — тоже часть суммы.
    for (var i = 2; i + 2 < tokens.length; i++) {
      if (_normalize(tokens[i]) == 'с' && flags[i - 2] && flags[i + 2]) flags[i] = true;
    }
    // Пробелы между словами суммы — тоже.
    for (var i = 1; i + 1 < tokens.length; i++) {
      if (tokens[i].trim().isEmpty && flags[i - 1] && flags[i + 1]) flags[i] = true;
    }

    final result = <PhraseSegment>[];
    final buffer = StringBuffer();
    bool? currentFlag;
    for (var i = 0; i < tokens.length; i++) {
      if (currentFlag != null && flags[i] != currentFlag) {
        result.add(PhraseSegment(buffer.toString(), currentFlag));
        buffer.clear();
      }
      currentFlag = flags[i];
      buffer.write(tokens[i]);
    }
    if (currentFlag != null && buffer.isNotEmpty) {
      result.add(PhraseSegment(buffer.toString(), currentFlag));
    }
    return result;
  }
}
