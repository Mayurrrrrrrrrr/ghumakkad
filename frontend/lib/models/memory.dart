class Memory {
  final int id;
  final int pinId;
  final String? pinTitle;
  final double? latitude;
  final double? longitude;
  final int addedBy;
  final String addedByName;
  final String? addedByAvatar;
  final String memoryType;
  final String? content;
  final String? caption;
  final DateTime? pinnedAt;
  final DateTime createdAt;

  Memory({
    required this.id,
    required this.pinId,
    this.pinTitle,
    this.latitude,
    this.longitude,
    required this.addedBy,
    required this.addedByName,
    this.addedByAvatar,
    required this.memoryType,
    this.content,
    this.caption,
    this.pinnedAt,
    required this.createdAt,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'],
      pinId: json['pin_id'],
      pinTitle: json['pin_title'],
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : null,
      addedBy: json['added_by'],
      addedByName: json['added_by_name'] ?? 'Unknown',
      addedByAvatar: json['added_by_avatar'],
      memoryType: json['memory_type'] ?? 'note',
      content: json['content'],
      caption: json['caption'],
      pinnedAt: json['pinned_at'] != null ? DateTime.parse(json['pinned_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
