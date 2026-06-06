import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

final triRingAgentProvider = Provider<TriRingAgent>((ref) {
  return LocalTriRingAgent();
});

final remoteTriRingAgentProvider = Provider<TriRingAgent>((ref) {
  return RemoteTriRingAgent(ref.watch(apiClientProvider));
});

final triRingAgentPlanProvider = FutureProvider.autoDispose
    .family<TriRingAgentPlan, TriRingAgentRequest>((ref, request) {
  return ref.watch(triRingAgentProvider).compose(request);
});

abstract interface class TriRingAgent {
  Future<TriRingAgentPlan> compose(TriRingAgentRequest request);
}

@immutable
class TriRingAgentRequest {
  const TriRingAgentRequest({
    required this.selectedPhotos,
    required this.socialEnabled,
  });

  final List<TriRingAgentPhoto> selectedPhotos;
  final bool socialEnabled;

  String get selectedPhotoKey =>
      selectedPhotos.map((photo) => photo.id).join('|');

  Map<String, Object?> toJson() {
    return {
      'socialEnabled': socialEnabled,
      'selectedPhotos': [
        for (final photo in selectedPhotos) photo.toJson(),
      ],
    };
  }

  @override
  bool operator ==(Object other) {
    return other is TriRingAgentRequest &&
        other.socialEnabled == socialEnabled &&
        other.selectedPhotoKey == selectedPhotoKey;
  }

  @override
  int get hashCode => Object.hash(socialEnabled, selectedPhotoKey);
}

@immutable
class TriRingAgentPhoto {
  const TriRingAgentPhoto({
    required this.albumName,
    required this.createdAt,
    required this.id,
    required this.title,
  });

  final String albumName;
  final DateTime createdAt;
  final String id;
  final String title;

  Map<String, Object?> toJson() {
    return {
      'albumName': albumName,
      'createdAt': createdAt.toIso8601String(),
      'id': id,
      'title': title,
    };
  }
}

@immutable
class TriRingAgentPlan {
  const TriRingAgentPlan({
    required this.guidance,
    required this.headline,
    required this.readiness,
    required this.rings,
  });

  final String guidance;
  final String headline;
  final TriRingReadiness readiness;
  final List<TriRingSlotPlan> rings;

  factory TriRingAgentPlan.fromJson(Map<String, Object?> json) {
    final ringsJson = json['rings'];
    return TriRingAgentPlan(
      guidance: json['guidance'] as String? ?? '智能体已返回三色环建议。',
      headline: json['headline'] as String? ?? '三色环智能体',
      readiness: TriRingReadiness.fromName(json['readiness'] as String?),
      rings: [
        if (ringsJson is List)
          for (final ring in ringsJson)
            if (ring is Map<String, Object?>) TriRingSlotPlan.fromJson(ring),
      ],
    );
  }
}

@immutable
class TriRingSlotPlan {
  const TriRingSlotPlan({
    required this.colorName,
    required this.insight,
    required this.name,
    this.photoTitle,
  });

  final String colorName;
  final String insight;
  final String name;
  final String? photoTitle;

  factory TriRingSlotPlan.fromJson(Map<String, Object?> json) {
    return TriRingSlotPlan(
      colorName: json['colorName'] as String? ?? '默认',
      insight: json['insight'] as String? ?? '等待智能体补充说明。',
      name: json['name'] as String? ?? '三色环',
      photoTitle: json['photoTitle'] as String?,
    );
  }
}

enum TriRingReadiness {
  disabled,
  waitingForPhotos,
  incomplete,
  ready;

  static TriRingReadiness fromName(String? name) {
    return TriRingReadiness.values.firstWhere(
      (value) => value.name == name,
      orElse: () => TriRingReadiness.incomplete,
    );
  }
}

class LocalTriRingAgent implements TriRingAgent {
  @override
  Future<TriRingAgentPlan> compose(TriRingAgentRequest request) async {
    if (!request.socialEnabled) {
      return const TriRingAgentPlan(
        guidance: '开启后智能体会读取所选照片标题、相册和时间，生成三色环建议。',
        headline: '智能体接口待命',
        readiness: TriRingReadiness.disabled,
        rings: _emptyRings,
      );
    }

    if (request.selectedPhotos.isEmpty) {
      return const TriRingAgentPlan(
        guidance: '请选择 1 到 3 张照片，智能体会先建立个人三色环草稿。',
        headline: '等待照片输入',
        readiness: TriRingReadiness.waitingForPhotos,
        rings: _emptyRings,
      );
    }

    final rings = _ringNames.indexed.map((entry) {
      final index = entry.$1;
      final ring = entry.$2;
      final photo = index < request.selectedPhotos.length
          ? request.selectedPhotos[index]
          : null;

      return TriRingSlotPlan(
        colorName: _ringColors[index],
        insight: photo == null
            ? '继续选择照片来补齐这个环。'
            : '来自「${photo.albumName}」，可作为 ${ring.name} 的社交记忆锚点。',
        name: ring.name,
        photoTitle: photo?.title,
      );
    }).toList();

    final isReady = request.selectedPhotos.length == 3;

    return TriRingAgentPlan(
      guidance: isReady
          ? '三色环已成型，可继续接入真实智能体做关系摘要、分享建议和 NFC 权限策略。'
          : '当前为智能体草稿，建议补齐 3 张照片后生成完整三色环。',
      headline: isReady ? '三色环智能体已生成' : '三色环智能体草稿',
      readiness: isReady ? TriRingReadiness.ready : TriRingReadiness.incomplete,
      rings: rings,
    );
  }

  static const _emptyRings = [
    TriRingSlotPlan(
      colorName: '蓝色',
      insight: '等待选择照片。',
      name: '自我环',
    ),
    TriRingSlotPlan(
      colorName: '红色',
      insight: '等待选择照片。',
      name: '关系环',
    ),
    TriRingSlotPlan(
      colorName: '黄色',
      insight: '等待选择照片。',
      name: '场景环',
    ),
  ];

  static const _ringColors = ['蓝色', '红色', '黄色'];
  static const _ringNames = [
    (name: '自我环'),
    (name: '关系环'),
    (name: '场景环'),
  ];
}

class RemoteTriRingAgent implements TriRingAgent {
  const RemoteTriRingAgent(this._client);

  final Dio _client;

  static const endpoint = '/agents/personal-tri-ring/social';

  @override
  Future<TriRingAgentPlan> compose(TriRingAgentRequest request) async {
    final response = await _client.post<Map<String, Object?>>(
      endpoint,
      data: request.toJson(),
    );
    return TriRingAgentPlan.fromJson(response.data ?? const {});
  }
}
