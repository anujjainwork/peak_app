class VideoModel {
  final String id;
  final DateTime creationDate;
  final String videoLocalPath;
  final String thumbnailLocalPath;
  final String? videothumnailgroup; // comma-separated list of thumbnail paths

  VideoModel({
    required this.id,
    required this.videoLocalPath,
    required this.thumbnailLocalPath,
    required this.creationDate,
    this.videothumnailgroup,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'videoLocalPath': videoLocalPath,
      'mainthumbnailLocalPath': thumbnailLocalPath,
      'creationDate': creationDate.toIso8601String(),
      'videothumnailgroup': videothumnailgroup,
    };
  }

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['id'],
      videoLocalPath: map['videoLocalPath'],
      thumbnailLocalPath: map['mainthumbnailLocalPath'],
      creationDate: DateTime.parse(map['creationDate']),
      videothumnailgroup: map['videothumnailgroup'],
    );
  }
}