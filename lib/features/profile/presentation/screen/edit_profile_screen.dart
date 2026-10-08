import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/shared/presentation/component/app_text_field.dart';
import 'package:passenger_app/shared/presentation/component/app_toast.dart';
import 'package:passenger_app/shared/presentation/component/custom_button.dart';
import 'package:passenger_app/shared/presentation/component/image_source_sheet.dart';
import 'package:passenger_app/shared/presentation/component/profile_avatar_picker.dart';
import 'package:passenger_app/shared/presentation/failure_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/profile_bloc.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final passenger = context.read<ProfileBloc>().state.passenger;
    if (passenger != null) {
      _firstNameController.text = passenger.firstName;
      _lastNameController.text = passenger.lastName;
      _emailController.text = passenger.email;
    }
    // Limpia cualquier imagen local o error que haya quedado de un intento
    // anterior de edición (el ProfileBloc es la misma instancia que la de
    // ProfileScreen, sigue viva mientras esta screen esté pusheada encima).
    context.read<ProfileBloc>().add(ProfileEditStarted());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await ImageSourceSheet.show(context);
    if (source == null || !mounted) return;
    context.read<ProfileBloc>().add(ProfileImagePicked(source));
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<ProfileBloc>().add(
      ProfileUpdateSubmitted(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileEdit)),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.appColors.backgroundGradient,
          ),
        ),
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state.errorCode != null) {
              AppToast.error(context, message: context.failureText(state.errorCode!));
            }
            if (state.updateSuccess) {
              // Toast antes del pop: al estar en el overlay raíz sigue visible
              // después de volver a la pantalla anterior.
              AppToast.success(context, message: l10n.profileUpdated);
              context.pop();
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: ProfileAvatarPicker(
                                localImage: state.localImage,
                                networkImageUrl: state.passenger?.photoUrl,
                                isLoading: state.isPickingImage,
                                onTap: _pickImage,
                              ),
                            ),
                            const SizedBox(height: 32),
                            AppTextField(
                              label: l10n.fieldFirstName,
                              controller: _firstNameController,
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.validationFirstName;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: l10n.fieldLastName,
                              controller: _lastNameController,
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.validationLastName;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: l10n.commonEmail,
                              controller: _emailController,
                              enabled: false,
                            ),
                            const SizedBox(height: 32),
                            CustomButton(
                              textButton:
                                  state.isSubmitting
                                      ? l10n.commonSaving
                                      : l10n.commonSave,
                              backgroundColor: colorScheme.primary,
                              onTap: state.isSubmitting ? null : _save,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
