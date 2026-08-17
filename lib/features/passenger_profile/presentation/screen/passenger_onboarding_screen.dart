import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/service_locator/main_service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/entity/user_entity.dart';
import '../../../../shared/presentation/bloc/session/session_bloc.dart';
import '../../../../shared/presentation/component/app_text_field.dart';
import '../../../../shared/presentation/component/custom_button.dart';
import '../../../../shared/presentation/component/image_source_sheet.dart';
import '../../../../shared/presentation/component/profile_avatar_picker.dart';
import '../bloc/passenger_onboarding_bloc.dart';

class PassengerOnboardingScreen extends StatelessWidget {
  final UserEntity user;

  const PassengerOnboardingScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              mainServiceLocator<PassengerOnboardingBloc>()
                ..add(PassengerOnboardingStarted(user)),
      child: PassengerOnboardingView(user: user),
    );
  }
}

class PassengerOnboardingView extends StatefulWidget {
  final UserEntity user;

  const PassengerOnboardingView({super.key, required this.user});

  @override
  State<PassengerOnboardingView> createState() =>
      _PassengerOnboardingViewState();
}

class _PassengerOnboardingViewState extends State<PassengerOnboardingView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final nameParts = (widget.user.displayName ?? '').trim().split(' ');
    _firstNameController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts.first : '',
    );
    _lastNameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    _emailController = TextEditingController(text: widget.user.email ?? '');
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
    context.read<PassengerOnboardingBloc>().add(
      PassengerOnboardingImagePicked(source),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    context.read<PassengerOnboardingBloc>().add(
      PassengerOnboardingSubmitted(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: BlocConsumer<PassengerOnboardingBloc, PassengerOnboardingState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
            if (state.registrationSuccess) {
              context.goNamed(sessionRoute.name);
            }
          },
          builder: (context, state) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: context.appColors.backgroundGradient,
                ),
              ),
              child: SafeArea(
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
                              Text(
                                'Completa tu perfil',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cuéntanos quién eres para poder identificarte en tus viajes.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Center(
                                child: ProfileAvatarPicker(
                                  localImage: state.profileImage,
                                  networkImageUrl: widget.user.photoUrl,
                                  isLoading: state.isPickingImage,
                                  onTap: _pickImage,
                                ),
                              ),
                              const SizedBox(height: 32),
                              AppTextField(
                                label: 'Nombres',
                                controller: _firstNameController,
                                textCapitalization: TextCapitalization.words,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa tus nombres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Apellidos',
                                controller: _lastNameController,
                                textCapitalization: TextCapitalization.words,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa tus apellidos';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Correo electrónico',
                                controller: _emailController,
                                enabled: false,
                              ),
                              const SizedBox(height: 32),
                              CustomButton(
                                textButton:
                                    state.isSubmitting
                                        ? 'Guardando...'
                                        : 'Continuar',
                                backgroundColor: colorScheme.primary,
                                onTap: state.isSubmitting ? null : _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<SessionBloc>().add(
                          SessionLogoutRequested(),
                        );
                        context.goNamed(signInRoute.name);
                      },
                      child: Text(
                        '¿No eres tú? Cerrar sesión',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
