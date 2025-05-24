import 'dart:io';

import 'package:flutter/material.dart';
import 'package:peak_app/video/presentation/widget/video_player_widget.dart';
import 'package:provider/provider.dart';
import '../provider/video_provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();

    final videoProvider = context.read<VideoProvider>();
    // videoProvider.loadVideosFromDb();

    // Uncomment below if you want to fetch from mock api every launch:
    videoProvider.fetchFromMockApiAndSave();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Videos")),
      body: Consumer<VideoProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.videos.isEmpty) {
            return const Center(child: Text("No videos found"));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.videos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (context, index) {
              final video = provider.videos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => VideoPlayerWidget(video: video),
                  ));
                },
                child: Image.file(
                  File(video.thumbnailLocalPath),
                  fit: BoxFit.cover,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
