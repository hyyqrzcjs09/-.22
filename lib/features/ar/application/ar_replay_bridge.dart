import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final arReplayBridgeProvider = Provider<ArReplayBridge>((ref) {
  return LocalArReplayBridge();
});

final unityArReplayBridgeProvider = Provider<ArReplayBridge>((ref) {
  return const UnityArReplayBridge();
});

abstract interface class ArReplayBridge {
  Future<ArReplayPlan> createReplay(ArReplayRequest request);
}

@immutable
class ArReplayRequest {
  const ArReplayRequest({
    required this.albumId,
    required this.albumName,
    required this.photos,
    required this.sceneAnchor,
  });

  final String albumId;
  final String albumName;
  final List<ArReplayPhoto> photos;
  final ArSceneAnchor sceneAnchor;

  Map<String, Object?> toJson() {
    return {
      'albumId': albumId,
      'albumName': albumName,
      'sceneAnchor': sceneAnchor.toJson(),
      'photos': [
        for (final photo in photos) photo.toJson(),
      ],
    };
  }
}

@immutable
class ArSceneAnchor {
  const ArSceneAnchor({
    required this.label,
    required this.sceneSignature,
  });

  final String label;
  final String sceneSignature;

  Map<String, Object?> toJson() {
    return {
      'label': label,
      'sceneSignature': sceneSignature,
    };
  }
}

@immutable
class ArReplayPhoto {
  const ArReplayPhoto({
    required this.createdAt,
    required this.id,
    required this.title,
  });

  final DateTime createdAt;
  final String id;
  final String title;

  Map<String, Object?> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'id': id,
      'title': title,
    };
  }
}

@immutable
class ArReplayPlan {
  const ArReplayPlan({
    required this.animationSummary,
    required this.overlays,
    required this.sceneMatched,
    required this.sceneMessage,
    required this.unityPayload,
  });

  final String animationSummary;
  final List<ArPhotoOverlay> overlays;
  final bool sceneMatched;
  final String sceneMessage;
  final Map<String, Object?> unityPayload;

  factory ArReplayPlan.fromJson(Map<String, Object?> json) {
    final overlaysJson = json['overlays'];
    final unityPayloadJson = json['unityPayload'];

    return ArReplayPlan(
      animationSummary: json['animationSummary'] as String? ?? 'AR 图片将以平滑动效重现。',
      overlays: [
        if (overlaysJson is List)
          for (final overlay in overlaysJson)
            if (overlay is Map<String, Object?>)
              ArPhotoOverlay.fromJson(overlay),
      ],
      sceneMatched: json['sceneMatched'] as bool? ?? false,
      sceneMessage: json['sceneMessage'] as String? ?? '等待同场景识别。',
      unityPayload: unityPayloadJson is Map<String, Object?>
          ? unityPayloadJson
          : const {},
    );
  }
}

@immutable
class ArPhotoOverlay {
  const ArPhotoOverlay({
    required this.animation,
    required this.depth,
    required this.photoTitle,
    required this.slot,
  });

  final ArPhotoAnimation animation;
  final double depth;
  final String photoTitle;
  final int slot;

  factory ArPhotoOverlay.fromJson(Map<String, Object?> json) {
    return ArPhotoOverlay(
      animation: ArPhotoAnimation.fromName(json['animation'] as String?),
      depth: (json['depth'] as num?)?.toDouble() ?? 1,
      photoTitle: json['photoTitle'] as String? ?? '照片',
      slot: json['slot'] as int? ?? 0,
    );
  }
}

enum ArPhotoAnimation {
  floatIn('浮现'),
  orbit('环绕'),
  parallax('景深漂移'),
  breathe('轻微呼吸');

  const ArPhotoAnimation(this.label);

  final String label;

  static ArPhotoAnimation fromName(String? name) {
    return ArPhotoAnimation.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ArPhotoAnimation.floatIn,
    );
  }
}

class LocalArReplayBridge implements ArReplayBridge {
  @override
  Future<ArReplayPlan> createReplay(ArReplayRequest request) async {
    final overlays = [
      for (var index = 0; index < request.photos.length; index++)
        ArPhotoOverlay(
          animation:
              ArPhotoAnimation.values[index % ArPhotoAnimation.values.length],
          depth: 0.8 + index * 0.16,
          photoTitle: request.photos[index].title,
          slot: index,
        ),
    ];

    return ArReplayPlan(
      animationSummary: '图片将按浮现、环绕、景深漂移和呼吸节奏动起来。',
      overlays: overlays,
      sceneMatched: request.photos.isNotEmpty,
      sceneMessage: request.photos.isEmpty
          ? '相册还没有照片，无法建立 AR 场景。'
          : '已用「${request.sceneAnchor.label}」建立同场景锚点，再次来到相同场景时可触发 AR 重现。',
      unityPayload: {
        'bridge': UnityArReplayBridge.channelName,
        'method': UnityArReplayBridge.createReplayMethod,
        ...request.toJson(),
        'overlays': [
          for (final overlay in overlays)
            {
              'animation': overlay.animation.name,
              'animationLabel': overlay.animation.label,
              'depth': overlay.depth,
              'photoTitle': overlay.photoTitle,
              'slot': overlay.slot,
            },
        ],
      },
    );
  }
}

class UnityArReplayBridge implements ArReplayBridge {
  const UnityArReplayBridge();

  static const channelName = 'photo_link_vr/unity_ar_replay';
  static const createReplayMethod = 'createArReplay';

  static const _channel = MethodChannel(channelName);

  @override
  Future<ArReplayPlan> createReplay(ArReplayRequest request) async {
    final response = await _channel.invokeMapMethod<String, Object?>(
      createReplayMethod,
      request.toJson(),
    );
    return ArReplayPlan.fromJson(response ?? const {});
  }
}
