import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Contact;
import 'package:flutter_metro_contacts/widgets/contact_list.dart';
import 'package:flutter_metro_contacts/widgets/bottom_app_bar.dart';
import 'package:flutter_metro_contacts/widgets/custom_app_bar.dart';

// ▼▼▼ Hide the original app bar so your custom one is used ▼▼▼
import 'package:wp_pivot_flutter/wp_components.dart'
    hide WpApplicationBar, WpApplicationBarAction, WpApplicationBarMenuItem, WpApplicationBarMode;
// ▲▲▲

import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';
import 'settings_page.dart';
import 'contact_details.dart';
import 'data/class_contact.dart';
import 'data/group_query.dart';
import 'group_contacts_page.dart';
import 'groups_list.dart';
import 'other/accent_color.dart';
import 'other/settings.dart';
import 'data/contact_repository.dart';
import 'services/metrov_theme_service.dart';
import 'transitions/wp_phone_transition.dart';
import 'contact_edit_page.dart';



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
  late Future<List<GroupEntry>> _groupsFuture;
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
    widget.settings.accountFilter.addListener(_onAccountFilterChanged);

    _allPivotFuture = _fetchFiltered();
    _groupsFuture = _fetchGroups();
  }

  @override
  void dispose() {
    _filterListenable.removeListener(_onFilterChanged);
    widget.settings.accountFilter.removeListener(_onAccountFilterChanged);
    _exitController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    if (!mounted) return;
    setState(() {
      _allPivotFuture = _fetchFiltered();
    });
  }

  void _onAccountFilterChanged() {
    if (!mounted) return;
    setState(() {
      _groupsFuture = _fetchGroups();
    });
  }

  Future<({List<Contact> contacts, Contact? meContact})> _fetchFiltered() {
    return _contactRepository.fetchContacts(
      accountId: widget.settings.accountFilter.value,
      groupId: widget.settings.groupFilter.value,
    );
  }

  Future<List<GroupEntry>> _fetchGroups() async {
    final status = await FlutterContacts.permissions.request(
      PermissionType.readWrite,
    );
    if (status != PermissionStatus.granted) return const [];

    final all = await GroupQuery.fetchAll();
    if (all.isEmpty) return const [];

    final filterAccount = widget.settings.accountFilter.value;
    final filtered = filterAccount == null
        ? all
        : all.where((g) => g.accountKey == filterAccount).toList();

    final entries = await Future.wait(filtered.map(_queryGroupCount));
    final nonEmpty = entries.where((e) => e.contactCount > 0).toList()
      ..sort((a, b) {
        final byTitle = a.group.title
            .toLowerCase()
            .compareTo(b.group.title.toLowerCase());
        if (byTitle != 0) return byTitle;
        return a.group.accountName
            .toLowerCase()
            .compareTo(b.group.accountName.toLowerCase());
      });
    return nonEmpty;
  }

  Future<GroupEntry> _queryGroupCount(NativeGroup g) async {
    try {
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.identifiers},
        filter: ContactFilter.group(g.id),
      ).timeout(const Duration(seconds: 5));
      return GroupEntry(group: g, contactCount: contacts.length);
    } catch (_) {
      return GroupEntry(group: g, contactCount: 0);
    }
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

  Future<void> _openDetails(Contact contact) async {
    _exitController.forward();

    final changed = await Navigator.of(context).push(
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

    if (changed == true && mounted) {
      setState(() {
        _allPivotFuture = _fetchFiltered();
        _groupsFuture = _fetchGroups();
      });
    }
  }

  Future<void> _openGroup(NativeGroup group) async {
    _exitController.forward();
    final changed = await Navigator.of(context).push(
      WpPhonePageRoute(
        incomingMaxIndex: groupContactsMaxIndex,
        outgoingMaxIndex: _homeMaxIndex,
        builder: (_) => GroupContactsPage(
          group: group,
          settings: widget.settings,
          onPopStart: _exitController.reverse,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() {
        _allPivotFuture = _fetchFiltered();
        _groupsFuture = _fetchGroups();
      });
    }
  }

  void _addNewContact() {
    _exitController.forward();
    Navigator.of(context).push(
      WpPhonePageRoute(
        incomingMaxIndex: 3,
        outgoingMaxIndex: _homeMaxIndex,
        builder: (_) => ContactEditPage(
          settings: widget.settings,
          onPopStart: _exitController.reverse,
          onSaved: () {
            if (mounted) {
              setState(() {
                _allPivotFuture = _fetchFiltered();
                _groupsFuture = _fetchGroups();
              });
            }
          },
        ),
      ),
    );
  }

  // ── Tab content builders ────────────────────────────────────────────

  Widget _buildLoading() {
    return SizedBox.expand(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
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

  Widget _buildError() {
    return const Center(
      child: Text(
        'Failed to load contacts',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildAllTab() {
    return FutureBuilder<({List<Contact> contacts, Contact? meContact})>(
      future: _allPivotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (snapshot.hasError) {
          return _buildError();
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
    );
  }

  Widget _buildFavoritesTab() {
    return FutureBuilder<({List<Contact> contacts, Contact? meContact})>(
      future: _allPivotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (snapshot.hasError) {
          return _buildError();
        }
        final data = snapshot.data;
        if (data == null) {
          return _buildError();
        }

        final favorites = data.contacts
            .where((c) => c.isStarred)
            .toList();

        final me = data.meContact;
        final starredMe = (me != null && me.isStarred) ? me : null;

        if (favorites.isEmpty && starredMe == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'No favorites yet.\nStar a contact from its details page to add it here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Colors.white54,
                  height: 1.5,
                ),
              ),
            ),
          );
        }

        return ContactList(
          contacts: favorites,
          meContact: starredMe,
          onContactTap: _openDetails,
          settings: widget.settings,
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    return FutureBuilder<List<GroupEntry>>(
      future: _groupsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (snapshot.hasError) {
          return _buildError();
        }
        final groups = snapshot.data ?? const [];
        if (groups.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'No groups with contacts in this account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Colors.white70,
                ),
              ),
            ),
          );
        }
        return GroupsList(groups: groups, onGroupTap: _openGroup);
      },
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
              tabTitles: const ['all', 'favorites', 'groups'],
              wrap: true,
              children: [
                _buildAllTab(),
                _buildFavoritesTab(),
                _buildGroupsTab(),
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