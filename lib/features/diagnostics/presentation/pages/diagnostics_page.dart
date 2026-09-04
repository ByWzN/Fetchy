import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/widgets/fetchy_rows.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../core/platform/file_action_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../upstream_links.dart';
import 'developer_information_page.dart';

/// Settings → Technical information.
///
/// Three short sections and nothing else: why a download can fail in
/// general terms, a door into the detailed developer view for whoever
/// wants it, and links to the upstream projects. Engine/version
/// information lives only in Settings → About now (see [EngineInfoTile]),
/// never repeated here. Anything tied to one specific failure (platform,
/// error category, sanitized message) lives on [DeveloperInformationPage]
/// instead of being repeated here — this page states facts that are true
/// regardless of what just failed.
class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyScaffold(
      title: strings.technicalInformationTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.hero,
        ),
        children: <Widget>[
          _buildLimitationsSection(context, strings),
          const SizedBox(height: AppSpacing.xxl),
          _buildDeveloperInformationEntry(context, strings),
          const SizedBox(height: AppSpacing.xxl),
          _buildUpstreamResourcesSection(context, strings),
        ],
      ),
    );
  }

  /// Plain-language, user-facing content: what can go wrong and why. Kept
  /// as an informational banner rather than a card, because it is guidance
  /// rather than a list of things to act on.
  Widget _buildLimitationsSection(BuildContext context, AppLocalizations strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FetchySectionHeader(
          icon: Icons.report_problem_outlined,
          title: strings.diagnosticsLimitationsTitle,
        ),
        FetchyBanner(message: strings.diagnosticsLimitationsBody),
      ],
    );
  }

  Widget _buildDeveloperInformationEntry(BuildContext context, AppLocalizations strings) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FetchySectionHeader(
          icon: Icons.code_rounded,
          title: strings.diagnosticsDeveloperInfoTitle,
        ),
        FetchyGroup(
          children: <Widget>[
            FetchyListRow(
              leading: const FetchyLeadingIcon(icon: Icons.terminal_rounded),
              title: strings.diagnosticsDeveloperInfoTitle,
              subtitle: strings.diagnosticsDeveloperInfoSubtitle,
              showChevron: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const DeveloperInformationPage(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
          child: Text(
            strings.diagnosticsSessionsPrivacy,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpstreamResourcesSection(BuildContext context, AppLocalizations strings) {
    return FetchyGroup(
      title: strings.diagnosticsUpstreamResourcesTitle,
      icon: Icons.link_rounded,
      children: <Widget>[
        for (final UpstreamLink link in upstreamLinks)
          _UpstreamLinkRow(link: link),
      ],
    );
  }
}

class _UpstreamLinkRow extends StatelessWidget {
  const _UpstreamLinkRow({required this.link});

  final UpstreamLink link;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyListRow(
      leading: const FetchyLeadingIcon(icon: Icons.open_in_new_rounded),
      title: link.label,
      subtitle: _descriptionFor(link.kind, strings),
      onTap: () => FileActionService.instance.openExternalUrl(link.url),
    );
  }

  String _descriptionFor(UpstreamLinkKind kind, AppLocalizations strings) {
    switch (kind) {
      case UpstreamLinkKind.repository:
        return strings.upstreamYtDlpRepo;
      case UpstreamLinkKind.issues:
        return strings.upstreamYtDlpIssues;
      case UpstreamLinkKind.documentation:
        return strings.upstreamDocumentation;
    }
  }
}
