import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:peak_app/video/domain/models/video_model.dart';
import 'dart:io';

import 'package:peak_app/video/data/db/video_repository.dart';
import 'package:peak_app/video/domain/services/thumbnail_generator.dart';
import 'package:uuid/uuid.dart';

class MockApiService {
  final VideoRepository _repository;
  final _uuid = const Uuid();

  MockApiService(this._repository);

  Future<void> fetchAndStoreMockVideos() async {
    final jsonString = await rootBundle.loadString('assets/mock_data.json');
    final List<dynamic> jsonList = json.decode(jsonString);

    final dir = await getApplicationDocumentsDirectory();

    for (var entry in jsonList) {
      final String base64Video = entry['video'];
      final String base64Thumbnail = entry['thumbnail'];
      final String createdTime = entry['createdTime'];

      final String id = _uuid.v4();
      final String videoPath = '${dir.path}/$id.mp4';
      final String thumbnailPath = '${dir.path}/$id.jpg';

      // Decode and save files
      await File(videoPath).writeAsBytes(base64Decode(base64Video));
      await File(thumbnailPath).writeAsBytes(base64Decode(base64Thumbnail));

      final model = VideoModel(
        id: id,
        videoLocalPath: videoPath,
        thumbnailLocalPath: thumbnailPath,
        creationDate: DateTime.parse(createdTime),
      );

      await _repository.addVideo(model);

      await _generateAndSaveThumbnails(model);
    }

    await loadVideosFromDb();
  }

  Future<void> _generateAndSaveThumbnails(VideoModel video) async {
    if (video.videothumnailgroup == null) {
      final thumbs = await generateThumbnails(
        videoPath: video.videoLocalPath,
        videoId: video.id,
      );

      final thumbString = thumbs.join(',');
      final updatedVideo = VideoModel(
        id: video.id,
        videoLocalPath: video.videoLocalPath,
        thumbnailLocalPath: video.thumbnailLocalPath,
        creationDate: video.creationDate,
        videothumnailgroup: thumbString,
      );

      await _repository.addVideo(updatedVideo);
    }
  }

  Future<void> loadVideosFromDb() async {
    await _repository.fetchAllVideos();
  }
}
