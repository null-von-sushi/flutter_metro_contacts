import 'package:flutter/material.dart';

import 'contact_details.dart';
import 'data/class_contact.dart';
import 'data/contact_repository.dart';
import 'data/group_query.dart';
import 'other/accent_color.dart';
import 'other/settings.dart';
import 'transitions/wp_phone_transition.dart';
import 'widgets/bottom_app_bar.dart';
import 'widgets/contact_list.dart';
import 'package:wp_pivot_flutter/wp_components.dart'
    hide WpApplicationBar, WpApplicationBarAction, WpApplicationBarMenuItem, WpApplicationBarMode;


/// Max feather index used on this page. Used both for the page's own
/// feather timing (when it's the incoming route) and as the
/// `outgoingMaxIndex` when pushing a details route on top.
const int groupContactsMaxIndex = 2;

class GroupContactsPage extends StatefulWidget {
  final NativeGroup group;
  final Settings settings;
  final VoidCallback? onPopStart;

  const GroupContactsPage({
    super.key,
    required this.group,
    required this.settings,
    this.onPopStart,
  });

  @override
  State<GroupContactsPage> createState() => _GroupContactsPageState();
}

class _GroupContactsPageState extends State<GroupContactsPage> {
  final _repository = ContactRepository();
  late Future<({List<Contact> contacts, Contact? meContact})> _future;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<({List<Contact> contacts, Contact? meContact})> _fetch() {
    return _repository.fetchContacts(
      accountId: widget.group.accountKey,
      groupId: widget.group.id,
    );
  }

  void _handleBack() {
    widget.onPopStart?.call();
    Navigator.of(context).pop(_hasChanged);
  }

  Future<void> _openDetails(Contact contact) async {
    final changed = await Navigator.of(context).push(
      WpPhonePageRoute(
        incomingMaxIndex: contact.detailsMaxIndex,
        outgoingMaxIndex: groupContactsMaxIndex,
        builder: (_) => ContactDetailsPage(
          contact: contact,
          settings: widget.settings,
        ),
      ),
    );
    if (changed == true && mounted) {
      _hasChanged = true;
      setState(() {
        _future = _fetch();
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final anim = route?.animation ?? const AlwaysStoppedAnimation(1.0);
    final accountLabel = widget.group.accountName.isNotEmpty
        ? widget.group.accountName
        : widget.group.accountType;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: anim,
                builder: (context, _) {
                  final t = (anim.value / 0.4).clamp(0.0, 1.0);
                  return ColoredBox(color: Colors.black.withOpacity(t));
                },
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FeatherLayer(
                    index: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GROUP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.group.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            accountLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: FeatherLayer(
                      index: 1,
                      child: FutureBuilder<
                          ({List<Contact> contacts, Contact? meContact})>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoading();
                          }
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text(
                                'Failed to load contacts',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }
                          final data = snapshot.data;
                          if (data == null || data.contacts.isEmpty) {
                            return const Center(
                              child: Text(
                                'No contacts in this group.',
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
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: FeatherLayer(
          index: 2,
          child: WpBottomAppBar(
            actions: [
              WpApplicationBarAction(
                icon: const Icon(Icons.arrow_back, size: 20),
                label: 'back',
                onPressed: _handleBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}