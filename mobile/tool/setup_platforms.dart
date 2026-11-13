// Добавляет в проект разрешения на микрофон и распознавание речи.
//
// Запускать ОДИН раз, после команды
//   flutter create --project-name spendly --platforms android,ios,web .
// из папки проекта:
//   dart run tool/setup_platforms.dart
//
// Скрипт можно запускать повторно: то, что уже добавлено, он пропустит.
import 'dart:io';

void main() {
  final android = _patchAndroid();
  final ios = _patchIos();
  if (android || ios) {
    stdout.writeln('Готово. Теперь можно запускать: flutter run');
  } else {
    stdout.writeln(
      'Не нашёл папок android и ios. Сначала выполните:\n'
      '  flutter create --project-name spendly --platforms android,ios,web .',
    );
  }
}

/// Android: разрешения на микрофон и интернет, доступ к сервису распознавания речи
/// и разрешение ходить на локальный сервер по http (для разработки).
bool _patchAndroid() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) return false;
  var xml = file.readAsStringSync();
  final before = xml;

  const permissions = [
    'android.permission.INTERNET',
    'android.permission.RECORD_AUDIO',
  ];
  for (final permission in permissions) {
    if (!xml.contains('"$permission"')) {
      xml = xml.replaceFirstMapped(
        RegExp(r'<manifest[^>]*>'),
        (m) => '${m.group(0)}\n    <uses-permission android:name="$permission"/>',
      );
    }
  }

  const speechIntent = '        <intent>\n'
      '            <action android:name="android.speech.RecognitionService" />\n'
      '        </intent>';
  if (!xml.contains('android.speech.RecognitionService')) {
    if (xml.contains('<queries>')) {
      xml = xml.replaceFirst('<queries>', '<queries>\n$speechIntent');
    } else {
      xml = xml.replaceFirst('</manifest>', '    <queries>\n$speechIntent\n    </queries>\n</manifest>');
    }
  }

  if (!xml.contains('usesCleartextTraffic')) {
    xml = xml.replaceFirst('<application', '<application\n        android:usesCleartextTraffic="true"');
  }

  if (xml != before) {
    file.writeAsStringSync(xml);
    stdout.writeln('Android: разрешения добавлены в ${file.path}');
  } else {
    stdout.writeln('Android: всё уже настроено');
  }
  return true;
}

/// iOS: тексты, которые телефон покажет при запросе доступа к микрофону и речи.
bool _patchIos() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) return false;
  var plist = file.readAsStringSync();
  final before = plist;

  const entries = {
    'NSMicrophoneUsageDescription': 'Микрофон нужен, чтобы записывать траты голосом.',
    'NSSpeechRecognitionUsageDescription': 'Распознавание речи превращает вашу фразу в текст.',
  };
  entries.forEach((key, value) {
    if (plist.contains(key)) return;
    final index = plist.lastIndexOf('</dict>');
    if (index < 0) return;
    plist = '${plist.substring(0, index)}\t<key>$key</key>\n\t<string>$value</string>\n'
        '${plist.substring(index)}';
  });

  if (plist != before) {
    file.writeAsStringSync(plist);
    stdout.writeln('iOS: описания доступа добавлены в ${file.path}');
  } else {
    stdout.writeln('iOS: всё уже настроено');
  }
  return true;
}
