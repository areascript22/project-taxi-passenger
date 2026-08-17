import 'package:get_it/get_it.dart';
import '../../../shared/image_picker/service/profile_image_picker_service.dart';
import '../data/repository/passenger_profile_repository_impl.dart';
import '../domain/repository/passenger_profile_repository.dart';
import '../presentation/bloc/passenger_onboarding_bloc.dart';

void initPassengerProfileDI(GetIt sl) {
  sl.registerLazySingleton<PassengerProfileRepository>(
    () => PassengerProfileRepositoryImpl(),
  );
  sl.registerFactory(
    () => PassengerOnboardingBloc(
      passengerProfileRepository: sl<PassengerProfileRepository>(),
      imagePickerService: sl<ProfileImagePickerService>(),
    ),
  );
}
