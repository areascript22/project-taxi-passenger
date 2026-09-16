import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/shared/settings/domain/repository/settings_repository.dart';
import 'package:passenger_app/shared/settings/presentation/bloc/settings_bloc.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockSettingsRepository repository;

  setUpAll(() {
    registerFallbackValue(ThemeMode.system);
  });

  setUp(() {
    repository = _MockSettingsRepository();
  });

  SettingsBloc buildBloc() => SettingsBloc(repository: repository);

  test('el estado inicial está en loading con defaults en true/system', () {
    final state = buildBloc().state;
    expect(state.isLoading, isTrue);
    expect(state.voiceEnabled, isTrue);
    expect(state.vibrationEnabled, isTrue);
    expect(state.themeMode, ThemeMode.system);
  });

  group('LoadSettings', () {
    blocTest<SettingsBloc, SettingsState>(
      'carga los tres valores desde el repositorio',
      build: () {
        when(
          () => repository.isVoiceEnabled(),
        ).thenAnswer((_) async => const Right(false));
        when(
          () => repository.isVibrationEnabled(),
        ).thenAnswer((_) async => const Right(false));
        when(
          () => repository.getThemeMode(),
        ).thenAnswer((_) async => const Right(ThemeMode.dark));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadSettings()),
      expect: () => [
        isA<SettingsState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.voiceEnabled, 'voiceEnabled', isFalse)
            .having((s) => s.vibrationEnabled, 'vibrationEnabled', isFalse)
            .having((s) => s.themeMode, 'themeMode', ThemeMode.dark),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'cae a los defaults (true/true/system) si el repositorio falla en cada campo',
      build: () {
        when(() => repository.isVoiceEnabled()).thenAnswer(
          (_) async => Left(Failure(message: 'err')),
        );
        when(() => repository.isVibrationEnabled()).thenAnswer(
          (_) async => Left(Failure(message: 'err')),
        );
        when(() => repository.getThemeMode()).thenAnswer(
          (_) async => Left(Failure(message: 'err')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadSettings()),
      expect: () => [
        isA<SettingsState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.voiceEnabled, 'voiceEnabled', isTrue)
            .having((s) => s.vibrationEnabled, 'vibrationEnabled', isTrue)
            .having((s) => s.themeMode, 'themeMode', ThemeMode.system),
      ],
    );
  });

  group('ToggleVoice', () {
    blocTest<SettingsBloc, SettingsState>(
      'invierte voiceEnabled y persiste el nuevo valor',
      build: () {
        when(
          () => repository.setVoiceEnabled(any()),
        ).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      seed: () => const SettingsState(isLoading: false, voiceEnabled: true),
      act: (bloc) => bloc.add(ToggleVoice()),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.voiceEnabled,
          'voiceEnabled',
          isFalse,
        ),
      ],
      verify: (_) {
        verify(() => repository.setVoiceEnabled(false)).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'de false pasa a true',
      build: () {
        when(
          () => repository.setVoiceEnabled(any()),
        ).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      seed: () => const SettingsState(isLoading: false, voiceEnabled: false),
      act: (bloc) => bloc.add(ToggleVoice()),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.voiceEnabled,
          'voiceEnabled',
          isTrue,
        ),
      ],
      verify: (_) {
        verify(() => repository.setVoiceEnabled(true)).called(1);
      },
    );
  });

  group('ToggleVibration', () {
    blocTest<SettingsBloc, SettingsState>(
      'invierte vibrationEnabled y persiste el nuevo valor',
      build: () {
        when(
          () => repository.setVibrationEnabled(any()),
        ).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      seed: () =>
          const SettingsState(isLoading: false, vibrationEnabled: true),
      act: (bloc) => bloc.add(ToggleVibration()),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.vibrationEnabled,
          'vibrationEnabled',
          isFalse,
        ),
      ],
      verify: (_) {
        verify(() => repository.setVibrationEnabled(false)).called(1);
      },
    );
  });

  group('ChangeThemeMode', () {
    blocTest<SettingsBloc, SettingsState>(
      'actualiza themeMode y lo persiste',
      build: () {
        when(
          () => repository.setThemeMode(any()),
        ).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      act: (bloc) => bloc.add(ChangeThemeMode(ThemeMode.light)),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.themeMode,
          'themeMode',
          ThemeMode.light,
        ),
      ],
      verify: (_) {
        verify(() => repository.setThemeMode(ThemeMode.light)).called(1);
      },
    );
  });
}
