part of 'settings_bloc.dart';

@immutable
class SettingsState {
  final bool isLoading;
  final bool voiceEnabled;
  final bool vibrationEnabled;
  final ThemeMode themeMode;

  const SettingsState({
    this.isLoading = true,
    this.voiceEnabled = true,
    this.vibrationEnabled = true,
    this.themeMode = ThemeMode.system,
  });

  SettingsState copyWith({
    bool? isLoading,
    bool? voiceEnabled,
    bool? vibrationEnabled,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
