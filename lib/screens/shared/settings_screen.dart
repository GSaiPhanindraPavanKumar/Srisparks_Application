import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../config/app_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  // Settings values
  bool _darkMode = false;
  bool _notifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  String _language = 'English';
  String _timeZone = 'UTC';
  String _theme = 'System';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from local storage or API
    // For now, using default values
    setState(() {
      // Settings loaded
    });
  }

  Future<void> _saveSettings() async {
    // Save settings to local storage or API
    _showMessage('Settings saved successfully');
  }

  Future<void> _logout() async {
    final shouldLogout = await _showLogoutDialog();
    if (shouldLogout) {
      try {
        await _authService.logout();
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.auth);
        }
      } catch (e) {
        _showMessage('Error logging out: $e');
      }
    }
  }

  Future<bool> _showLogoutDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveSettings),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAppearanceSection(),
            const SizedBox(height: 20),
            _buildNotificationSection(),
            const SizedBox(height: 20),
            _buildLanguageSection(),
            const SizedBox(height: 20),
            _buildAccountSection(),
            const SizedBox(height: 20),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return _buildSection(
      title: 'Appearance',
      icon: Icons.palette,
      children: [
        _buildDropdownSetting(
          title: 'Theme',
          value: _theme,
          items: ['System', 'Light', 'Dark'],
          onChanged: (value) {
            setState(() {
              _theme = value;
            });
          },
        ),
        _buildSwitchSetting(
          title: 'Dark Mode',
          subtitle: 'Enable dark theme',
          value: _darkMode,
          onChanged: (value) {
            setState(() {
              _darkMode = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return _buildSection(
      title: 'Notifications',
      icon: Icons.notifications,
      children: [
        _buildSwitchSetting(
          title: 'Push Notifications',
          subtitle: 'Receive push notifications',
          value: _notifications,
          onChanged: (value) {
            setState(() {
              _notifications = value;
            });
          },
        ),
        _buildSwitchSetting(
          title: 'Email Notifications',
          subtitle: 'Receive email notifications',
          value: _emailNotifications,
          onChanged: (value) {
            setState(() {
              _emailNotifications = value;
            });
          },
        ),
        _buildSwitchSetting(
          title: 'SMS Notifications',
          subtitle: 'Receive SMS notifications',
          value: _smsNotifications,
          onChanged: (value) {
            setState(() {
              _smsNotifications = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLanguageSection() {
    return _buildSection(
      title: 'Language & Region',
      icon: Icons.language,
      children: [
        _buildDropdownSetting(
          title: 'Language',
          value: _language,
          items: ['English', 'Spanish', 'French', 'German'],
          onChanged: (value) {
            setState(() {
              _language = value;
            });
          },
        ),
        _buildDropdownSetting(
          title: 'Time Zone',
          value: _timeZone,
          items: ['UTC', 'EST', 'PST', 'CST', 'MST'],
          onChanged: (value) {
            setState(() {
              _timeZone = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(
      title: 'Account',
      icon: Icons.account_circle,
      children: [
        _buildActionSetting(
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          icon: Icons.privacy_tip,
          onTap: () {
            _showMessage('Privacy policy feature coming soon');
          },
        ),
        _buildActionSetting(
          title: 'Terms of Service',
          subtitle: 'Read our terms of service',
          icon: Icons.description,
          onTap: () {
            _showMessage('Terms of service feature coming soon');
          },
        ),
        _buildActionSetting(
          title: 'Data Export',
          subtitle: 'Export your data',
          icon: Icons.download,
          onTap: () {
            _showMessage('Data export feature coming soon');
          },
        ),
        _buildActionSetting(
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          icon: Icons.delete_forever,
          iconColor: Colors.red,
          onTap: () {
            _showMessage('Account deletion feature coming soon');
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'About',
      icon: Icons.info,
      children: [
        _buildActionSetting(
          title: 'Version',
          subtitle: '1.0.0',
          icon: Icons.info_outline,
          onTap: () {},
        ),
        _buildActionSetting(
          title: 'Help & Support',
          subtitle: 'Get help and support',
          icon: Icons.help,
          onTap: () {
            _showMessage('Help & support feature coming soon');
          },
        ),
        _buildActionSetting(
          title: 'Send Feedback',
          subtitle: 'Send us your feedback',
          icon: Icons.feedback,
          onTap: () {
            _showMessage('Feedback feature coming soon');
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildDropdownSetting({
    required String title,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }

  Widget _buildActionSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
