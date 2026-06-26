/// Settings screen — theme, TTS speed, haptics, clear history, about.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/voice_personas.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/home_viewmodel.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = '${info.version} (${info.buildNumber})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final ttsSpeed = ref.watch(ttsSpeedProvider);
    final hapticsEnabled = ref.watch(hapticsEnabledProvider);
    final silenceTimeout = ref.watch(silenceTimeoutProvider);
    final voicePersona = ref.watch(voicePersonaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Appearance ─────────────────────────────────────
          const _SectionHeader('Appearance'),
          _ThemeModeTile(
            value: themeMode,
            onChanged: (mode) =>
                ref.read(themeModeProvider.notifier).setThemeMode(mode),
          ),

          const Divider(height: 32),

          // ── Voice ──────────────────────────────────────────
          const _SectionHeader('Voice'),
          _TtsSpeedTile(
            value: ttsSpeed,
            onChanged: (speed) =>
                ref.read(ttsSpeedProvider.notifier).setSpeed(speed),
          ),
          _SilenceTimeoutTile(
            value: silenceTimeout,
            onChanged: (ms) =>
                ref.read(silenceTimeoutProvider.notifier).setTimeout(ms),
          ),
          _VoicePersonaTile(
            value: voicePersona,
            onChanged: (persona) =>
                ref.read(voicePersonaProvider.notifier).setPersona(persona),
          ),

          const Divider(height: 32),

          // ── Feedback ───────────────────────────────────────
          const _SectionHeader('Feedback'),
          SwitchListTile(
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Vibrations on actions and AI responses'),
            value: hapticsEnabled,
            onChanged: (v) =>
                ref.read(hapticsEnabledProvider.notifier).setEnabled(v),
            secondary: const Icon(Icons.vibration),
          ),

          const Divider(height: 32),

          // ── Data ───────────────────────────────────────────
          const _SectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text(
              'Clear All History',
              style: TextStyle(color: AppColors.error),
            ),
            subtitle: const Text('Permanently delete all brainstorm sessions'),
            onTap: () => _confirmClearHistory(context),
          ),

          const Divider(height: 32),

          // ── About ──────────────────────────────────────────
          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(_version),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('How we handle your data'),
            onTap: () {
              // Stub — link to privacy policy page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy policy coming soon'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text(
          'This will permanently delete all your brainstorm sessions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Load all sessions and delete each one.
        final vm = ref.read(homeViewModelProvider.notifier);
        final sessions = await ref.read(homeViewModelProvider.future);
        for (final session in sessions) {
          await vm.deleteBrainstorm(session.id);
        }

        if (context.mounted) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All history cleared')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing history: $e')),
          );
        }
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {

  const _ThemeModeTile({
    required this.value,
    required this.onChanged,
  });
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.brightness_auto),
          title: const Text('System'),
          trailing: Radio<ThemeMode>(
            value: ThemeMode.system,
            groupValue: value,
            onChanged: (v) => onChanged(v!),
          ),
          onTap: () => onChanged(ThemeMode.system),
        ),
        ListTile(
          leading: const Icon(Icons.brightness_high),
          title: const Text('Light'),
          trailing: Radio<ThemeMode>(
            value: ThemeMode.light,
            groupValue: value,
            onChanged: (v) => onChanged(v!),
          ),
          onTap: () => onChanged(ThemeMode.light),
        ),
        ListTile(
          leading: const Icon(Icons.brightness_2),
          title: const Text('Dark'),
          trailing: Radio<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: value,
            onChanged: (v) => onChanged(v!),
          ),
          onTap: () => onChanged(ThemeMode.dark),
        ),
      ],
    );
  }
}

class _TtsSpeedTile extends StatelessWidget {

  const _TtsSpeedTile({
    required this.value,
    required this.onChanged,
  });
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    const speeds = [0.75, 1.0, 1.25, 1.5];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TTS Speed',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: speeds.map((speed) {
              final isSelected = (value - speed).abs() < 0.01;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('${speed}x'),
                    selected: isSelected,
                    onSelected: (_) => onChanged(speed),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : null,
                      fontWeight: isSelected ? FontWeight.w700 : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SilenceTimeoutTile extends StatelessWidget {

  const _SilenceTimeoutTile({
    required this.value,
    required this.onChanged,
  });
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const presets = AppConstants.silenceTimeoutPresets;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Silence Timeout',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text(
            'How long to wait after you stop speaking',
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: presets.map((ms) {
              final isSelected = value == ms;
              final label = ms >= 1000 ? '${ms ~/ 1000}s' : '${ms}ms';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => onChanged(ms),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : null,
                      fontWeight: isSelected ? FontWeight.w700 : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _VoicePersonaTile extends StatelessWidget {

  const _VoicePersonaTile({
    required this.value,
    required this.onChanged,
  });
  final VoicePersona value;
  final ValueChanged<VoicePersona> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voice Persona',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: VoicePersonas.all.map((persona) {
              final isSelected = persona.id == value.id;
              return ChoiceChip(
                label: Text(persona.label.split(' —').first),
                selected: isSelected,
                onSelected: (_) => onChanged(persona),
                selectedColor: AppColors.primary.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : null,
                  fontWeight: isSelected ? FontWeight.w700 : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
