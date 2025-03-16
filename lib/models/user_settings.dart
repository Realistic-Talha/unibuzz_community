class UserSettings {
  final bool emailNotifications;
  final bool pushNotifications;
  final Map<String, bool> categorySubscriptions;
  final List<String> mutedUsers;
  final List<String> blockedUsers; // Add this field

  UserSettings({
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.categorySubscriptions = const {},
    this.mutedUsers = const [],
    this.blockedUsers = const [], // Initialize blocked users
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      emailNotifications: map['emailNotifications'] ?? true,
      pushNotifications: map['pushNotifications'] ?? true,
      categorySubscriptions: Map<String, bool>.from(map['categorySubscriptions'] ?? {}),
      mutedUsers: List<String>.from(map['mutedUsers'] ?? []),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []), // Parse blocked users
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'categorySubscriptions': categorySubscriptions,
      'mutedUsers': mutedUsers,
      'blockedUsers': blockedUsers, // Include blocked users in map
    };
  }

  UserSettings copyWith({
    bool? emailNotifications,
    bool? pushNotifications,
    Map<String, bool>? categorySubscriptions,
    List<String>? mutedUsers,
    List<String>? blockedUsers, // Add to copyWith
  }) {
    return UserSettings(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      categorySubscriptions: categorySubscriptions ?? this.categorySubscriptions,
      mutedUsers: mutedUsers ?? this.mutedUsers,
      blockedUsers: blockedUsers ?? this.blockedUsers, // Include in new instance
    );
  }
}
