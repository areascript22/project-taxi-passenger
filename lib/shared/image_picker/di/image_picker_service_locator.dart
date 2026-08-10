import 'package:get_it/get_it.dart';
import '../service/profile_image_picker_service.dart';
import '../service/profile_image_picker_service_impl.dart';

void initImagePickerDI(GetIt sl) {
  sl.registerFactory<ProfileImagePickerService>(
    () => ProfileImagePickerServiceImpl(),
  );
}
