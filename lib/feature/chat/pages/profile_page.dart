import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/helper/last_seen_message.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/common/utils/coloors.dart';
import 'package:tuyage/common/widgets/custom_icon_button.dart';
import 'package:tuyage/feature/chat/widgets/custom_list_tile.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final lastMessage = lastSeenMessage(user.lastSeen);

    return Scaffold(
      backgroundColor: context.theme.profilePageBg,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            delegate: SliverPersistentDelegate(user),
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
                        user.username,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.phoneNumber ?? user.email,
                        style: TextStyle(
                          fontSize: 20,
                          color: context.theme.greyColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.active ? 'online' : "haciye $lastMessage",
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
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
                const ListTile(
                  contentPadding: EdgeInsets.only(left: 30),
                  title: Text('Bite ubu nsigaye nkoresha Tuyage Barundi'),
                  subtitle: Text('17th February'),
                ),
                const SizedBox(height: 20),
                CustomListTile(
                  title: 'Mute notification',
                  leading: Icons.notifications,
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {},
                  ),
                ),
                const CustomListTile(
                  title: 'Custom notification',
                  leading: Icons.music_note,
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
                  title: 'Encryption',
                  subTitle:
                      'Messages and calls are end-to-end encrypted, Tap to verify.',
                  leading: Icons.lock,
                ),
                const CustomListTile(
                  title: 'Disappearing messages',
                  subTitle: 'Off',
                  leading: Icons.timer,
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.only(left: 25, right: 10),
                  leading: const Icon(
                    Icons.block,
                    color: Color(0xFFF15C6D),
                  ),
                  title: Text(
                    'Block ${user.username}',
                    style: const TextStyle(
                      color: Color(0xFFF15C6D),
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.only(left: 25, right: 10),
                  leading: const Icon(
                    Icons.thumb_down,
                    color: Color(0xFFF15C6D),
                  ),
                  title: Text(
                    'Report ${user.username}',
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
  final UserModel user;

  final double maxHeaderHeight = 180;
  final double minHeaderHeight = kToolbarHeight + 20;
  final double maxImageSize = 130;
  final double minImageSize = 40;

  SliverPersistentDelegate(this.user);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final size = MediaQuery.of(context).size;
    final percent = shrinkOffset / (maxHeaderHeight - 35);
    final percent2 = shrinkOffset / (maxHeaderHeight);
    final currentImageSize = (maxImageSize * (1 - percent)).clamp(
      minImageSize,
      maxImageSize,
    );
    final currentImagePosition = ((size.width / 2 - 65) * (1 - percent)).clamp(
      minImageSize,
      maxImageSize,
    );
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
              left: currentImagePosition + 50,
              child: Text(
                user.username,
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
            Positioned(
              left: currentImagePosition,
              top: MediaQuery.of(context).viewPadding.top + 5,
              bottom: 0,
              child: Hero(
                tag: 'profile',
                child: Container(
                  width: currentImageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        user.profileImageUrl ?? '',
                      ),
                    ),
                  ),
                ),
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
