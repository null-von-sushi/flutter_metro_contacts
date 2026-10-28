import 'package:flutter/material.dart';
import 'package:flutter_metro_contacts/widgets/contact_list.dart';
import 'package:flutter_metro_contacts/widgets/bottom_app_bar.dart'; // <-- Import the new bar
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';
import 'settings_page.dart';
import 'data/class_contact.dart';
import 'other/accent_color.dart';
import 'data/contact_repository.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'People',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: wpPivotFontFamily,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const PeoplePage(),
    );
  }
}

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  late Future<({List<Contact> contacts, Contact? meContact})> _contactsFuture;

  final _contactRepository = ContactRepository();

  @override
  void initState() {
    super.initState();
    _contactsFuture = _contactRepository.fetchContacts();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _addNewContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('New Contact'),
        content: const Text('Add contact form will go here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Save', style: TextStyle(color: AccentColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: WpPivotView(
          title: 'PEOPLE',
          tabTitles: const ['all', 'recent', 'rooms'],
          wrap: true,
          children: [
            FutureBuilder<({List<Contact> contacts, Contact? meContact})>(
              future: _contactsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load contacts', style: TextStyle(color: Colors.white)));
                }

                final data = snapshot.data;
                if (data == null || data.contacts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No contacts found or permission denied.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ContactList(
                  contacts: data.contacts,
                  meContact: data.meContact,
                );
              },
            ),
            const ContactList(contacts: []),
            const ContactList(contacts: []),
          ],
        ),
      ),
      // Use the new custom bar here
      bottomNavigationBar: PeopleBottomBar(
        onAdd: _addNewContact,
        onSettings: _openSettings,
      ),
    );
  }
}