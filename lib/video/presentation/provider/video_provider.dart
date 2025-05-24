import 'package:flutter/material.dart';
import 'package:peak_app/video/data/remote/video_mock_api.dart';
import 'package:peak_app/video/domain/models/video_model.dart';
import 'package:peak_app/video/data/db/video_repository.dart';
import 'package:peak_app/video/domain/services/thumbnail_generator.dart';

class VideoProvider extends ChangeNotifier {
  final VideoRepository _repository;
  final MockApiService _apiService;

  List<VideoModel> _videos = [];
  bool _isLoading = false;

  List<VideoModel> get videos => _videos;
  bool get isLoading => _isLoading;

  VideoProvider(this._repository) : _apiService = MockApiService(_repository);

  Future<void> loadVideosFromDb() async {
    _isLoading = true;
    notifyListeners();

    _videos = await _repository.fetchAllVideos();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchFromMockApiAndSave() async {
    _isLoading = true;
    notifyListeners();

    await _apiService.fetchAndStoreMockVideos();

    _videos = await _repository.fetchAllVideos();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> generateAndSaveThumbnails(VideoModel video) async {
    if (video.videothumnailgroup == null) {
      final thumbs = await generateThumbnails(
          videoPath: video.videoLocalPath, videoId: video.id);
      final thumbString = thumbs.join(',');
      final updatedVideo = VideoModel(
        id: video.id,
        videoLocalPath: video.videoLocalPath,
        thumbnailLocalPath: video.thumbnailLocalPath,
        creationDate: video.creationDate,
        videothumnailgroup: thumbString,
      );
      await _repository.addVideo(updatedVideo);
      await loadVideosFromDb();
    }
  }
}
