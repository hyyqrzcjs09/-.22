import 'package:flutter/foundation.dart';

class MemoryClip {
  const MemoryClip({
    required this.date,
    required this.title,
  });

  final DateTime date;
  final String title;
}

class MemoryVideo {
  const MemoryVideo({
    required this.albumName,
    required this.clips,
    required this.createdAt,
    required this.id,
  });

  final String albumName;
  final List<MemoryClip> clips;
  final DateTime createdAt;
  final String id;

  int get durationSeconds => clips.length * 4;
}

class MemoryVideoStore extends ChangeNotifier {
  MemoryVideoStore._();

  static final instance = MemoryVideoStore._();

  final _videos = <MemoryVideo>[];

  List<MemoryVideo> get videos => List.unmodifiable(_videos);

  MemoryVideo addFromAlbum({
    required String albumName,
    required List<MemoryClip> clips,
  }) {
    final now = DateTime.now();
    final video = MemoryVideo(
      albumName: albumName,
      clips: List.unmodifiable(clips),
      createdAt: now,
      id: '${albumName}_${now.microsecondsSinceEpoch}',
    );

    _videos.insert(0, video);
    notifyListeners();
    return video;
  }

  @visibleForTesting
  void clearForTesting() {
    _videos.clear();
    notifyListeners();
  }
}
