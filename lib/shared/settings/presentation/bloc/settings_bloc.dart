import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:passenger_app/core/l10n/app_language.dart';
import 'package:passenger_app/features/passenger_profile/domain/repository/passenger_profile_repository.dart';
import 'package:passenger_app/shared/domain/repository/session_repository.dart';
import '../../domain/repository/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;

  // Para avisarle al backend en qué idioma mandarle los push a este
  // pasajero: el copy de las notificaciones lo arma el server, así que la
  // preferencia tiene que viajar hasta su documento de Firestore (ver
  // CLAUDE.md seccion 10.1). La sesión es lo que da el uid del documento.
  final PassengerProfileRepository profileRepository;
  final SessionRepository sessionRepository;

  SettingsBloc({
    required this.repository,
    required this.profileRepository,
    required this.sessionRepository,
  }) : super(const SettingsState()) {
    on<LoadSettings>(_onLoad);
    on<ToggleVoice>(_onToggleVoice);
    on<ToggleVibration>(_onToggleVibration);
    on<ChangeThemeMode>(_onChangeThemeMode);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  Future<void> _onLoad(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));

    final voiceResult = await repository.isVoiceEnabled();
    final vibrationResult = await repository.isVibrationEnabled();
    final themeModeResult = await repository.getThemeMode();
    final languageResult = await repository.getLanguage();

    emit(
      state.copyWith(
        isLoading: false,
        voiceEnabled: voiceResult.fold((_) => true, (enabled) => enabled),
        vibrationEnabled: vibrationResult.fold(
          (_) => true,
          (enabled) => enabled,
        ),
        themeMode: themeModeResult.fold(
          (_) => ThemeMode.system,
          (mode) => mode,
        ),
        language: languageResult.fold(
          (_) => AppLanguage.system,
          (language) => language,
        ),
      ),
    );
  }

  Future<void> _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(themeMode: event.themeMode));
    await repository.setThemeMode(event.themeMode);
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(language: event.language));
    await repository.setLanguage(event.language);
    await _syncPushLanguage(event.language);
  }

  // El idioma de los push se escribe ACÁ y no solo al arrancar la app: si
  // esperáramos al próximo arranque, el pasajero que acaba de elegir inglés
  // seguiría recibiendo notificaciones en español justo después de pedir lo
  // contrario.
  //
  // Fire-and-forget deliberado: el fallo ya quedó en el debugPrint del
  // repositorio y no hay nada que el pasajero pueda hacer al respecto. El
  // idioma de la app (lo que sí ve) ya se emitió y se persistió localmente.
  Future<void> _syncPushLanguage(AppLanguage language) async {
    final sessionResult = await sessionRepository.isUserAuthenticated();
    final user = sessionResult.fold((_) => null, (user) => user);
    // Sin sesión no hay documento donde escribir. No es un error: lo resuelve
    // el próximo login, que registra token e idioma juntos.
    if (user == null) return;

    await profileRepository.updateLanguage(
      passengerId: user.id,
      language: resolveSystemAppLocale(preference: language).languageCode,
    );
  }

  Future<void> _onToggleVoice(
    ToggleVoice event,
    Emitter<SettingsState> emit,
  ) async {
    final newValue = !state.voiceEnabled;
    emit(state.copyWith(voiceEnabled: newValue));
    await repository.setVoiceEnabled(newValue);
  }

  Future<void> _onToggleVibration(
    ToggleVibration event,
    Emitter<SettingsState> emit,
  ) async {
    final newValue = !state.vibrationEnabled;
    emit(state.copyWith(vibrationEnabled: newValue));
    await repository.setVibrationEnabled(newValue);
  }
}
