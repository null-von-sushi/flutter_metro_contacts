/// Lowercases a string for the Windows Phone typographic treatment.
///
/// WP8.1 rendered most UI strings — section headers, buttons, pivot titles —
/// in lowercase. Contact names and data values kept their original casing,
/// so this is meant for typographic elements only, not for user data.
String wpLowercase(String input) => input.toLowerCase();