import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/features/passenger_profile/domain/entity/passenger_entity.dart';
import 'package:passenger_app/features/profile/presentation/component/confirmation_popup.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/shared/presentation/component/app_version.dart';
import 'package:passenger_app/shared/presentation/component/custom_button.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/service_locator/main_service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/profile_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionState = context.read<SessionBloc>().state;
    final passengerId =
        sessionState is SessionAuthenticated ? sessionState.user.id : null;

    return BlocProvider(
      create:
          (_) =>
              mainServiceLocator<ProfileBloc>()
                ..add(ProfileLoadRequested(passengerId: passengerId ?? '')),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state.passenger == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar perfil',
                onPressed:
                    () => context.push(
                      editProfileRoute.route,
                      extra: context.read<ProfileBloc>(),
                    ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed(settingsRoute.name),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.appColors.backgroundGradient,
          ),
        ),
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state.isLoading && state.passenger == null) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            if (state.passenger == null) {
              return Center(
                child: Text(
                  state.errorMessage ??
                      'No se encontró información del pasajero',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              );
            }

            return _buildProfileContent(context, state.passenger!);
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, PassengerEntity passenger) {
    final colorScheme = Theme.of(context).colorScheme;
    final fullName = '${passenger.firstName} ${passenger.lastName}'.trim();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildAvatar(context, networkImageUrl: passenger.photoUrl),
            const SizedBox(height: 20),
            Text(
              fullName.isEmpty ? 'Pasajero' : fullName,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              passenger.email,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildInfoCard(context, passenger),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildSignOutButton(context),
            ),
            const SizedBox(height: 40),
            const AppVersionWidget(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, {required String? networkImageUrl}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.2),
          width: 4,
        ),
      ),
      child: CircleAvatar(
        radius: 60,
        backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
        backgroundImage:
            networkImageUrl != null ? NetworkImage(networkImageUrl) : null,
        child:
            networkImageUrl == null
                ? Icon(
                  Icons.person,
                  size: 60,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                )
                : null,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, PassengerEntity passenger) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _buildInfoTile(
            context,
            icon: Icons.badge_outlined,
            title: 'Nombres',
            value: passenger.firstName.isEmpty ? 'No registrado' : passenger.firstName,
            isFirst: true,
          ),
          Divider(
            height: 1,
            indent: 60,
            color: colorScheme.onSurface.withValues(alpha: 0.06),
          ),
          _buildInfoTile(
            context,
            icon: Icons.badge_outlined,
            title: 'Apellidos',
            value: passenger.lastName.isEmpty ? 'No registrado' : passenger.lastName,
          ),
          Divider(
            height: 1,
            indent: 60,
            color: colorScheme.onSurface.withValues(alpha: 0.06),
          ),
          _buildInfoTile(
            context,
            icon: Icons.email_outlined,
            title: 'Correo',
            value: passenger.email,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    bool isFirst = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 8.0 : 4.0, bottom: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return CustomButton(
      textButton: 'Cerrar sesión',
      onTap: () {
        ConfirmationPopup.show(context: context);
      },
    );
  }
}
