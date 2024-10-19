import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/models/status_model.dart';
import 'package:tuyage/common/routes/routes.dart';
import 'package:tuyage/common/utils/coloors.dart';
import 'package:tuyage/feature/status/controller/status_controller.dart';

class StatusHomePage extends ConsumerStatefulWidget {
  const StatusHomePage({super.key});

  @override
  ConsumerState<StatusHomePage> createState() => _StatusHomePageState();
}

class _StatusHomePageState extends ConsumerState<StatusHomePage> {
  late Future<List<Status>> _statusFuture;

  @override
  void initState() {
    super.initState();
    _statusFuture = ref.read(statusControllerProvider).getStatus(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Status>>(
      future: _statusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Coloors.greenDark,
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading status: ${snapshot.error}',
              style: TextStyle(color: context.theme.greyColor),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No statuses available',
              style: TextStyle(color: context.theme.greyColor),
            ),
          );
        }

        // Afficher la liste des statuts si les données existent
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var statusData = snapshot.data![index];
            return Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.statusScreen,
                      arguments: statusData,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      title: Text(statusData.username),
                      leading: CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(
                          statusData.profilePic,
                        ),
                        radius: 30,
                      ),
                    ),
                  ),
                ),
                Divider(
                  color: context.theme.greyColor,
                  indent: 85,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
