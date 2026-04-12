class TripPin {
  final int id;
  final int tripId;
  final int addedBy;
  final String pinType;
  final String? title;
  final double latitude;
  final double longitude;
  final String? address;
  final int pinOrder;
  final DateTime pinnedAt;

  TripPin({
    required this.id,
    required this.tripId,
    required this.addedBy,
    required this.pinType,
    this.title,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.pinOrder,
    required this.pinnedAt,
  });

  factory TripPin.fromJson(Map<String, dynamic> json) {
    return TripPin(
      id: json['id'],
      tripId: json['trip_id'],
      addedBy: json['added_by'],
      pinType: json['pin_type'],
      title: json['title'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      address: json['address'],
      pinOrder: json['pin_order'] ?? 0,
      pinnedAt: DateTime.parse(json['pinned_at']),
    );
  }
}
