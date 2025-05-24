import 'package:peak_app/video/data/db/video_db.dart';
import 'package:peak_app/video/domain/models/video_model.dart';

class VideoRepository {
  static final VideoRepository _instance = VideoRepository._internal();
  factory VideoRepository() => _instance;
  VideoRepository._internal();

  Future<void> addVideo(VideoModel video) async {
    await VideoDatabase.instance.insertVideo(video);
  }

  Future<List<VideoModel>> fetchAllVideos() async {
    return await VideoDatabase.instance.getAllVideos();
  }

  Future<void> deleteVideoById(String id) async {
    await VideoDatabase.instance.deleteVideo(id);
  }

  Future<void> close() async {
    await VideoDatabase.instance.close();
  }
}