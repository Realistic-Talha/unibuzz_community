import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String? bio;
  final String? gender;
  final DateTime? birthDate;
  final String? phone;
  final String? location;
  final String? website;
  final Map<String, String> socialLinks;
  final List<String> followers;
  final List<String> following;
  final List<String> blockedUsers;
  final String? profileImageUrl;  // Changed from photoUrl
  final String? coverPhotoUrl;
  final int postsCount;
  final List<String> posts;
  final DateTime lastSeen;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.bio,
    this.gender,
    this.birthDate,
    this.phone,
    this.location,
    this.website,
    this.socialLinks = const {},
    this.followers = const [],
    this.following = const [],
    this.blockedUsers = const [],
    this.profileImageUrl,  // Changed from photoUrl
    this.coverPhotoUrl,
    this.postsCount = 0,
    this.posts = const [],
    DateTime? lastSeen,
    this.fcmToken,
  }) : this.lastSeen = lastSeen ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      return null;
    }

    // Validate image URLs
    String? validateImageUrl(String? url) {
      if (url != null && !url.startsWith('http')) {
        debugPrint('Invalid image URL found: $url');
        return null;
      }
      return url;
    }

    return UserModel(
      id: id,
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      bio: map['bio'],
      gender: map['gender'],
      birthDate: parseTimestamp(map['birthDate']),
      phone: map['phone'],
      location: map['location'],
      website: map['website'],
      socialLinks: Map<String, String>.from(map['socialLinks'] ?? {}),
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
      profileImageUrl: validateImageUrl(map['profileImageUrl']),  // Changed from photoUrl
      coverPhotoUrl: validateImageUrl(map['coverPhotoUrl']),
      postsCount: map['postsCount'] ?? 0,
      posts: List<String>.from(map['posts'] ?? []),
      lastSeen: parseTimestamp(map['lastSeen']) ?? DateTime.now(),
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'bio': bio,
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'phone': phone,
      'location': location,
      'website': website,
      'socialLinks': socialLinks,
      'followers': followers,
      'following': following,
      'blockedUsers': blockedUsers,
      'profileImageUrl': profileImageUrl,  // Changed from photoUrl
      'coverPhotoUrl': coverPhotoUrl,
      'postsCount': postsCount,
      'posts': posts,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? email,
    String? username,
    String? bio,
    String? gender,
    DateTime? birthDate,
    String? phone,
    String? location,
    String? website,
    Map<String, String>? socialLinks,
    List<String>? followers,
    List<String>? following,
    List<String>? blockedUsers,
    String? profileImageUrl,  // Changed from photoUrl
    String? coverPhotoUrl,
    int? postsCount,
    List<String>? posts,
    DateTime? lastSeen,
    String? fcmToken,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      website: website ?? this.website,
      socialLinks: socialLinks ?? this.socialLinks,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,  // Changed from photoUrl
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      postsCount: postsCount ?? this.postsCount,
      posts: posts ?? this.posts,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
