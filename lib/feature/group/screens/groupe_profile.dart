import 'package:flutter/material.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/utils/coloors.dart';
import 'package:tuyage/common/widgets/custom_icon_button.dart';
import 'package:tuyage/feature/chat/widgets/custom_list_tile.dart';

class GroupProfilePage extends StatelessWidget {
  const GroupProfilePage({
    super.key,
    required this.groupName,
    required this.uid,
  });

  final String groupName;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.profilePageBg,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            delegate: SliverPersistentDelegate(groupName),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      Text(
                        groupName,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '1000 members',
                        style: TextStyle(
                          fontSize: 20,
                          color: context.theme.greyColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          iconWithText(icon: Icons.call_outlined, text: 'Call'),
                          iconWithText(
                              icon: Icons.video_call_outlined, text: 'Video'),
                          iconWithText(
                              icon: Icons.search_outlined, text: 'Search'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CustomListTile(
                  title: 'Group Settings',
                  leading: Icons.settings,
                ),
                CustomListTile(
                  title: 'Media visibility',
                  leading: Icons.photo,
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(height: 20),
                const CustomListTile(
                  title: 'Group Encryption',
                  subTitle: 'Messages and calls are end-to-end encrypted.',
                  leading: Icons.lock,
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.only(left: 25, right: 10),
                  leading: const Icon(
                    Icons.block,
                    color: Color(0xFFF15C6D),
                  ),
                  title: Text(
                    'Leave Group',
                    style: const TextStyle(
                      color: Color(0xFFF15C6D),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  iconWithText({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 30,
            color: Coloors.greenDark,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(color: Coloors.greenDark),
          ),
        ],
      ),
    );
  }
}

class SliverPersistentDelegate extends SliverPersistentHeaderDelegate {
  final String groupName;

  final double maxHeaderHeight = 180;
  final double minHeaderHeight = kToolbarHeight + 20;

  SliverPersistentDelegate(this.groupName);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final size = MediaQuery.of(context).size;
    final percent = shrinkOffset / (maxHeaderHeight - 35);
    final percent2 = shrinkOffset / (maxHeaderHeight);
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        color: Theme.of(context)
            .appBarTheme
            .backgroundColor!
            .withOpacity(percent2 * 2 < 1 ? percent2 * 2 : 1),
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).viewPadding.top + 15,
              left: (size.width / 2 - 50),
              child: Text(
                groupName,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withOpacity(percent2),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: MediaQuery.of(context).viewPadding.top + 5,
              child: BackButton(
                color:
                    percent2 > .3 ? Colors.white.withOpacity(percent2) : null,
              ),
            ),
            Positioned(
              right: 0,
              top: MediaQuery.of(context).viewPadding.top + 5,
              child: CustomIconButton(
                onPressed: () {},
                icon: Icons.more_vert,
                iconColor: percent2 > .3
                    ? Colors.white.withOpacity(percent2)
                    : Theme.of(context).textTheme.bodyMedium!.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => maxHeaderHeight;

  @override
  double get minExtent => minHeaderHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
