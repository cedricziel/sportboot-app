import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/platform/adaptive_switch.dart';
import '../widgets/platform/adaptive_list_tile.dart';
import '../widgets/platform/adaptive_list_section.dart';

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
    return PlatformScaffold(
      appBar: const PlatformAppBar(title: Text('Einstellungen')),
      body: ListView(
        children: [
          AdaptiveListSection.insetGrouped(
            header: Text(
              'Lerneinstellungen',
              style: TextStyle(
                color: isCupertino(context)
                    ? CupertinoColors.secondaryLabel.resolveFrom(context)
                    : null,
              ),
            ),
            children: [
              AdaptiveSwitchListTile(
                title: Text(
                  'Fragen mischen',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.label.resolveFrom(context)
                        : null,
                  ),
                ),
                subtitle: Text(
                  'Zufällige Reihenfolge der Fragen',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
                ),
                value: _settings['shuffleQuestions'] ?? false,
                onChanged: (value) => _updateSetting('shuffleQuestions', value),
              ),
              AdaptiveSwitchListTile(
                title: Text(
                  'Timer anzeigen',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.label.resolveFrom(context)
                        : null,
                  ),
                ),
                subtitle: Text(
                  'Zeit pro Frage anzeigen',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
                ),
                value: _settings['showTimer'] ?? true,
                onChanged: (value) => _updateSetting('showTimer', value),
              ),
              AdaptiveSwitchListTile(
                title: Text(
                  'Töne aktiviert',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.label.resolveFrom(context)
                        : null,
                  ),
                ),
                subtitle: Text(
                  'Soundeffekte bei Antworten',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
                ),
                value: _settings['soundEnabled'] ?? true,
                onChanged: (value) => _updateSetting('soundEnabled', value),
              ),
            ],
          ),
          AdaptiveListSection.insetGrouped(
            header: Text(
              'Lernziele',
              style: TextStyle(
                color: isCupertino(context)
                    ? CupertinoColors.secondaryLabel.resolveFrom(context)
                    : null,
              ),
            ),
            children: [
              AdaptiveListTile(
                title: Text(
                  'Tägliches Ziel',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.label.resolveFrom(context)
                        : null,
                  ),
                ),
                subtitle: Text(
                  '${_settings['dailyGoal'] ?? 20} Fragen pro Tag',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
                ),
                onTap: () => _showDailyGoalDialog(),
              ),
            ],
          ),
          AdaptiveListSection.insetGrouped(
            header: Text(
              'Benachrichtigungen',
              style: TextStyle(
                color: isCupertino(context)
                    ? CupertinoColors.secondaryLabel.resolveFrom(context)
                    : null,
              ),
            ),
            children: [
              AdaptiveSwitchListTile(
                title: Text(
                  'Tägliche Erinnerung',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.label.resolveFrom(context)
                        : null,
                  ),
                ),
                subtitle: Text(
                  'Erinnere mich ans tägliche Quiz',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
                ),
                value: _notificationsEnabled,
                onChanged: (value) => _toggleNotifications(value),
              ),
              if (_notificationsEnabled)
                AdaptiveListTile(
                  title: Text(
                    'Erinnerungszeit',
                    style: TextStyle(
                      color: isCupertino(context)
                          ? CupertinoColors.label.resolveFrom(context)
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    _notificationTime.format(context),
                    style: TextStyle(
                      color: isCupertino(context)
                          ? CupertinoColors.secondaryLabel.resolveFrom(context)
                          : null,
                    ),
                  ),
                  onTap: () => _selectNotificationTime(),
                ),
              if (_notificationsEnabled)
                AdaptiveListTile(
                  title: Text(
                    'Test-Benachrichtigung',
                    style: TextStyle(
                      color: isCupertino(context)
                          ? CupertinoColors.label.resolveFrom(context)
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    'Sende eine Test-Benachrichtigung',
                    style: TextStyle(
                      color: isCupertino(context)
                          ? CupertinoColors.secondaryLabel.resolveFrom(context)
                          : null,
                    ),
                  ),
                  trailing: Icon(
                    isCupertino(context)
                        ? CupertinoIcons.bell_fill
                        : Icons.notifications_active,
                  ),
                  onTap: () => _sendTestNotification(),
                ),
            ],
          ),
          AdaptiveListSection.insetGrouped(
            header: Text(
              'App-Info',
              style: TextStyle(
                color: isCupertino(context)
                    ? CupertinoColors.secondaryLabel.resolveFrom(context)
                    : null,
              ),
            ),
            children: [
              AdaptiveListTile(
                title: Text(
                  'Version',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.label.resolveFrom(context)
                        : null,
                  ),
                ),
                subtitle: Text(
                  '1.0.0',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
                ),
              ),
              AdaptiveListTile(
                title: Text(
                  'Fragen',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.label.resolveFrom(context)
                        : null,
                  ),
                ),
                subtitle: Text(
                  '287 Fragen (SBF-See 2024)',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
                ),
              ),
              AdaptiveListTile(
                title: Text(
                  'Quelle',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.label.resolveFrom(context)
                        : null,
                  ),
                ),
                subtitle: Text(
                  'ELWIS - Elektronisches Wasserstraßen-Informationssystem',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: PlatformElevatedButton(
              onPressed: () => _showAboutDialog(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCupertino(context)
                        ? CupertinoIcons.info_circle
                        : Icons.info_outline,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text('Über diese App'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDailyGoalDialog() {
    int currentGoal = _settings['dailyGoal'] ?? 20;
    showPlatformDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
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
          PlatformDialogAction(
            onPressed: () => context.pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
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
    TimeOfDay? newTime;

    if (isCupertino(context)) {
      // Use Cupertino picker for iOS
      await showCupertinoModalPopup(
        context: context,
        builder: (context) {
          DateTime tempTime = DateTime(
            2024,
            1,
            1,
            _notificationTime.hour,
            _notificationTime.minute,
          );
          return Container(
            height: 216,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Abbrechen'),
                        onPressed: () => context.pop(),
                      ),
                      CupertinoButton(
                        child: const Text('Fertig'),
                        onPressed: () {
                          newTime = TimeOfDay.fromDateTime(tempTime);
                          context.pop();
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      initialDateTime: tempTime,
                      onDateTimeChanged: (DateTime value) {
                        tempTime = value;
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      newTime = await showTimePicker(
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
    }

    if (newTime != null && newTime != _notificationTime) {
      setState(() {
        _notificationTime = newTime!;
      });
      await _storage.setSetting(
        'notificationTime',
        '${newTime!.hour}:${newTime!.minute}',
      );
      if (_notificationsEnabled) {
        await _notifications.scheduleDailyNotification(newTime!);
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
