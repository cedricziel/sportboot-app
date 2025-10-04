import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();
  late Map<String, dynamic> _settings;
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    _settings = _storage.getSettings();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _notificationsEnabled = _storage.getSetting(
        'notificationsEnabled',
        defaultValue: false,
      );
      final timeString = _storage.getSetting(
        'notificationTime',
        defaultValue: '19:00',
      );
      final parts = timeString.split(':');
      _notificationTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    });
  }

  void _updateSetting(String key, dynamic value) {
    setState(() {
      _settings[key] = value;
    });
    _storage.saveSetting(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Lerneinstellungen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Fragen mischen'),
            subtitle: const Text('Zufällige Reihenfolge der Fragen'),
            value: _settings['shuffleQuestions'] ?? false,
            onChanged: (value) => _updateSetting('shuffleQuestions', value),
          ),
          SwitchListTile(
            title: const Text('Timer anzeigen'),
            subtitle: const Text('Zeit pro Frage anzeigen'),
            value: _settings['showTimer'] ?? true,
            onChanged: (value) => _updateSetting('showTimer', value),
          ),
          SwitchListTile(
            title: const Text('Töne aktiviert'),
            subtitle: const Text('Soundeffekte bei Antworten'),
            value: _settings['soundEnabled'] ?? true,
            onChanged: (value) => _updateSetting('soundEnabled', value),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Lernziele',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Tägliches Ziel'),
            subtitle: Text('${_settings['dailyGoal'] ?? 20} Fragen pro Tag'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showDailyGoalDialog(),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Benachrichtigungen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Tägliche Erinnerung'),
            subtitle: const Text('Erinnere mich ans tägliche Quiz'),
            value: _notificationsEnabled,
            onChanged: (value) => _toggleNotifications(value),
          ),
          if (_notificationsEnabled)
            ListTile(
              title: const Text('Erinnerungszeit'),
              subtitle: Text(_notificationTime.format(context)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectNotificationTime(),
            ),
          if (_notificationsEnabled)
            ListTile(
              title: const Text('Test-Benachrichtigung'),
              subtitle: const Text('Sende eine Test-Benachrichtigung'),
              trailing: const Icon(Icons.notifications_active),
              onTap: () => _sendTestNotification(),
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'App-Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const ListTile(title: Text('Version'), subtitle: Text('1.0.0')),
          const ListTile(
            title: Text('Fragen'),
            subtitle: Text('287 Fragen (SBF-See 2024)'),
          ),
          const ListTile(
            title: Text('Quelle'),
            subtitle: Text(
              'ELWIS - Elektronisches Wasserstraßen-Informationssystem',
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () => _showAboutDialog(),
              icon: const Icon(Icons.info_outline),
              label: const Text('Über diese App'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDailyGoalDialog() {
    int currentGoal = _settings['dailyGoal'] ?? 20;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tägliches Lernziel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Wie viele Fragen möchtest du täglich lernen?'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [10, 20, 30, 50, 100].map((goal) {
                  return ChoiceChip(
                    label: Text('$goal'),
                    selected: currentGoal == goal,
                    onSelected: (selected) {
                      if (selected) {
                        _updateSetting('dailyGoal', goal);
                        context.pop();
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Abbrechen'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'SBF-See Lernkarten',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Sportbootführerschein Lern-App',
      children: const [
        SizedBox(height: 16),
        Text(
          'Diese App hilft dir bei der Vorbereitung auf die theoretische Prüfung zum Sportbootführerschein See (SBF-See).',
        ),
        SizedBox(height: 8),
        Text(
          'Die Fragen basieren auf dem offiziellen Fragenkatalog der ELWIS.',
        ),
      ],
    );
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (enabled) {
      final hasPermission = await _notifications.requestPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Benachrichtigungen wurden nicht erlaubt'),
            ),
          );
        }
        return;
      }
      await _notifications.scheduleDailyNotification(_notificationTime);
    } else {
      await _notifications.cancelAllNotifications();
    }

    setState(() {
      _notificationsEnabled = enabled;
    });
    await _storage.setSetting('notificationsEnabled', enabled);
  }

  Future<void> _selectNotificationTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      helpText: 'Wähle Erinnerungszeit',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (newTime != null && newTime != _notificationTime) {
      setState(() {
        _notificationTime = newTime;
      });
      await _storage.setSetting(
        'notificationTime',
        '${newTime.hour}:${newTime.minute}',
      );
      if (_notificationsEnabled) {
        await _notifications.scheduleDailyNotification(newTime);
      }
    }
  }

  Future<void> _sendTestNotification() async {
    await _notifications.showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test-Benachrichtigung gesendet!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
