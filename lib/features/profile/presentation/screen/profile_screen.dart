import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/features/profile/presentation/component/confirmation_popup.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/shared/presentation/component/app_version.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/entity/user_entity.dart';
import '../../../../shared/presentation/component/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileView();
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
        child: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, state) {
            if (state is SessionAuthenticated) {
              return _buildProfileContent(context, state.user);
            }

            return Center(
              child: Text(
                "No se encontró información del usuario",
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserEntity user) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Profile Avatar
            Container(
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
                    user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child:
                    user.photoUrl == null
                        ? Icon(
                          Icons.person,
                          size: 60,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        )
                        : null,
              ),
            ),

            const SizedBox(height: 24),

            // Display Name
            Text(
              user.displayName ?? 'Usuario Sin Nombre',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            // Email (Primary Subtitle)
            Text(
              user.email ?? 'Sin correo electrónico',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 40),

            // Info Cards Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoTile(
                      context,
                      icon: Icons.fingerprint,
                      title: 'ID de Usuario',
                      value: user.id,
                      isFirst: true,
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
                      value: user.email ?? 'No disponible',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Sign Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: CustomButton(
                textButton: "Cerrar sesión",
                onTap: () {
                  ConfirmationPopup.show(context: context);
                },
              ),
            ),

            const SizedBox(height: 40),
            AppVersionWidget(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Reusable widget for profile rows
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
}
