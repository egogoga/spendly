/// Форматирование сумм, дат и слов по-русски.
library;

const String _nbsp = ' ';

/// 23410 → «23 410».
String formatNumber(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(_nbsp);
    buffer.write(digits[i]);
  }
  return value < 0 ? '−$buffer' : buffer.toString();
}

/// 23410 → «23 410 ₽».
String formatRub(int value) => '${formatNumber(value)}$_nbsp₽';

const List<String> _monthsGenitive = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];

const List<String> _monthsNominative = [
  'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
];

const List<String> _weekdays = [
  'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье',
];

const List<String> weekdaysShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

/// «10 ноября».
String formatDayMonth(DateTime d) => '${d.day} ${_monthsGenitive[d.month - 1]}';

/// «Вторник, 10 ноября».
String formatWeekdayDate(DateTime d) => '${_weekdays[d.weekday - 1]}, ${formatDayMonth(d)}';

/// «Ноябрь».
String monthNominative(DateTime d) => _monthsNominative[d.month - 1];

/// «09:05».
String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// «Сегодня, 10 ноября», «Вчера, 9 ноября» или «Пятница, 6 ноября».
String dayLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Сегодня, ${formatDayMonth(d)}';
  if (diff == 1) return 'Вчера, ${formatDayMonth(d)}';
  return formatWeekdayDate(d);
}

/// Приветствие по времени суток.
String greeting() {
  final hour = DateTime.now().hour;
  if (hour < 5) return 'Доброй ночи';
  if (hour < 12) return 'Доброе утро';
  if (hour < 18) return 'Добрый день';
  return 'Добрый вечер';
}

/// Склонение: pluralRu(2, 'трата', 'траты', 'трат') → «траты».
String pluralRu(int n, String one, String few, String many) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}
