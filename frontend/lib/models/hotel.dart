class Hotel {
  final int id;
  final int tripId;
  final String hotelName;
  final String? city;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? confirmationNo;
  final double amount;
  final String? bookingImageUrl;
  final String? notes;

  Hotel({
    required this.id,
    required this.tripId,
    required this.hotelName,
    this.city,
    this.checkIn,
    this.checkOut,
    this.confirmationNo,
    required this.amount,
    this.bookingImageUrl,
    this.notes,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'],
      tripId: json['trip_id'],
      hotelName: json['hotel_name'],
      city: json['city'],
      checkIn: json['check_in'] != null ? DateTime.parse(json['check_in']) : null,
      checkOut: json['check_out'] != null ? DateTime.parse(json['check_out']) : null,
      confirmationNo: json['confirmation_no'],
      amount: double.parse(json['amount'].toString()),
      bookingImageUrl: json['booking_image_url'],
      notes: json['notes'],
    );
  }
}
