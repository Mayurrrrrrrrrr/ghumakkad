class TripPin {
  final int id;
  final int tripId;
  final int addedBy;
  final String pinType;
  final String? title;
  final double latitude;
  final double longitude;
  final String? address;
  final String? notes;
  final String? photoUrl;
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
    this.notes,
    this.photoUrl,
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
      notes: json['notes'],
      photoUrl: json['photo_url'],
      pinOrder: json['pin_order'] ?? 0,
      pinnedAt: json['pinned_at'] != null 
          ? DateTime.parse(json['pinned_at']) 
          : DateTime.now(),
    );
  }
}
