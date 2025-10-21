import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/daily_goal_service.dart';
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
  final DailyGoalService _dailyGoalService = DailyGoalService();
  late Map<String, dynamic> _settings;
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 19, minute: 0);
  String _appVersion = '';
  int _dailyGoalTarget = 10;

  @override
  void initState() {
    super.initState();
    _settings = _storage.getSettings();
    _loadNotificationSettings();
    _loadAppVersion();
    _loadDailyGoal();
  }

  void _loadDailyGoal() {
    setState(() {
      _dailyGoalTarget = _dailyGoalService.getDailyTarget();
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
              AdaptiveSwitchListTile(
                title: Text(
                  'Tägliche Lernziele',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.label.resolveFrom(context)
                        : null,
                  ),
                ),
                subtitle: Text(
                  'Aktiviere tägliche Lernziele',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
                ),
                value: _dailyGoalService.areGoalsEnabled(),
                onChanged: (value) async {
                  await _dailyGoalService.setGoalsEnabled(value);
                  setState(() {});
                },
              ),
              if (_dailyGoalService.areGoalsEnabled())
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
                    '$_dailyGoalTarget Fragen pro Tag',
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
                    _formatTime(_notificationTime),
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
              children: [5, 10, 15, 20, 30].map((goal) {
                return ChoiceChip(
                  label: Text('$goal'),
                  selected: _dailyGoalTarget == goal,
                  onSelected: (selected) async {
                    if (selected) {
                      await _dailyGoalService.setDailyTarget(goal);

                      if (!mounted) return;

                      setState(() {
                        _dailyGoalTarget = goal;
                      });

                      if (context.mounted) {
                        context.pop();
                      }
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
    showPlatformDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: const Text('SBF-See Lernkarten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version $_appVersion',
                style: TextStyle(
                  color: isCupertino(context)
                      ? CupertinoColors.secondaryLabel.resolveFrom(context)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Diese App hilft dir bei der Vorbereitung auf die theoretische Prüfung zum Sportbootführerschein See (SBF-See).',
              ),
              const SizedBox(height: 8),
              const Text(
                'Die Fragen basieren auf dem offiziellen Fragenkatalog der ELWIS.',
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _launchGitHub(),
                child: Text(
                  'github.com/cedricziel/sportboot-app',
                  style: TextStyle(
                    color: isCupertino(context)
                        ? CupertinoColors.activeBlue
                        : Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '© 2024 Cedric Ziel',
                style: TextStyle(
                  fontSize: 12,
                  color: isCupertino(context)
                      ? CupertinoColors.secondaryLabel.resolveFrom(context)
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lizenziert unter AGPL-3.0',
                style: TextStyle(
                  fontSize: 12,
                  color: isCupertino(context)
                      ? CupertinoColors.secondaryLabel.resolveFrom(context)
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quellcode verfügbar auf GitHub',
                style: TextStyle(
                  fontSize: 11,
                  color: isCupertino(context)
                      ? CupertinoColors.tertiaryLabel.resolveFrom(context)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PlatformDialogAction(
            onPressed: () => context.pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchGitHub() async {
    final uri = Uri.parse('https://github.com/cedricziel/sportboot-app');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    // Update state immediately for responsive UI
    setState(() {
      _notificationsEnabled = enabled;
    });

    try {
      if (enabled) {
        final hasPermission = await _notifications.requestPermissions();
        if (!hasPermission) {
          // Permission denied - revert state
          setState(() {
            _notificationsEnabled = false;
          });
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

      await _storage.setSetting('notificationsEnabled', enabled);
    } catch (e) {
      // Error occurred - revert state
      setState(() {
        _notificationsEnabled = !enabled;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fehler beim ${enabled ? "Aktivieren" : "Deaktivieren"} der Benachrichtigungen',
            ),
          ),
        );
      }
    }
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
