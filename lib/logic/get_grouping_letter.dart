
import 'pinyin_utils.dart';


/// Extracts the first actual letter from a string, skipping spaces, quotes, numbers, etc.
String getGroupingLetter(String name) {
  if (name.isEmpty) return '#';

  for (int i = 0; i < name.length; i++) {
    final char = name[i];

    if (RegExp(r'\p{L}', unicode: true).hasMatch(char)) {
      final pinyin = PinyinUtils.getFirstLetter(char);
      if (pinyin.isNotEmpty) {
        return pinyin[0].toUpperCase();
      }
    }
  }

  return '#';
}