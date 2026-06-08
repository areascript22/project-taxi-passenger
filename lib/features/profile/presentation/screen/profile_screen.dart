import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';
import '../../../../shared/domain/entity/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // Soft gray background for contrast
      body: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SessionAuthenticated) {
            return _buildProfileContent(state.user);
          }

          return const Center(
            child: Text("No se encontró información del usuario"),
          );
        },
      ),
    );
  }

  Widget _buildProfileContent(UserEntity user) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Profile Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage:
                    user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child:
                    user.photoUrl == null
                        ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF94A3B8),
                        )
                        : null,
              ),
            ),

            const SizedBox(height: 24),

            // Display Name
            Text(
              user.displayName ?? 'Usuario Sin Nombre',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B), // Dark slate
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            // Email (Primary Subtitle)
            Text(
              user.email ?? 'Sin correo electrónico',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B), // Medium slate
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 40),

            // Info Cards Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.fingerprint,
                      title: 'ID de Usuario',
                      value: user.id,
                      isFirst: true,
                    ),
                    const Divider(
                      height: 1,
                      indent: 60,
                      color: Color(0xFFF1F5F9),
                    ),
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      title: 'Correo',
                      value: user.email ?? 'No disponible',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable widget for profile rows
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    bool isFirst = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 8.0 : 4.0, bottom: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF), // Light blue tint
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3B82F6),
            size: 24,
          ), // Blue icon
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}
