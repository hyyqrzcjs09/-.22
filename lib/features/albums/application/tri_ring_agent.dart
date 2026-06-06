import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

const triRingMinPhotosPerRing = 3;
const triRingMaxPhotosPerRing = 10;

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

enum TriRingType {
  self('self', '自我环', '蓝色'),
  relationship('relationship', '关系环', '红色'),
  scene('scene', '场景环', '黄色');

  const TriRingType(this.apiName, this.label, this.colorName);

  final String apiName;
  final String colorName;
  final String label;

  static TriRingType fromName(String? name) {
    return TriRingType.values.firstWhere(
      (value) => value.apiName == name || value.name == name,
      orElse: () => TriRingType.self,
    );
  }
}

@immutable
class TriRingAgentRequest {
  const TriRingAgentRequest({
    required this.rings,
    required this.socialEnabled,
  });

  final List<TriRingPhotoSelection> rings;
  final bool socialEnabled;

  String get selectionKey {
    return rings
        .map(
          (ring) =>
              '${ring.type.apiName}:${ring.photos.map((photo) => photo.id).join(',')}',
        )
        .join('|');
  }

  bool get hasAnyPhoto => rings.any((ring) => ring.photos.isNotEmpty);

  bool get isComplete {
    return rings.every(
      (ring) =>
          ring.photos.length >= triRingMinPhotosPerRing &&
          ring.photos.length <= triRingMaxPhotosPerRing,
    );
  }

  int selectedCountFor(TriRingType type) {
    return rings
        .firstWhere(
          (ring) => ring.type == type,
          orElse: () => TriRingPhotoSelection(type: type, photos: const []),
        )
        .photos
        .length;
  }

  Map<String, Object?> toJson() {
    return {
      'socialEnabled': socialEnabled,
      'minPhotosPerRing': triRingMinPhotosPerRing,
      'maxPhotosPerRing': triRingMaxPhotosPerRing,
      'rings': [
        for (final ring in rings) ring.toJson(),
      ],
    };
  }

  @override
  bool operator ==(Object other) {
    return other is TriRingAgentRequest &&
        other.socialEnabled == socialEnabled &&
        other.selectionKey == selectionKey;
  }

  @override
  int get hashCode => Object.hash(socialEnabled, selectionKey);
}

@immutable
class TriRingPhotoSelection {
  const TriRingPhotoSelection({
    required this.photos,
    required this.type,
  });

  final List<TriRingAgentPhoto> photos;
  final TriRingType type;

  Map<String, Object?> toJson() {
    return {
      'type': type.apiName,
      'label': type.label,
      'colorName': type.colorName,
      'photos': [
        for (final photo in photos) photo.toJson(),
      ],
    };
  }
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
    required this.imageAnalyses,
    required this.matches,
    required this.profile,
    required this.readiness,
    required this.rings,
  });

  final String guidance;
  final String headline;
  final List<TriRingImageAnalysis> imageAnalyses;
  final List<TriRingMatchSuggestion> matches;
  final TriRingUserProfile profile;
  final TriRingReadiness readiness;
  final List<TriRingSlotPlan> rings;

  factory TriRingAgentPlan.fromJson(Map<String, Object?> json) {
    final ringsJson = json['rings'];
    final analysesJson = json['imageAnalyses'];
    final matchesJson = json['matches'];
    final profileJson = json['profile'];

    return TriRingAgentPlan(
      guidance: json['guidance'] as String? ?? '智能体已返回三色环建议。',
      headline: json['headline'] as String? ?? '三色环智能体',
      imageAnalyses: [
        if (analysesJson is List)
          for (final analysis in analysesJson)
            if (analysis is Map<String, Object?>)
              TriRingImageAnalysis.fromJson(analysis),
      ],
      matches: [
        if (matchesJson is List)
          for (final match in matchesJson)
            if (match is Map<String, Object?>)
              TriRingMatchSuggestion.fromJson(match),
      ],
      profile: profileJson is Map<String, Object?>
          ? TriRingUserProfile.fromJson(profileJson)
          : TriRingUserProfile.empty,
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
    required this.selectedCount,
    required this.type,
  });

  final String colorName;
  final String insight;
  final String name;
  final int selectedCount;
  final TriRingType type;

  factory TriRingSlotPlan.fromJson(Map<String, Object?> json) {
    return TriRingSlotPlan(
      colorName: json['colorName'] as String? ?? '默认',
      insight: json['insight'] as String? ?? '等待智能体补充说明。',
      name: json['name'] as String? ?? '三色环',
      selectedCount: json['selectedCount'] as int? ?? 0,
      type: TriRingType.fromName(json['type'] as String?),
    );
  }
}

