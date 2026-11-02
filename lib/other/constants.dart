import 'package:flutter/material.dart';

// Accent Color used for the app if no actual preference can be found
const Color accentColorFallback = Color(0xFFA20025);

// List of strings that represent the concept of self. Used for identifying
// who to put as the ME tile.
const Set<String> meStrings = {
  'me', '我', 'yo', 'moi', 'ich', 'io', 'eu', 'я', '私', '나',
};

// List of messaging apps
class MessagingAccountTypes {
  /// Known identifiers and account types for Signal and its forks
  static const List<String> signalMessenger = [
    'org.thoughtcrime.securesms', // Official Signal & Langis fork
    'im.molly.app',               // Molly (Main / FOSS variants)
    'im.molly.app.socket',        // Molly Socket variant
  ];

  static const List<String> signalMessengerLabels = [
    'signal',
    'https://signal.me/#p/',
    'sgnl://',
  ];

  /// Known identifiers and account types for Telegram and its forks
  static const List<String> telegramMessenger = [
    'org.telegram.messenger',      // Official Telegram (Play Store)
    'org.telegram.messenger.web',  // Official Telegram (Direct APK / Web)
    'org.thunderdog.challegram',   // Telegram X
    'org.telegram.messenger.beta', // Telegram Beta
    'tw.nekomimi.nekogram',        // Nekogram
    'xyz.nextalone.nagram',        // Nagram
    'org.telegram.plus',           // Plus Messenger
    'com.iMe.android',             // iMe Messenger
    'org.vidogram.messenger',      // Vidogram
    'com.turrit.app',              // Turrit
    'com.mdgram.messenger',        // MDGram
  ];

  static const List<String> telegramMessengerLabels = [
    'telegram',
    'tg',
    'https://t.me/',
  ];

  static const List<String> weChatMessenger = [
    // WeChat. We won't editorialise. Much.
    'com.tencent.mm',
  ];

  static const List<String> weChatMessengerLabels = [
    'weixin',
    'wechat',
    '微信',
  ];
}

/// Parses "favorite color" mentions out of a contact's notes.
///
/// Supports:
/// - English: "favorite color: red", "favourite colour is #1212FF"
/// - Chinese: "最喜歡紫色", "最喜歡的顏色是紫色"
///
/// The captured colour name is looked up in [colorMap], or if it looks
/// like a hex code (#RRGGBB or #AARRGGBB) it's used directly.
class FavoriteColorDetection {
  /// Regex patterns tried in order. Group 1 must capture the text likely
  /// to contain the colour (a hex code or a name).
  static const List<String> patterns = [
    // English: "favorite color: X" / "favourite colour is X"
    r'favou?rite\s+colou?r\s*(?:[:=\-]|is)?\s*(.{1,30})',
    // Chinese: "最喜歡X" / "最喜歡的顏色是X"
    r'最喜[欢歡].{0,6}?(.{1,20})',
    // Chinese (short): "喜歡X"
    r'喜[欢歡].{0,3}?(.{1,20})',
  ];

  /// Color name → ARGB int.
  ///
  /// Structure: one section per language, each listing its own spellings.
  /// To add a new language (Japanese, Korean, …), append a new section
  /// with a `// ── <Language> ──` header and one entry per colour. No
  /// other file needs to change; the matching regex in
  /// `ContactRepository._resolveColorFromText` builds itself from these
  /// keys dynamically.
  ///
  /// Rules:
  /// 1. Traditional Chinese entries come first; Simplified follow.
  /// 2. Only Simplified entries that differ from their Traditional
  ///    counterpart need listing — `橙色`, `紫色`, `黑色`, `白色`, `灰色`,
  ///    `青色`, `靛色`, `棕色` are identical in both scripts and appear
  ///    only once.
  /// 3. Every Chinese entry ends in `色`. Single-character colours are
  ///    deliberately not supported (too many false positives in prose).
  static const Map<String, int> colorMap = {

    // ── English ──
    'lime':    0xFFA4C400,
    'green':   0xFF60A917,
    'emerald': 0xFF008A00,
    'teal':    0xFF00ABA9,
    'cyan':    0xFF1BA1E2,
    'cobalt':  0xFF0050EF,
    'indigo':  0xFF6A00FF,
    'violet':  0xFFAA00FF,
    'pink':    0xFFF472D0,
    'magenta': 0xFFD80073,
    'crimson': 0xFFA20025,
    'red':     0xFFE51400,
    'orange':  0xFFFA6800,
    'amber':   0xFFF0A30A,
    'yellow':  0xFFE3C800,
    'brown':   0xFF825A2C,
    'olive':   0xFF6D8764,
    'steel':   0xFF647687,
    'mauve':   0xFF76608A,
    'taupe':   0xFF87794E,
    'black':   0xFF000000,
    'white':   0xFFFFFFFF,
    'gray':    0xFF808080,
    'grey':    0xFF808080,
    'none':    0xFF808080, //because I have this one person who insists on not having a favorite color at all and that sould resolve the the most boring color of all, grey :P

    // ── Chinese ──
    '紅色': 0xFFE51400,
    '橙色': 0xFFFA6800,
    '黃色': 0xFFE3C800,
    '綠色': 0xFF60A917,
    '青色': 0xFF1BA1E2,
    '藍色': 0xFF0050EF,
    '靛色': 0xFF6A00FF,
    '紫色': 0xFFAA00FF,
    '粉色': 0xFFF472D0,
    '粉紅色': 0xFFF472D0,
    '洋紅色': 0xFFD80073,
    '棕色': 0xFF825A2C,
    '黑色': 0xFF000000,
    '白色': 0xFFFFFFFF,
    '灰色': 0xFF808080,

    // ── Chinese (殘體字) — only entries that differ from
    //     the normal form ──
    '红色': 0xFFE51400,
    '黄色': 0xFFE3C800,
    '绿色': 0xFF60A917,
    '蓝色': 0xFF0050EF,
    '粉红色': 0xFFF472D0,
    '洋红色': 0xFFD80073,
  };
}