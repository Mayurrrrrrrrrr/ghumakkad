class Ticket {
  final int id;
  final int tripId;
  final String ticketType;
  final String fromPlace;
  final String toPlace;
  final DateTime? travelDate;
  final String? travelTime;
  final String? pnrNumber;
  final double amount;
  final String? ticketImageUrl;
  final String? notes;

  Ticket({
    required this.id,
    required this.tripId,
    required this.ticketType,
    required this.fromPlace,
    required this.toPlace,
    this.travelDate,
    this.travelTime,
    this.pnrNumber,
    required this.amount,
    this.ticketImageUrl,
    this.notes,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      tripId: json['trip_id'],
      ticketType: json['ticket_type'],
      fromPlace: json['from_place'],
      toPlace: json['to_place'],
      travelDate: json['travel_date'] != null ? DateTime.parse(json['travel_date']) : null,
      travelTime: json['travel_time'],
      pnrNumber: json['pnr_number'],
      amount: double.parse(json['amount'].toString()),
      ticketImageUrl: json['ticket_image_url'],
      notes: json['notes'],
    );
  }
}
