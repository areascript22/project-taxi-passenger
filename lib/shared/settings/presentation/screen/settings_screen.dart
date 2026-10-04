import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/core/l10n/app_language.dart';
import 'package:passenger_app/core/routing/app_routes.dart';
import 'package:passenger_app/core/service_locator/main_service_locator.dart';
import 'package:passenger_app/core/theme/app_colors.dart';
import 'package:passenger_app/l10n/app_localizations.dart';
import 'package:passenger_app/shared/account/presentation/component/delete_account_confirm_dialog.dart';
import 'package:passenger_app/shared/account/presentation/cubit/account_cubit.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/shared/presentation/component/app_toast.dart';
import 'package:passenger_app/shared/presentation/failure_text.dart';
import '../bloc/settings_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AccountCubit>(
      create: (_) => mainServiceLocator<AccountCubit>(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<AccountCubit, AccountState>(
          listener: (context, state) {
            if (state.wasDeleted) {
              // El toast vive en el overlay raíz, así que sobrevive al logout
              // y a la navegación al login que vienen justo después.
              AppToast.success(
                context,
                message: l10n.deleteAccountSuccess,
              );
              context.read<SessionBloc>().add(SessionLogoutRequested());
            } else if (state.errorCode != null) {
              AppToast.error(context, message: context.failureText(state.errorCode!));
            }
          },
        ),
        // La propia SessionBloc ya hace el signOut de Firebase al recibir
        // SessionLogoutRequested (ver ConfirmationPopup, mismo patrón para el
        // logout normal) -- acá solo navegamos cuando confirma que ya quedó
        // sin sesión.
        BlocListener<SessionBloc, SessionState>(
          listener: (context, state) {
            if (state is SessionUnauthenticated) {
              context.goNamed(sessionRoute.name);
            }
          },
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.appColors.backgroundGradient,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              l10n.settingsTitle,
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
          body: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              if (state.isLoading) {
                return Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(text: l10n.settingsSectionAppearance),
                    const SizedBox(height: 12),
                    _ThemeModeSelector(themeMode: state.themeMode),
                    const SizedBox(height: 28),
                    _SectionLabel(text: l10n.settingsSectionLanguage),
                    const SizedBox(height: 12),
                    _LanguageSelector(language: state.language),
                    const SizedBox(height: 28),
                    _SectionLabel(text: l10n.settingsSectionNotifications),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildToggleTile(
                            context,
                            icon: Icons.record_voice_over_rounded,
                            title: l10n.settingsVoiceTitle,
                            subtitle: l10n.settingsVoiceSubtitle,
                            value: state.voiceEnabled,
                            onChanged:
                                (_) => context.read<SettingsBloc>().add(
                                  ToggleVoice(),
                                ),
                          ),
                          Divider(
                            height: 1,
                            indent: 60,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.06,
                            ),
                          ),
                          _buildToggleTile(
                            context,
                            icon: Icons.vibration_rounded,
                            title: l10n.settingsVibrationTitle,
                            subtitle: l10n.settingsVibrationSubtitle,
                            value: state.vibrationEnabled,
                            onChanged:
                                (_) => context.read<SettingsBloc>().add(
                                  ToggleVibration(),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SectionLabel(text: l10n.settingsSectionAccount),
                    const SizedBox(height: 12),
                    BlocBuilder<AccountCubit, AccountState>(
                      builder: (context, accountState) {
                        return _DeleteAccountTile(
                          isDeleting: accountState.isDeleting,
                          onTap: () async {
                            final confirmed =
                                await DeleteAccountConfirmDialog.show(context);
                            if (confirmed == true && context.mounted) {
                              context.read<AccountCubit>().deleteAccount();
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      activeColor: colorScheme.primary,
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: 12,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode themeMode;

  const _ThemeModeSelector({required this.themeMode});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          _ThemeModeOption(
            icon: Icons.dark_mode_rounded,
            label: l10n.settingsThemeDark,
            selected: themeMode == ThemeMode.dark,
            onTap:
                () => context.read<SettingsBloc>().add(
                  ChangeThemeMode(ThemeMode.dark),
                ),
          ),
          _ThemeModeOption(
            icon: Icons.light_mode_rounded,
            label: l10n.settingsThemeLight,
            selected: themeMode == ThemeMode.light,
            onTap:
                () => context.read<SettingsBloc>().add(
                  ChangeThemeMode(ThemeMode.light),
                ),
          ),
          _ThemeModeOption(
            icon: Icons.settings_suggest_rounded,
            label: l10n.settingsThemeSystem,
            selected: themeMode == ThemeMode.system,
            onTap:
                () => context.read<SettingsBloc>().add(
                  ChangeThemeMode(ThemeMode.system),
                ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeModeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color:
                    selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountTile extends StatelessWidget {
  final bool isDeleting;
  final VoidCallback onTap;

  const _DeleteAccountTile({required this.isDeleting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.delete_forever_rounded,
            color: colorScheme.error,
            size: 22,
          ),
        ),
        title: Text(
          l10n.deleteAccountTitle,
          style: TextStyle(
            color: colorScheme.error,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          l10n.deleteAccountSubtitle,
          style: TextStyle(
            color: colorScheme.error.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        trailing:
            isDeleting
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.error,
                  ),
                )
                : null,
        onTap: isDeleting ? null : onTap,
      ),
    );
  }
}

// Mismo contenedor y mismas pills que _ThemeModeSelector, pero sin icono: un
// idioma no tiene un icono que lo represente sin caer en banderas, que mapean
// paises y no idiomas (el espanol no es "Espania").
class _LanguageSelector extends StatelessWidget {
  final AppLanguage language;

  const _LanguageSelector({required this.language});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          _LanguageOption(
            label: l10n.settingsLanguageSystem,
            selected: language == AppLanguage.system,
            onTap:
                () => context.read<SettingsBloc>().add(
                  ChangeLanguage(AppLanguage.system),
                ),
          ),
          _LanguageOption(
            label: l10n.settingsLanguageSpanish,
            selected: language == AppLanguage.spanish,
            onTap:
                () => context.read<SettingsBloc>().add(
                  ChangeLanguage(AppLanguage.spanish),
                ),
          ),
          _LanguageOption(
            label: l10n.settingsLanguageEnglish,
            selected: language == AppLanguage.english,
            onTap:
                () => context.read<SettingsBloc>().add(
                  ChangeLanguage(AppLanguage.english),
                ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
