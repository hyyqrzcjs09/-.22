import 'package:flutter_test/flutter_test.dart';
import 'package:photo_link_vr/features/albums/application/tri_ring_agent.dart';

void main() {
  test('local tri-ring agent composes a ready social plan', () async {
    final agent = LocalTriRingAgent();

    final plan = await agent.compose(
      TriRingAgentRequest(
        socialEnabled: true,
        selectedPhotos: [
          for (var index = 0; index < 3; index++)
            TriRingAgentPhoto(
              albumName: '家庭',
              createdAt: DateTime(2026, 6, 6 - index),
              id: 'photo-$index',
              title: '照片 ${index + 1}',
            ),
        ],
      ),
    );

    expect(plan.readiness, TriRingReadiness.ready);
    expect(plan.headline, '三色环智能体已生成');
    expect(plan.rings, hasLength(3));
    expect(plan.rings.first.photoTitle, '照片 1');
  });
}
