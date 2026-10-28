import 'package:lpinyin/lpinyin.dart';

class PinyinUtils {
  /// Returns the full pinyin string for sorting.
  static String getFullPinyin(String text) {
    return PinyinHelper.getPinyin(text);
  }

  /// Returns the first letter of the pinyin for a single character.
  static String getFirstLetter(String char) {
    final pinyin = PinyinHelper.getPinyin(char);
    return pinyin.isNotEmpty ? pinyin[0].toUpperCase() : '';
  }
}