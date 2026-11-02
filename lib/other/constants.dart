import 'package:flutter/material.dart';

// Accent Color used for the app if no actual preference can be found
const Color accentColorFallback = Color(0xFFA20025);

// List of strings that represent the concept of self. Used for identifying who to put as the ME tile.
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
    'org.telegram.messenger',     // Official Telegram (Play Store)
    'org.telegram.messenger.web', // Official Telegram (Direct APK / Web)
    'org.thunderdog.challegram',  // Telegram X
    'org.telegram.messenger.beta',// Telegram Beta
    'tw.nekomimi.nekogram',      // Nekogram
    'xyz.nextalone.nagram',       // Nagram
    'org.telegram.plus',          // Plus Messenger
    'com.iMe.android',            // iMe Messenger
    'org.vidogram.messenger',     // Vidogram
    'com.turrit.app',             // Turrit
    'com.mdgram.messenger',       // MDGram
  ];

  static const List<String> telegramMessengerLabels = [
    'telegram',
    "tg",
  ];

  static const List<String> weChatMessenger = [
    'com.tencent.mm',       // WeChat, kinda moot since this piece of shit doesn't actually allow anything and I pity anyone who has to suffer it's use. Consider switching to carrier pidgeon. Or at least physical mail.
  ];

  static const List<String> weChatMessengerLabels = [
    'weixin',
    'wechat',
    '微信',
  ];

  static const List<String> favoriteColorString = [
    '最喜歡.{1,3}色',
    'favou*rite\scolou*r:\s*.{1,10}',
  ];
}