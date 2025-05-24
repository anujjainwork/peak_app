import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:peak_app/video/domain/models/video_model.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerWidget({super.key, required this.video});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  Duration _currentPosition = Duration.zero;
  Duration? _dragPosition;
  bool _isDragging = false;

  List<String> thumbnails = [];
  File? _lastValidThumbnailFile;
  late List<int> _validThumbnailIndexes;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.video.videoLocalPath))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _controller.play();
          _controller.addListener(_updatePosition);
        });
      });

    if (widget.video.videothumnailgroup != null) {
      thumbnails = widget.video.videothumnailgroup!.split(',');
      _validThumbnailIndexes = [];

      for (int i = 0; i < thumbnails.length; i++) {
        final file = File(thumbnails[i]);
        if (file.existsSync()) {
          _validThumbnailIndexes.add(i);
        }
      }
    } else {
      _validThumbnailIndexes = [];
    }
  }

  void _updatePosition() {
    if (_controller.value.isInitialized && !_isDragging) {
      setState(() {
        _currentPosition = _controller.value.position;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final path in thumbnails) {
      final file = File(path);
      if (file.existsSync()) {
        precacheImage(FileImage(file), context);
      } else {
        print('Missing thumbnail at path: $path');
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updatePosition);
    _controller.dispose();
    super.dispose();
  }

  Widget _buildThumbnail(Duration? position,
      {double height = double.infinity}) {
    try {
      if (thumbnails.isEmpty || position == null) {
        throw Exception('No thumbnails or invalid position');
      }

      int posMs = position.inMilliseconds;
      posMs = posMs.isFinite && posMs >= 0 ? posMs : 0;

      int rawIndex = (posMs ~/ 30).clamp(0, thumbnails.length - 1);
      int validIndex = _getNearestValidIndex(rawIndex);

      if (validIndex != -1) {
        final file = File(thumbnails[validIndex]);
        _lastValidThumbnailFile = file;
        return Image.file(
          file,
          fit: BoxFit.cover,
          height: height,
          width: double.infinity,
        );
      }

      throw Exception('No valid thumbnail');
    } catch (e, stack) {
      print('Thumbnail render error: $e');
      print(stack);

      if (_lastValidThumbnailFile != null) {
        return Image.file(
          _lastValidThumbnailFile!,
          fit: BoxFit.cover,
          height: height,
          width: double.infinity,
        );
      }

      return Container(
        color: Colors.white,
        alignment: Alignment.center,
        height: height,
        child: const Text(
          'No Thumbnail',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxPosition = _controller.value.duration.inMilliseconds.toDouble();
    double sliderValRaw = _isDragging && _dragPosition != null
        ? _dragPosition!.inMilliseconds.toDouble()
        : _currentPosition.inMilliseconds.toDouble();

// Defensive clamp to avoid infinity or NaN:
    final sliderValue = (sliderValRaw.isFinite && sliderValRaw >= 0)
        ? sliderValRaw.clamp(0, maxPosition)
        : 0.0;

    final showThumbnailOverlay = _isDragging && _dragPosition != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Show thumbnail full screen when dragging, else show video player
                if (showThumbnailOverlay)
                  _buildThumbnail(_dragPosition!, height: double.infinity)
                else
                  VideoPlayer(_controller),

                // Floating thumbnail (optional)
                if (showThumbnailOverlay)
                  Positioned(
                    bottom: 100,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black,
                      ),
                      child: _buildThumbnail(_dragPosition!, height: 80),
                    ),
                  ),

                // Red slider
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.red,
                      inactiveTrackColor: Colors.red.withOpacity(0.3),
                      thumbColor: Colors.red,
                    ),
                    child: Slider(
                      value: sliderValue.clamp(0, maxPosition).toDouble(),
                      max: maxPosition,
                      onChangeStart: (_) {
                        _controller.pause();
                        setState(() => _isDragging = true);
                      },
                      onChanged: (value) {
                        final newPos = Duration(milliseconds: value.toInt());
                        setState(() {
                          _dragPosition = newPos;
                          _currentPosition = newPos;
                        });
                      },
                      onChangeEnd: (value) {
                        final newPos = Duration(milliseconds: value.toInt());
                        _controller.seekTo(newPos);
                        _controller.play();
                        setState(() {
                          _isDragging = false;
                          _dragPosition = null;
                        });
                      },
                    ),
                  ),
                ),

                // Play/pause button
                Positioned(
                  left: 16,
                  bottom: 64,
                  child: IconButton(
                    iconSize: 40,
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  int _getNearestValidIndex(int desiredIndex) {
    for (int i = desiredIndex; i >= 0; i--) {
      if (_validThumbnailIndexes.contains(i)) return i;
    }
    return _validThumbnailIndexes.isNotEmpty
        ? _validThumbnailIndexes.first
        : -1;
  }
}
