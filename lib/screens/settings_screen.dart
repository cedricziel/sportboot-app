import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    _settings = _storage.getSettings();
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
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
}
