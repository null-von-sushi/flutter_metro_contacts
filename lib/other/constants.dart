import 'package:flutter/material.dart';

// Accent Color used for the app if no actual preference can be found
const Color accentColorFallback = Color(0xFFA20025);

// List of strings that represent the concept of self. Used for identifying who to put as the ME tile.
const Set<String> meStrings = {
  'me', '我', 'yo', 'moi', 'ich', 'io', 'eu', 'я', '私', '나',
};