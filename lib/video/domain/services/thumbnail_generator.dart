import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

Future<List<String>> generateThumbnails({
  required String videoPath,
  required String videoId,
  Duration interval = const Duration(milliseconds: 30),
}) async {
  final List<String> paths = [];
  final Directory appDir = await getApplicationDocumentsDirectory();
  final Directory thumbDir = Directory('${appDir.path}/thumbnails/$videoId');
  if (!await thumbDir.exists()) await thumbDir.create(recursive: true);

  final controller = VideoPlayerController.file(File(videoPath));
  await controller.initialize();
  final duration = controller.value.duration;
  await controller.dispose();

  for (int ms = 0;
      ms < duration.inMilliseconds;
      ms += interval.inMilliseconds) {
    final thumbPath = '${thumbDir.path}/thumb_${ms}ms.jpg';
    final thumbFile = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      timeMs: ms,
      thumbnailPath: thumbPath,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );
    if (thumbFile != null) {
      paths.add(thumbFile);
    }
  }

  return paths;
}