class UserProfile {
  final String id;
  final String name;
  final String? profileImageUrl;
  final String? bio;
  final int level;
  final int completedOreums;
  final double totalDistance;
  final int totalStamps;
  final int badges;

  UserProfile({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.bio,
    this.level = 1,
    this.completedOreums = 0,
    this.totalDistance = 0.0,
    this.totalStamps = 0,
    this.badges = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '사용자',
      profileImageUrl: json['profile_image_url'] as String?,
      bio: json['bio'] as String?,
      level: json['level'] as int? ?? 1,
      completedOreums: json['completed_oreums'] as int? ?? 0,
      totalDistance: (json['total_distance'] as num?)?.toDouble() ?? 0.0,
      totalStamps: json['total_stamps'] as int? ?? 0,
      badges: json['badges'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profile_image_url': profileImageUrl,
      'bio': bio,
      'level': level,
      'completed_oreums': completedOreums,
      'total_distance': totalDistance,
      'total_stamps': totalStamps,
      'badges': badges,
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? profileImageUrl,
    String? bio,
    int? level,
    int? completedOreums,
    double? totalDistance,
    int? totalStamps,
    int? badges,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      level: level ?? this.level,
      completedOreums: completedOreums ?? this.completedOreums,
      totalDistance: totalDistance ?? this.totalDistance,
      totalStamps: totalStamps ?? this.totalStamps,
      badges: badges ?? this.badges,
    );
  }
}
