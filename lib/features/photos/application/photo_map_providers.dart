import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_photo_repository.dart';

final localPhotoRepositoryProvider = Provider<LocalPhotoRepository>((ref) {
  return LocalPhotoRepository();
});

final photoMapProvider = FutureProvider.autoDispose<PhotoMapLoadResult>((ref) {
  return ref.watch(localPhotoRepositoryProvider).loadPhotoMap();
});
