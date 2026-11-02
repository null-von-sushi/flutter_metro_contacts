import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_metro_contacts/widgets/contact_list.dart';
import 'package:flutter_metro_contacts/widgets/bottom_app_bar.dart';
import 'package:wp_pivot_flutter/wp_components.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';
import 'settings_page.dart';
import 'contact_details.dart';
import 'data/class_contact.dart';
import 'other/accent_color.dart';
import 'other/settings.dart';
import 'data/contact_repository.dart';
import 'services/metrov_theme_service.dart';
import 'transitions/wp_phone_transition.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await Settings.load();
  MetrovAccent = await MetrovThemeService.getAccentColor();
  debugPrint(
    '[MetroV] startup accent = '
        '${MetrovAccent == null ? "null" : "#${MetrovAccent!.value.toRadixString(16).padLeft(8, '0').toUpperCase()}"}',
  );
  runApp(MyApp(appSettings: settings));
}

const int _homeMaxIndex = 1;
const int _settingsMaxIndex = 12;

class MyApp extends StatefulWidget {
  final Settings appSettings;
  const MyApp({super.key, required this.appSettings});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recomputeAccent();
    widget.appSettings.selectedAccentArgb.addListener(_onAccentChanged);
    widget.appSettings.useLauncherAccent.addListener(_onAccentChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.appSettings.selectedAccentArgb.removeListener(_onAccentChanged);
    widget.appSettings.useLauncherAccent.removeListener(_onAccentChanged);
    widget.appSettings.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshMetrovAccent();
    }
  }

  Future<void> _refreshMetrovAccent() async {
    final fresh = await MetrovThemeService.getAccentColor();
    if (fresh?.value == MetrovAccent?.value) return;
    if (fresh == null && MetrovAccent == null) return;
    MetrovAccent = fresh;
    if (!mounted) return;
    setState(_recomputeAccent);
  }

  void _onAccentChanged() {
    setState(_recomputeAccent);
  }

  void _recomputeAccent() {
    final useLauncher = widget.appSettings.useLauncherAccent.value;
    final metroV = MetrovAccent;
    final selected = Color(widget.appSettings.selectedAccentArgb.value);
    if (useLauncher && metroV != null) {
      AccentColor = metroV;
    } else {
      AccentColor = selected;
    }
    debugPrint(
      '[accent] useLauncher=$useLauncher '
          'metroV=${metroV == null ? "null" : "#${metroV.value.toRadixString(16).padLeft(8, '0').toUpperCase()}"} '
          'selected=#${selected.value.toRadixString(16).padLeft(8, '0').toUpperCase()} '
          '-> effective=#${AccentColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
    );
  }

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
      onGenerateRoute: (routeSettings) => MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => PeoplePage(settings: widget.appSettings),
      ),
    );
  }
}

class PeoplePage extends StatefulWidget {
  final Settings settings;
  const PeoplePage({super.key, required this.settings});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exitController;
  late Future<({List<Contact> contacts, Contact? meContact})> _allPivotFuture;
  final _contactRepository = ContactRepository();

  late final Listenable _filterListenable;

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

    _filterListenable = Listenable.merge([
      widget.settings.accountFilter,
      widget.settings.groupFilter,
    ]);
    _filterListenable.addListener(_onFilterChanged);

    _allPivotFuture = _fetchFiltered();
  }

  @override
  void dispose() {
    _filterListenable.removeListener(_onFilterChanged);
    _exitController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    if (!mounted) return;
    setState(() {
      _allPivotFuture = _fetchFiltered();
    });
  }

  Future<({List<Contact> contacts, Contact? meContact})> _fetchFiltered() {
    return _contactRepository.fetchContacts(
      accountId: widget.settings.accountFilter.value,
      groupId: widget.settings.groupFilter.value,
    );
  }

  void _openSettings() {
    _exitController.forward();
    Navigator.of(context).push(
      WpPhonePageRoute(
        incomingMaxIndex: _settingsMaxIndex,
        outgoingMaxIndex: _homeMaxIndex,
        builder: (_) => SettingsPage(
          onPopStart: _exitController.reverse,
          settings: widget.settings,
        ),
      ),
    );
  }

  void _openDetails(Contact contact) {
    _exitController.forward();
    Navigator.of(context).push(
      WpPhonePageRoute(
        incomingMaxIndex: contact.detailsMaxIndex,
        outgoingMaxIndex: _homeMaxIndex,
        builder: (_) => ContactDetailsPage(
          contact: contact,
          settings: widget.settings,
          onPopStart: _exitController.reverse,
        ),
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
                  future: _allPivotFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox.expand(
                        child: Center(
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 48),
                            child: SizedBox(
                              width: double.infinity,
                              height: 4,
                              child: WpProgressBar(
                                semanticLabel: 'Loading contacts',
                                color: AccentColor,
                              ),
                            ),
                          ),
                        ),
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
                          'No contacts match the current filter.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    return ContactList(
                      contacts: data.contacts,
                      meContact: data.meContact,
                      onContactTap: _openDetails,
                      settings: widget.settings,
                    );
                  },
                ),
                ContactList(contacts: const [], settings: widget.settings),
                ContactList(contacts: const [], settings: widget.settings),
              ],
            ),
          ),
        ),
        bottomNavigationBar: FeatherLayer(
          index: 1,
          child: WpBottomAppBar(
            actions: [
              WpApplicationBarAction(
                icon: const Icon(
                  Icons.add,
                  weight: 1000,
                  size: 30,
                  color: Colors.white,
                ),
                label: 'add',
                onPressed: _addNewContact,
              ),
            ],
            menuItems: [
              WpApplicationBarMenuItem(
                label: 'settings',
                onPressed: _openSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}