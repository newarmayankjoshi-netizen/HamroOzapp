import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_page.dart';
import 'terms_of_service_page.dart';
import 'privacy_policy_page.dart';
import 'help_support_page.dart';
import 'services/security_service.dart';
import 'services/theme_controller.dart';
import 'services/locale_controller.dart';
import 'package:hamro_oz/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;

  final _adzunaFormKey = GlobalKey<FormState>();
  final _adzunaAppIdController = TextEditingController();
  final _adzunaAppKeyController = TextEditingController();
  final _securityService = SecurityService();

  bool _isSavingAdzuna = false;
  bool _showAdzunaKey = false;
  String? _storedAdzunaAppId;
  String? _storedAdzunaAppKey;

  // Notification Settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _jobNotifications = true;
  bool _roomNotifications = true;
  bool _eventNotifications = true;
  bool _marketplaceNotifications = true;

  // Privacy Settings
  bool _profileVisible = true;
  bool _showContactInfo = true;
  bool _showLocation = true;

  // App Settings
  String _themeMode = 'system'; // light, dark, system
  bool _autoDownloadImages = true;
  String _language = 'english'; // english, nepali

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _adzunaAppIdController.dispose();
    _adzunaAppKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Adzuna credentials (best-effort; secure storage can be unavailable on some platforms).
    String? adzunaId;
    String? adzunaKey;
    try {
      adzunaId = await _securityService.getSecureData('adzuna_app_id');
      adzunaKey = await _securityService.getSecureData('adzuna_app_key');
    } catch (_) {
      adzunaId = null;
      adzunaKey = null;
    }

    setState(() {
      // Notification Settings
      _pushNotifications = prefs.getBool('pushNotifications') ?? true;
      _emailNotifications = prefs.getBool('emailNotifications') ?? true;
      _jobNotifications = prefs.getBool('jobNotifications') ?? true;
      _roomNotifications = prefs.getBool('roomNotifications') ?? true;
      _eventNotifications = prefs.getBool('eventNotifications') ?? true;
      _marketplaceNotifications =
          prefs.getBool('marketplaceNotifications') ?? true;

      // Privacy Settings
      _profileVisible = prefs.getBool('profileVisible') ?? true;
      _showContactInfo = prefs.getBool('showContactInfo') ?? true;
      _showLocation = prefs.getBool('showLocation') ?? true;

      // App Settings
      _themeMode = prefs.getString('themeMode') ?? 'system';
      _autoDownloadImages = prefs.getBool('autoDownloadImages') ?? true;
      _language = prefs.getString('language') ?? 'english';

      _storedAdzunaAppId = adzunaId;
      _storedAdzunaAppKey = adzunaKey;

      _isLoading = false;
    });
  }

  String _maskSecret(String value, {int keepStart = 4, int keepEnd = 2}) {
    final v = value.trim();
    if (v.isEmpty) return '';
    if (v.length <= keepStart + keepEnd) return '••••';
    final start = v.substring(0, keepStart);
    final end = v.substring(v.length - keepEnd);
    return '$start••••••••$end';
  }

  Future<void> _saveAdzunaCredentials() async {
    if (_isSavingAdzuna) return;
    final form = _adzunaFormKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    final appId = _adzunaAppIdController.text.trim();
    final appKey = _adzunaAppKeyController.text.trim();

    setState(() {
      _isSavingAdzuna = true;
    });

    try {
      await _securityService.storeSecureData('adzuna_app_id', appId);
      await _securityService.storeSecureData('adzuna_app_key', appKey);

      if (!mounted) return;
      setState(() {
        _storedAdzunaAppId = appId;
        _storedAdzunaAppKey = appKey;
        _adzunaAppIdController.clear();
        _adzunaAppKeyController.clear();
        _isSavingAdzuna = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Adzuna credentials saved')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSavingAdzuna = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save Adzuna credentials: $e')),
      );
    }
  }

  Future<void> _clearAdzunaCredentials() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Adzuna Credentials'),
        content: const Text(
          'This will remove the saved Adzuna APP_ID and APP_KEY from secure storage. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _securityService.deleteSecureData('adzuna_app_id');
      await _securityService.deleteSecureData('adzuna_app_key');
      if (!mounted) return;
      setState(() {
        _storedAdzunaAppId = null;
        _storedAdzunaAppKey = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adzuna credentials cleared')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear Adzuna credentials: $e')),
      );
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached images and data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // In a real app, you would clear actual cache here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // In a real app, you would delete the account from backend
      await AuthState.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = AuthState.currentUser?.email;
    if (email == null || email.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email available for this account')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await fb_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset email sent to $email')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send password reset email: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportData() async {
    // In a real app, you would export user data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your data has been exported and will be sent to your email',
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Nepalese in Australia',
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(size: 48),
      children: [
        const Text(
          'A community platform connecting Nepalese people living in Australia. '
          'Find jobs, accommodation, services, events, and more.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.settings ?? 'Settings')),
      body: ListView(
        children: [
          // Notifications Section
          _buildSectionHeader(AppLocalizations.of(context)?.notifications ?? 'Notifications', Icons.notifications),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive notifications on your device'),
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
              _saveSetting('pushNotifications', value);
            },
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive notifications via email'),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
              _saveSetting('emailNotifications', value);
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Notification Types',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Job Listings'),
            value: _jobNotifications,
            onChanged: (value) {
              setState(() => _jobNotifications = value);
              _saveSetting('jobNotifications', value);
            },
          ),
          SwitchListTile(
            title: const Text('Room Listings'),
            value: _roomNotifications,
            onChanged: (value) {
              setState(() => _roomNotifications = value);
              _saveSetting('roomNotifications', value);
            },
          ),
          SwitchListTile(
            title: const Text('Community Events'),
            value: _eventNotifications,
            onChanged: (value) {
              setState(() => _eventNotifications = value);
              _saveSetting('eventNotifications', value);
            },
          ),
          SwitchListTile(
            title: const Text('Marketplace'),
            value: _marketplaceNotifications,
            onChanged: (value) {
              setState(() => _marketplaceNotifications = value);
              _saveSetting('marketplaceNotifications', value);
            },
          ),
          const Divider(height: 32),

          // Privacy Section
          _buildSectionHeader('Privacy', Icons.lock),
          SwitchListTile(
            title: const Text('Profile Visibility'),
            subtitle: const Text('Make your profile visible to other users'),
            value: _profileVisible,
            onChanged: (value) {
              setState(() => _profileVisible = value);
              _saveSetting('profileVisible', value);
            },
          ),
          SwitchListTile(
            title: const Text('Show Contact Information'),
            subtitle: const Text('Display phone number to other users'),
            value: _showContactInfo,
            onChanged: (value) {
              setState(() => _showContactInfo = value);
              _saveSetting('showContactInfo', value);
            },
          ),
          SwitchListTile(
            title: const Text('Show Location'),
            subtitle: const Text('Display your state to other users'),
            value: _showLocation,
            onChanged: (value) {
              setState(() => _showLocation = value);
              _saveSetting('showLocation', value);
            },
          ),
          const Divider(height: 32),

          // App Preferences Section
          _buildSectionHeader(AppLocalizations.of(context)?.appPreferences ?? 'App Preferences', Icons.tune),
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(AppLocalizations.of(context)?.theme ?? 'Theme'),
            subtitle: Text(_getThemeDisplayName(_themeMode)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showThemeDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context)?.language ?? 'Language'),
            subtitle: Text(_getLanguageDisplayName(_language)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.image),
            title: const Text('Auto-download Images'),
            subtitle: const Text('Automatically load images'),
            value: _autoDownloadImages,
            onChanged: (value) {
              setState(() => _autoDownloadImages = value);
              _saveSetting('autoDownloadImages', value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            onTap: _clearCache,
          ),
          const Divider(height: 32),

          // Adzuna API Settings - Admin Only
          if (AuthState.isAdmin) ...[
            _buildSectionHeader('Adzuna API (Jobs)', Icons.api),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _adzunaFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Used to load jobs by Australian state from Adzuna.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if ((_storedAdzunaAppId ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Saved APP_ID: ${_maskSecret(_storedAdzunaAppId!)}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      if ((_storedAdzunaAppKey ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Saved APP_KEY: ${_maskSecret(_storedAdzunaAppKey!, keepStart: 6, keepEnd: 4)}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      TextFormField(
                        controller: _adzunaAppIdController,
                        decoration: const InputDecoration(
                          labelText: 'Adzuna APP_ID',
                          hintText: 'e.g. 2e6f4bda',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return 'APP_ID is required';
                          if (!RegExp(r'^[a-zA-Z0-9_\-]{6,40} ?$').hasMatch(v)) {
                            return 'Invalid APP_ID format';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _adzunaAppKeyController,
                        decoration: InputDecoration(
                          labelText: 'Adzuna APP_KEY',
                          hintText: 'Paste your APP_KEY',
                          suffixIcon: IconButton(
                            tooltip: _showAdzunaKey ? 'Hide' : 'Show',
                            onPressed: () {
                              setState(() {
                                _showAdzunaKey = !_showAdzunaKey;
                              });
                            },
                            icon: Icon(
                              _showAdzunaKey
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        obscureText: !_showAdzunaKey,
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return 'APP_KEY is required';
                          // Adzuna keys are commonly hex strings, but keep validation flexible.
                          if (v.length < 16) return 'APP_KEY looks too short';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: _isSavingAdzuna
                                  ? null
                                  : _saveAdzunaCredentials,
                              child: _isSavingAdzuna
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: _clearAdzunaCredentials,
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 32),
          ],

          // Account Section
          _buildSectionHeader('Account', Icons.account_circle),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            subtitle: const Text('Send a password reset email to your account'),
            onTap: _sendPasswordResetEmail,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export My Data'),
            subtitle: const Text('Download a copy of your data'),
            onTap: _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Permanently delete your account'),
            onTap: _showDeleteAccountDialog,
          ),
          const Divider(height: 32),

          // About Section
          _buildSectionHeader('About', Icons.info),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About App'),
            onTap: _showAboutDialog,
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Version'),
            subtitle: const Text('1.0.0 (Build 1)'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System Default';
      default:
        return 'System Default';
    }
  }

  String _getLanguageDisplayName(String lang) {
    switch (lang) {
      case 'english':
        return 'English';
      case 'nepali':
        return 'नेपाली (Nepali)';
      default:
        return 'English';
    }
  }

  Future<void> _showThemeDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'light'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Light'),
                if (_themeMode == 'light') Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'dark'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dark'),
                if (_themeMode == 'dark') Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'system'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('System Default'),
                if (_themeMode == 'system') Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _themeMode = result);
      await _saveSetting('themeMode', result);
      await ThemeController.instance.setThemeModeFromString(result);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.themeChanged(result) ?? 'Theme changed to ${_getThemeDisplayName(result)}')));
    }
  }

  Future<void> _showLanguageDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Choose Language'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'english'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('English'),
                if (_language == 'english') Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'nepali'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('नेपाली (Nepali)'),
                if (_language == 'nepali') Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _language = result);
      await _saveSetting('language', result);
      // apply immediately via LocaleController
      await LocaleController.instance.setLocale(result == 'nepali' ? const Locale('ne') : const Locale('en'));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.languageChanged(_getLanguageDisplayName(result)) ?? 'Language changed to ${_getLanguageDisplayName(result)}')));
    }
  }
}