@immutable
class TriRingImageAnalysis {
  const TriRingImageAnalysis({
    required this.emotionTag,
    required this.photoTitle,
    required this.ringName,
    required this.visualSignal,
  });

  final String emotionTag;
  final String photoTitle;
  final String ringName;
  final String visualSignal;

  factory TriRingImageAnalysis.fromJson(Map<String, Object?> json) {
    return TriRingImageAnalysis(
      emotionTag: json['emotionTag'] as String? ?? '平衡',
      photoTitle: json['photoTitle'] as String? ?? '照片',
      ringName: json['ringName'] as String? ?? '三色环',
      visualSignal: json['visualSignal'] as String? ?? '等待图片分析。',
    );
  }
}

@immutable
class TriRingUserProfile {
  const TriRingUserProfile({
    required this.matchingVector,
    required this.persona,
    required this.traits,
  });

  final String matchingVector;
  final String persona;
  final List<String> traits;

  static const empty = TriRingUserProfile(
    matchingVector: '等待三色环完整后生成匹配向量。',
    persona: '画像待生成',
    traits: [],
  );

  factory TriRingUserProfile.fromJson(Map<String, Object?> json) {
    final traitsJson = json['traits'];
    return TriRingUserProfile(
      matchingVector: json['matchingVector'] as String? ?? '等待三色环完整后生成匹配向量。',
      persona: json['persona'] as String? ?? '画像待生成',
      traits: [
        if (traitsJson is List)
          for (final trait in traitsJson)
            if (trait is String) trait,
      ],
    );
  }
}

@immutable
class TriRingMatchSuggestion {
  const TriRingMatchSuggestion({
    required this.reason,
    required this.score,
    required this.title,
  });

  final String reason;
  final int score;
  final String title;

  factory TriRingMatchSuggestion.fromJson(Map<String, Object?> json) {
    return TriRingMatchSuggestion(
      reason: json['reason'] as String? ?? '等待匹配系统返回原因。',
      score: json['score'] as int? ?? 0,
      title: json['title'] as String? ?? '匹配建议',
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
      return TriRingAgentPlan(
        guidance: '开启后智能体会按三色环读取照片，生成图片分析、用户画像和匹配建议。',
        headline: '智能体接口待命',
        imageAnalyses: const [],
        matches: const [],
        profile: TriRingUserProfile.empty,
        readiness: TriRingReadiness.disabled,
        rings: _emptyRings,
      );
    }

    if (!request.hasAnyPhoto) {
      return TriRingAgentPlan(
        guidance:
            '每个环需要选择 $triRingMinPhotosPerRing-$triRingMaxPhotosPerRing 张照片。',
        headline: '等待照片输入',
        imageAnalyses: const [],
        matches: const [],
        profile: TriRingUserProfile.empty,
        readiness: TriRingReadiness.waitingForPhotos,
        rings: _ringsFromRequest(request),
      );
    }

    final complete = request.isComplete;
    final analyses = _buildImageAnalyses(request);
    final profile = _buildProfile(request, complete);
    final matches =
        complete ? _buildMatches(request) : const <TriRingMatchSuggestion>[];

    return TriRingAgentPlan(
      guidance: complete
          ? '三色环已达到分析要求，后台可用该结构生成用户画像并进入匹配系统。'
          : '请把每个环补齐到至少 $triRingMinPhotosPerRing 张照片，补齐后生成完整画像和匹配结果。',
      headline: complete ? '画像与匹配已生成' : '三色环分析草稿',
      imageAnalyses: analyses,
      matches: matches,
      profile: profile,
      readiness:
          complete ? TriRingReadiness.ready : TriRingReadiness.incomplete,
      rings: _ringsFromRequest(request),
    );
  }

