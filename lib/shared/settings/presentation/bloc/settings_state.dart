part of 'settings_bloc.dart';

@immutable
class SettingsState {
  final bool isLoading;
  final bool voiceEnabled;
  final bool vibrationEnabled;

  const SettingsState({
    this.isLoading = true,
    this.voiceEnabled = true,
    this.vibrationEnabled = true,
  });

  SettingsState copyWith({
    bool? isLoading,
    bool? voiceEnabled,
    bool? vibrationEnabled,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}
