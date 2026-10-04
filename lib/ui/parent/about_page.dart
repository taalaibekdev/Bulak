import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_config.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../state/library_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/brand_mark.dart';
import '../widgets/common.dart';

/// О приложении: версия, юридические ссылки, полное удаление данных.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const AboutPage());

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Center(
            child: Column(
              children: [
                const BrandMark(size: 88),
                const SizedBox(height: 16),
                Text(strings.appName, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  strings.tagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final version = info == null
                        ? AppConfig.versionName
                        : '${info.version} (${info.buildNumber})';
                    return PillBadge(
                      label: '${strings.aboutVersion} $version',
                      background: theme.colorScheme.surfaceContainerHighest,
                      foreground: theme.colorScheme.onSurfaceVariant,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _InfoCard(
            icon: Icons.privacy_tip_rounded,
            title: strings.aboutDataTitle,
            body: strings.aboutDataBody,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.play_circle_outline_rounded,
            title: 'YouTube',
            body: strings.aboutYouTubeNotice,
          ),
          const SizedBox(height: 20),
          _LinkTile(
            icon: Icons.privacy_tip_outlined,
            label: strings.aboutPrivacy,
            url: AppConfig.privacyPolicyUrl,
          ),
          _LinkTile(
            icon: Icons.gavel_rounded,
            label: strings.aboutTerms,
            url: AppConfig.termsOfUseUrl,
          ),
          _LinkTile(
            icon: Icons.mail_outline_rounded,
            label: strings.aboutSupport,
            url: 'mailto:${AppConfig.supportEmail}',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            icon: const Icon(Icons.delete_forever_rounded),
            label: Text(strings.aboutReset),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              '${AppConfig.brandName} · ${AppConfig.applicationId}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final strings = AppStrings.of(context);
    final settings = context.read<SettingsController>();
    final library = context.read<LibraryController>();

    final confirmed = await showConfirmDialog(
      context,
      title: strings.aboutResetTitle,
      body: strings.aboutResetBody,
      destructive: true,
      icon: Icons.warning_amber_rounded,
    );
    if (!confirmed) return;

    await library.resetAll();
    await settings.resetAll();
    if (!context.mounted) return;
    showAppSnack(context, strings.aboutResetDone, icon: Icons.check_rounded);
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.blue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.label, required this.url});

  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(label),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      onTap: () async {
        final uri = Uri.parse(url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          if (!context.mounted) return;
          showAppSnack(context, AppStrings.of(context).somethingWentWrong);
        }
      },
    );
  }
}
