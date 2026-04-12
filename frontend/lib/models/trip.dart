class Trip {
  final int id;
  final String uuid;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final int creatorId;
  final String status;
  final String inviteCode;

  Trip({
    required this.id,
    required this.uuid,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.startDate,
    this.endDate,
    required this.creatorId,
    required this.status,
    required this.inviteCode,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      uuid: json['uuid'],
      title: json['title'],
      description: json['description'],
      coverImageUrl: json['cover_image_url'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      creatorId: json['creator_id'],
      status: json['status'],
      inviteCode: json['invite_code'],
    );
  }
}
