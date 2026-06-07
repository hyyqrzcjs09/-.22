import 'package:flutter_test/flutter_test.dart';
import 'package:photo_link_vr/features/albums/application/tri_ring_agent.dart';

void main() {
  test('local tri-ring agent composes a ready social plan', () async {
    final agent = LocalTriRingAgent();

    final plan = await agent.compose(
      TriRingAgentRequest(
        socialEnabled: true,
        rings: [
          for (final type in TriRingType.values)
            TriRingPhotoSelection(
              type: type,
              photos: [
                for (var index = 0; index < 3; index++)
                  TriRingAgentPhoto(
                    albumName: '家庭',
                    createdAt: DateTime(2026, 6, 6 - index),
                    id: '${type.name}-photo-$index',
                    title: '${type.label}照片 ${index + 1}',
                  ),
              ],
            ),
        ],
      ),
    );

    expect(plan.readiness, TriRingReadiness.ready);
    expect(plan.headline, '画像与匹配已生成');
    expect(plan.rings, hasLength(3));
    expect(plan.rings.first.selectedCount, 3);
    expect(plan.imageAnalyses, isNotEmpty);
    expect(plan.profile.persona, '稳定型社交记忆用户');
    expect(plan.matches, isNotEmpty);
  });

  test('fallback tri-ring agent uses local plan when remote fails', () async {
    final agent = FallbackTriRingAgent(
      local: LocalTriRingAgent(),
      remote: _FailingTriRingAgent(),
    );

    final plan = await agent.compose(
      TriRingAgentRequest(
        socialEnabled: true,
        rings: [
          for (final type in TriRingType.values)
            TriRingPhotoSelection(
              type: type,
              photos: [
                for (var index = 0; index < 3; index++)
                  TriRingAgentPhoto(
                    albumName: '家庭',
                    createdAt: DateTime(2026, 6, 6 - index),
                    id: '${type.name}-fallback-$index',
                    title: '${type.label}照片 ${index + 1}',
                  ),
              ],
            ),
        ],
      ),
    );

    expect(plan.readiness, TriRingReadiness.ready);
    expect(plan.headline, '画像与匹配已生成');
    expect(plan.matches.every((match) => match.score >= 70), isTrue);
  });
}

class _FailingTriRingAgent implements TriRingAgent {
  @override
  Future<TriRingAgentPlan> compose(TriRingAgentRequest request) {
    throw StateError('remote unavailable');
  }
}
