import 'package:flutter/material.dart';
import 'package:flutter_metro_contacts/widgets/contact_list.dart';
import 'package:flutter_metro_contacts/widgets/bottom_app_bar.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';
import 'settings_page.dart';
import 'data/class_contact.dart';
import 'other/accent_color.dart';
import 'data/contact_repository.dart';
import 'transitions/wp_phone_transition.dart';

void main() => runApp(const MyApp());

const int _homeMaxIndex = 1;
const int _settingsMaxIndex = 4; // Settings has FeatherLayers 0..4

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
        pageTransitionsTheme: const PageTransitionsTheme(builders: {}),
      ),
      initialRoute: Navigator.defaultRouteName,
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => const PeoplePage(),
      ),
    );
  }
}

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exitController;
  late Future<({List<Contact> contacts, Contact? meContact})> _contactsFuture;
  final _contactRepository = ContactRepository();

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      vsync: this,
      duration: WpTurnstileFeatherTiming(
        outgoingMaxIndex: _homeMaxIndex,
        incomingMaxIndex: _settingsMaxIndex,
      ).routeDuration(),
    );
    _contactsFuture = _contactRepository.fetchContacts();
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  void _openSettings() {
    _exitController.forward();
    Navigator.of(context).push(
      WpPhonePageRoute(
        incomingMaxIndex: _settingsMaxIndex,
        outgoingMaxIndex: _homeMaxIndex,
        builder: (_) => SettingsPage(onPopStart: _exitController.reverse),
      ),
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
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
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
    final route = ModalRoute.of(context);
    return WpPhoneFeatherScope(
      timing: WpTurnstileFeatherTiming(
        outgoingMaxIndex: _homeMaxIndex,
        incomingMaxIndex: _settingsMaxIndex,
      ),
      animation: route?.animation ?? const AlwaysStoppedAnimation(1.0),
      secondaryAnimation: _exitController,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: FeatherLayer(
            index: 0,
            child: WpPivotView(
              title: 'PEOPLE',
              tabTitles: const ['all', 'favorites', 'recent'],
              wrap: true,
              children: [
                FutureBuilder<
                    ({List<Contact> contacts, Contact? meContact})>(
                  future: _contactsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Failed to load contacts',
                            style: TextStyle(color: Colors.white)),
                      );
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
        ),
        bottomNavigationBar: FeatherLayer(
          index: 1,
          child: PeopleBottomBar(
            onAdd: _addNewContact,
            onSettings: _openSettings,
          ),
        ),
      ),
    );
  }
}