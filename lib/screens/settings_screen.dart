import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constant/theme_provider.dart';
import '../localization/localization_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizedValues =
        LocalizationService.getLocalizedValues(themeProvider.selectedLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizedValues['settings'] ?? 'Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Toggle Theme
            SwitchListTile(
              title: Text(localizedValues['dark_mode'] ?? 'Dark Mode'),
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (bool value) {
                themeProvider.toggleTheme(value);
              },
            ),
            // Language Selection
            DropdownButtonFormField<String>(
              value: themeProvider.selectedLanguage,
              items: [
                {
                  'code': 'en',
                  'label': localizedValues['english'] ?? 'English'
                },
                {
                  'code': 'vi',
                  'label': localizedValues['vietnamese'] ?? 'Vietnamese'
                },
              ].map((Map<String, String> language) {
                return DropdownMenuItem<String>(
                  value: language['code'],
                  child: Text(language['label']!),
                );
              }).toList(),
              onChanged: (String? newLanguage) {
                if (newLanguage != null) {
                  themeProvider.saveLanguagePreference(newLanguage);
                  setState(() {});
                }
              },
              decoration: InputDecoration(
                  labelText: localizedValues['language'] ?? 'Language'),
            ),
          ],
        ),
      ),
    );
  }
}
