import 'class_contact.dart';

abstract class ListEntry {}

class MeEntry extends ListEntry {
  final Contact contact;
  MeEntry(this.contact);
}

class HeaderEntry extends ListEntry {
  final String letter;
  HeaderEntry(this.letter);
}

class ContactEntry extends ListEntry {
  final Contact contact;
  ContactEntry(this.contact);
}