import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as geo;
import 'package:photo_link_vr/features/photos/data/local_photo_repository.dart';

void main() {
  test('groups nearby photos by area type when count reaches two', () {
    final groups = buildPhotoAreaGroups(
      const [
        PhotoMapItem(
          areaType: PhotoAreaType.school,
          position: geo.LatLng(31.2986, 121.5032),
          title: '学校照片 1',
        ),
        PhotoMapItem(
          areaType: PhotoAreaType.school,
          position: geo.LatLng(31.2994, 121.5040),
          title: '学校照片 2',
        ),
        PhotoMapItem(
          areaType: PhotoAreaType.attraction,
          position: geo.LatLng(31.2397, 121.4998),
          title: '景点照片 1',
        ),
      ],
    );

    expect(groups, hasLength(2));
    expect(groups.first.areaType, PhotoAreaType.school);
    expect(groups.first.isCluster, isTrue);
    expect(groups.first.items, hasLength(2));
    expect(groups.last.areaType, PhotoAreaType.attraction);
    expect(groups.last.isCluster, isFalse);
  });
}
