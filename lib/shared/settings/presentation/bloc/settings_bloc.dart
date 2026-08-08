import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../domain/repository/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;

  SettingsBloc({required this.repository}) : super(const SettingsState()) {
    on<LoadSettings>(_onLoad);
    on<ToggleVoice>(_onToggleVoice);
    on<ToggleVibration>(_onToggleVibration);
  }

  Future<void> _onLoad(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));

    final voiceResult = await repository.isVoiceEnabled();
    final vibrationResult = await repository.isVibrationEnabled();

    emit(
      state.copyWith(
        isLoading: false,
        voiceEnabled: voiceResult.fold((_) => true, (enabled) => enabled),
        vibrationEnabled: vibrationResult.fold(
          (_) => true,
          (enabled) => enabled,
        ),
      ),
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
