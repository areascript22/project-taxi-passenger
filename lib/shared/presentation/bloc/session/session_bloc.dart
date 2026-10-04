import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:passenger_app/features/passenger_profile/domain/entity/passenger_entity.dart';
import 'package:passenger_app/features/passenger_profile/domain/repository/passenger_profile_repository.dart';
import 'package:passenger_app/features/ride_tracking/domain/entity/ride_entity.dart';
import 'package:passenger_app/features/ride_tracking/domain/repository/ride_tracking_repository.dart';
import 'package:passenger_app/core/l10n/app_language.dart';
import 'package:passenger_app/shared/domain/repository/session_repository.dart';
import 'package:passenger_app/shared/notifications/service/push_notifications_service.dart';
import 'package:passenger_app/shared/settings/domain/repository/settings_repository.dart';
import '../../../domain/entity/user_entity.dart';

part 'session_event.dart';
part 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final SessionRepository sessionRepository;
  final RideTrackingRepository rideTrackingRepository;
  final PassengerProfileRepository passengerProfileRepository;
  final PushNotificationsService pushNotificationsService;
  final SettingsRepository settingsRepository;

  StreamSubscription<String>? _tokenRefreshSub;

  SessionBloc({
    required this.sessionRepository,
    required this.rideTrackingRepository,
    required this.passengerProfileRepository,
    required this.pushNotificationsService,
    required this.settingsRepository,
  }) : super(SessionUnknown()) {
    on<SessionCheckRequested>(_onCheckRequested);
    on<SessionLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    SessionCheckRequested event,
    Emitter<SessionState> emit,
  ) async {
    final result = await sessionRepository.isUserAuthenticated();

    final user = result.fold((failure) => null, (user) => user);
    if (user == null) {
      emit(SessionUnauthenticated());
      return;
    }

    final passengerResult = await passengerProfileRepository.getPassenger(
      passengerId: user.id,
    );
    if (passengerResult.isLeft()) {
      emit(SessionCheckFailed(user: user));
      return;
    }

    final PassengerEntity? passenger = passengerResult.fold(
      (_) => null,
      (value) => value,
    );
    if (passenger == null) {
      emit(SessionOnboardingRequired(user: user));
      return;
    }

    final activeRideResult = await rideTrackingRepository.getActiveRide();
    final activeRide = activeRideResult.fold((_) => null, (ride) => ride);

    emit(SessionAuthenticated(user: user, activeRide: activeRide));

    unawaited(_registerPushToken(passengerId: user.id));
  }

  // Fire-and-forget: si falla, el pasajero simplemente no recibirá push
  // hasta el siguiente chequeo de sesión -- no debe bloquear ni afectar el
  // flujo de autenticación.
  Future<void> _registerPushToken({required String passengerId}) async {
    final tokenResult = await pushNotificationsService.getToken();
    final token = tokenResult.fold((_) => null, (token) => token);
    if (token != null) {
      await passengerProfileRepository.updateFcmToken(
        passengerId: passengerId,
        token: token,
        language: await _resolvePushLanguage(),
      );
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = pushNotificationsService.onTokenRefresh.listen((
      newToken,
    ) async {
      passengerProfileRepository.updateFcmToken(
        passengerId: passengerId,
        token: newToken,
        // Se resuelve de nuevo (y no se reusa el de arriba) porque el refresh
        // puede llegar mucho después, con el idioma ya cambiado en Ajustes.
        language: await _resolvePushLanguage(),
      );
    });
  }

  // Idioma en el que el backend debe armarle los push a ESTE pasajero.
  // Se guarda ya resuelto ('es'/'en'): el server no puede resolver "seguir al
  // dispositivo". Si la lectura falla se asume el default, que es justo lo
  // que el server usa cuando el campo no está.
  Future<String> _resolvePushLanguage() async {
    final result = await settingsRepository.getLanguage();
    final preference = result.fold((_) => AppLanguage.system, (value) => value);

    return resolveSystemAppLocale(preference: preference).languageCode;
  }

  @override
  Future<void> close() {
    _tokenRefreshSub?.cancel();
    return super.close();
  }

  Future<void> _onLogoutRequested(
    SessionLogoutRequested event,
    Emitter<SessionState> emit,
  ) async {
    final response = await sessionRepository.signOut();
    response.fold(
      (failure) => debugPrint('SessionDebug | Error en logout: ${failure.code}'),
      (unit) => emit(SessionUnauthenticated()),
    );
  }
}
