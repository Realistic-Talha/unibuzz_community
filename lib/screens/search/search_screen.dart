import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unibuzz_community/providers/theme_provider.dart';
import 'package:unibuzz_community/models/user_settings.dart';
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:unibuzz_community/widgets/search/post_search_delegate.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            showSearch(
              context: context,
              delegate: PostSearchDelegate(),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(Icons.search),
                SizedBox(width: 8),
                Text('Search...'),
              ],
            ),
          ),
        ),
      ),
      body: const Center(child: Text('Tap the search bar to start')),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final userData = await AuthService().getUserSettings();
      setState(() {
        _settings = userData != null
            ? UserSettings.fromMap(userData)
            : UserSettings();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSection(
            title: 'Appearance',
            children: [
              ListTile(
                title: const Text('Theme'),
                trailing: DropdownButton<ThemeMode>(
                  value: context.watch<ThemeProvider>().themeMode,
                  items: ThemeMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode.name.capitalize()),
                    );
                  }).toList(),
                  onChanged: (mode) {
                    if (mode != null) {
                      context.read<ThemeProvider>().setThemeMode(mode);
                    }
                  },
                ),
              ),
            ],
          ),
          _buildSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: const Text('Email Notifications'),
                value: _settings.emailNotifications,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(
                      emailNotifications: value,
                    );
                  });
                  AuthService().updateUserSettings(_settings.toMap());
                },
              ),
              SwitchListTile(
                title: const Text('Push Notifications'),
                value: _settings.pushNotifications,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(
                      pushNotifications: value,
                    );
                  });
                  AuthService().updateUserSettings(_settings.toMap());
                },
              ),
            ],
          ),
          _buildSection(
            title: 'Category Subscriptions',
            children: [
              for (final category in [
                'Academic',
                'Social',
                'Events',
                'Lost & Found'
              ])
                SwitchListTile(
                  title: Text(category),
                  value: _settings.categorySubscriptions[category] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(
                        categorySubscriptions: {
                          ..._settings.categorySubscriptions,
                          category: value,
                        },
                      );
                    });
                    AuthService().updateUserSettings(_settings.toMap());
                  },
                ),
            ],
          ),
          _buildSection(
            title: 'Privacy',
            children: [
              ListTile(
                title: const Text('Blocked Users'),
                trailing: Text(
                  '${_settings.mutedUsers.length} blocked',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  // TODO: Implement blocked users screen
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
