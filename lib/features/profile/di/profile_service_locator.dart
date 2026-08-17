import 'package:get_it/get_it.dart';
import '../../../shared/image_picker/service/profile_image_picker_service.dart';
import '../../passenger_profile/domain/repository/passenger_profile_repository.dart';
import '../presentation/bloc/profile_bloc.dart';

void initProfileDI(GetIt sl) {
  sl.registerFactory(
    () => ProfileBloc(
      passengerProfileRepository: sl<PassengerProfileRepository>(),
      imagePickerService: sl<ProfileImagePickerService>(),
    ),
  );
}