  static List<TriRingSlotPlan> _ringsFromRequest(TriRingAgentRequest request) {
    return [
      for (final type in TriRingType.values)
        TriRingSlotPlan(
          colorName: type.colorName,
          insight: _insightFor(type, request.selectedCountFor(type)),
          name: type.label,
          selectedCount: request.selectedCountFor(type),
          type: type,
        ),
    ];
  }

  static String _insightFor(TriRingType type, int count) {
    if (count == 0) {
      return '等待选择 $triRingMinPhotosPerRing-$triRingMaxPhotosPerRing 张照片。';
    }
    if (count < triRingMinPhotosPerRing) {
      return '已选择 $count 张，还需要补齐到至少 $triRingMinPhotosPerRing 张。';
    }
    return '已达到基础分析要求，可继续补充到 $triRingMaxPhotosPerRing 张提升画像稳定度。';
  }

  static List<TriRingImageAnalysis> _buildImageAnalyses(
    TriRingAgentRequest request,
  ) {
    return [
      for (final ring in request.rings)
        for (final photo in ring.photos.take(2))
          TriRingImageAnalysis(
            emotionTag: _emotionFor(ring.type),
            photoTitle: photo.title,
            ringName: ring.type.label,
            visualSignal:
                '识别「${photo.albumName}」中的时间、主题和社交语境，作为 ${ring.type.label} 的图片分析输入。',
          ),
    ];
  }

  static TriRingUserProfile _buildProfile(
    TriRingAgentRequest request,
    bool complete,
  ) {
    final total = request.rings.fold<int>(
      0,
      (sum, ring) => sum + ring.photos.length,
    );
    return TriRingUserProfile(
      matchingVector: complete
          ? 'tri-ring:${request.selectionKey.hashCode.abs()}'
          : '草稿向量：已采集 $total 张照片',
      persona: complete ? '稳定型社交记忆用户' : '三色环画像草稿',
      traits: [
        '重视照片记忆',
        if (request.selectedCountFor(TriRingType.relationship) >=
            triRingMinPhotosPerRing)
          '关系表达清晰',
        if (request.selectedCountFor(TriRingType.scene) >=
            triRingMinPhotosPerRing)
          '场景偏好明确',
        if (request.selectedCountFor(TriRingType.self) >=
            triRingMinPhotosPerRing)
          '自我叙事完整',
      ],
    );
  }

  static List<TriRingMatchSuggestion> _buildMatches(
    TriRingAgentRequest request,
  ) {
    final sceneCount = request.selectedCountFor(TriRingType.scene);
    final relationCount = request.selectedCountFor(TriRingType.relationship);
    return [
      TriRingMatchSuggestion(
        reason: '三色环完整度高，适合匹配相似照片记录频率的用户。',
        score: 92,
        title: '相似记忆节奏',
      ),
      TriRingMatchSuggestion(
        reason: sceneCount >= relationCount
            ? '场景环内容更强，可优先匹配地点兴趣相近的人。'
            : '关系环内容更强，可优先匹配社交互动偏好相近的人。',
        score: 86,
        title: sceneCount >= relationCount ? '地点偏好匹配' : '关系偏好匹配',
      ),
    ];
  }

  static String _emotionFor(TriRingType type) {
    return switch (type) {
      TriRingType.self => '自我表达',
      TriRingType.relationship => '亲密连接',
      TriRingType.scene => '地点氛围',
    };
  }

  static final _emptyRings = [
    for (final type in TriRingType.values)
      TriRingSlotPlan(
        colorName: type.colorName,
        insight: '等待选择照片。',
        name: type.label,
        selectedCount: 0,
        type: type,
      ),
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
