import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:unibuzz_community/widgets/user_avatar.dart';

class UserSelectionSheet extends StatefulWidget {
  const UserSelectionSheet({super.key});

  @override
  State<UserSelectionSheet> createState() => _UserSelectionSheetState();
}

class _UserSelectionSheetState extends State<UserSelectionSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  Stream<QuerySnapshot> _getUsersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('uid', isNotEqualTo: AuthService().currentUser?.uid)
        .limit(20)
        .snapshots();
  }

  bool _matchesSearch(Map<String, dynamic> userData) {
    if (_searchQuery.isEmpty) return true;
    
    final searchLower = _searchQuery.toLowerCase();
    final username = (userData['username'] ?? '').toString().toLowerCase();
    final email = (userData['email'] ?? '').toString().toLowerCase();
    
    return username.contains(searchLower) || email.contains(searchLower);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search users...',
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
          autofocus: true,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allUsers = snapshot.data!.docs;
          final filteredUsers = allUsers.where(
            (doc) => _matchesSearch(doc.data() as Map<String, dynamic>)
          ).toList();
          
          if (filteredUsers.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final userData = filteredUsers[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: UserAvatar(
                  imageUrl: userData['photoUrl'],
                  username: userData['username'],
                ),
                title: Text(userData['username'] ?? 'Unknown User'),
                subtitle: Text(userData['email'] ?? ''),
                onTap: () => Navigator.pop(context, filteredUsers[index].id),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
