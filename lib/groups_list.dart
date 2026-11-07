import 'package:flutter/material.dart';
import '../data/group_query.dart';
import '../other/accent_color.dart';

/// A group paired with its non-zero contact count, as shown in the
/// groups tab. The count is pre-computed by the caller so the tile
/// only has to render.
class GroupEntry {
  final NativeGroup group;
  final int contactCount;
  const GroupEntry({required this.group, required this.contactCount});
}

class GroupsList extends StatelessWidget {
  final List<GroupEntry> groups;
  final void Function(NativeGroup group) onGroupTap;

  const GroupsList({
    super.key,
    required this.groups,
    required this.onGroupTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final entry = groups[index];
        return _GroupTile(
          entry: entry,
          onTap: () => onGroupTap(entry.group),
        );
      },
    );
  }
}

class _GroupTile extends StatelessWidget {
  final GroupEntry entry;
  final VoidCallback onTap;

  const _GroupTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final group = entry.group;
    final accountLabel = group.accountName.isNotEmpty
        ? group.accountName
        : group.accountType;
    final plural = entry.contactCount == 1 ? 'contact' : 'contacts';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              color: AccentColor,
              alignment: Alignment.center,
              child: const Icon(
                Icons.group_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$accountLabel · ${entry.contactCount} $plural',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}