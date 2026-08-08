part of 'settings_bloc.dart';

@immutable
sealed class SettingsEvent {}

class LoadSettings extends SettingsEvent {}

class ToggleVoice extends SettingsEvent {}

class ToggleVibration extends SettingsEvent {}
