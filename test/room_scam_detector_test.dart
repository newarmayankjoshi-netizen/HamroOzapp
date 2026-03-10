import 'package:hamro_oz/services/room_scam_detector_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quickAssess flags obvious scam patterns as high', () {
    final listing = RoomListingInput(
      title: 'Cheap room near station',
      suburb: 'Sydney',
      city: 'NSW',
      pricePerWeek: 80,
      roomType: 'Private',
      description:
          'No inspection allowed. Pay bond upfront today. Message on WhatsApp only.',
      address: '',
      photoUrls: const [],
    );

    final result = RoomScamDetectorService.quickAssess(listing);
    expect(result.likelihood, ScamLikelihood.high);
    expect(result.redFlags, isNotEmpty);
  });

  test('quickAssess stays low for normal listings', () {
    final listing = RoomListingInput(
      title: 'Private room in Parramatta',
      suburb: 'Parramatta',
      city: 'NSW',
      pricePerWeek: 260,
      roomType: 'Private',
      description:
          'Inspection welcome. Bond lodged with NSW Rental Bonds Online after agreement. Looking for tidy tenant.',
      address: '45 Church Street, Parramatta NSW',
      photoUrls: const ['https://example.com/photo.jpg'],
    );

    final result = RoomScamDetectorService.quickAssess(listing);
    expect(result.likelihood, ScamLikelihood.low);
  });
}
