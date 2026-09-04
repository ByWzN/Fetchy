import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/widgets/fetchy_buttons.dart';
import '../../../../app/widgets/fetchy_rows.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../core/engine/engine_update_service.dart';
import '../../../../core/update/app_version.dart';
import '../../../../core/update/update_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../downloader/extraction_error_mapper.dart';
import '../../../downloader/extraction_error_presentation.dart';
import '../../last_extraction_error.dart';
import '../../upstream_links.dart';

/// Settings → Technical information → Developer information.
///
/// The detailed, structured counterpart to the plain-language "Why?"
/// dialog — for someone investigating an extraction problem, not a normal
/// user. Shows the most recent Fetch failure's real context (platform,
/// extractor, error category, sanitized message, the relevant known
/// limitation, and a possible upstream reference), all derived from the
/// same [MappedExtractionError]/[ExtractionFailureKind] system the rest of
/// the app uses — never a second, separate error model.
///
/// Never shown here: cookies, passwords, access tokens, authorization
/// headers, clipboard contents, or private session values. The only detail
/// text on this page is [MappedExtractionError.sanitizedDetails], which
/// already redacts those before this page ever sees it.
///
/// This screen's own UI chrome (labels, buttons, empty state) follows the
/// system language like everywhere else, but the "Copy technical details"
/// clipboard block is deliberately kept in English regardless of locale —
/// it is meant to be pasted into an upstream GitHub issue, where English
/// is what maintainers can act on.
class DeveloperInformationPage extends StatelessWidget {
  const DeveloperInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final MappedExtractionError? error = LastExtractionError.instance.error;
    final String? platform = LastExtractionError.instance.platform;

    return FetchyScaffold(
      title: strings.developerInfoTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.hero,
        ),
        children: <Widget>[
          Text(
            strings.developerInfoIntro,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (error == null)
            _EmptyState(strings: strings)
          else
            _FailureDetails(error: error, platform: platform, strings: strings),
          const SizedBox(height: AppSpacing.xl),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FetchyTonalButton(
              label: strings.developerInfoCopyTechnicalDetails,
              icon: Icons.copy_rounded,
              expand: false,
              onPressed: () => _copyTechnicalDetails(context, error, platform, strings),
            ),
          ),
        ],
      ),
    );
  }

  /// Deliberately English regardless of locale — see the class doc.
  Future<void> _copyTechnicalDetails(
    BuildContext context,
    MappedExtractionError? error,
    String? platform,
    AppLocalizations strings,
  ) async {
    final String ytDlpVersion = await EngineUpdateService.instance.getVersion() ?? 'Unavailable';
    final InstalledAppVersion? appVersion = await UpdateService.instance
        .installedVersion();
    final StringBuffer buffer = StringBuffer('Fetchy technical details\n');
    buffer.writeln(
      'App version: ${appVersion?.versionName ?? 'Unavailable'} '
      '(${appVersion?.versionCode ?? '?'})',
    );
    buffer.writeln('yt-dlp version: $ytDlpVersion');

    if (error == null) {
      buffer.writeln('No recent Fetch failure recorded this session.');
    } else {
      buffer.writeln('Platform: ${platform ?? 'Unknown'}');
      buffer.writeln('Extractor: ${_extractorFor(platform)}');
      buffer.writeln('Error category: ${error.kind.name}');
      buffer.writeln('Sanitized message: ${error.message}');
      buffer.writeln('Known limitation: ${extractionKnownLimitation(error.kind, strings)}');
      buffer.writeln('Possible upstream issue: ${_upstreamReferenceFor(error.kind, strings)}');
      buffer.writeln(
        'Detail: ${error.sanitizedDetails.isEmpty ? '(none)' : error.sanitizedDetails}',
      );
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.developerInfoTechnicalDetailsCopied)));
    }
  }
}

String _extractorFor(String? platform) {
  if (platform == null || platform.isEmpty) return 'Unknown';
  return platform.toLowerCase().replaceAll(RegExp(r'\s+'), '');
}

String _upstreamReferenceFor(ExtractionFailureKind kind, AppLocalizations strings) {
  if (!extractionMayHaveUpstreamIssue(kind)) return strings.developerInfoNotApplicable;
  final UpstreamLink issues = upstreamLinks.firstWhere(
    (UpstreamLink link) => link.label == 'yt-dlp' && link.kind == UpstreamLinkKind.issues,
  );
  return strings.developerInfoUpstreamIssueHint(issues.url);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return FetchyBanner(message: strings.developerInfoEmptyState);
  }
}

class _FailureDetails extends StatelessWidget {
  const _FailureDetails({required this.error, required this.platform, required this.strings});

  final MappedExtractionError error;
  final String? platform;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // This page is explicitly for someone investigating a failure, so it
    // stays denser and more technical than the rest of the app: an
    // aligned key/value block up top, then labelled prose sections, then
    // the raw sanitized detail in a monospace well.
    return FetchyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FetchyDetailRow(
            label: strings.developerInfoPlatformLabel,
            value: platform ?? strings.developerInfoUnknown,
          ),
          FetchyDetailRow(
            label: strings.developerInfoExtractorLabel,
            value: _extractorFor(platform),
            valueTextDirection: TextDirection.ltr,
          ),
          FutureBuilder<String?>(
            future: EngineUpdateService.instance.getVersion(),
            builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
              return FetchyDetailRow(
                label: strings.developerInfoVersionLabel,
                value: snapshot.data ?? strings.engineCheckingVersion,
                valueTextDirection: TextDirection.ltr,
              );
            },
          ),
          FutureBuilder<InstalledAppVersion?>(
            future: UpdateService.instance.installedVersion(),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<InstalledAppVersion?> snapshot,
                ) {
                  return FetchyDetailRow(
                    label: strings.developerInfoAppVersionLabel,
                    value: snapshot.data?.versionName ?? '—',
                    valueTextDirection: TextDirection.ltr,
                  );
                },
          ),
          FetchyDetailRow(
            label: strings.developerInfoErrorCategoryLabel,
            value: error.kind.name,
            valueTextDirection: TextDirection.ltr,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          _LabelledBlock(
            label: strings.developerInfoSanitizedMessageTitle,
            body: error.message,
            emphasize: true,
          ),
          _LabelledBlock(
            label: strings.developerInfoKnownLimitationTitle,
            body: extractionKnownLimitation(error.kind, strings),
          ),
          _LabelledBlock(
            label: strings.developerInfoUpstreamIssueTitle,
            body: _upstreamReferenceFor(error.kind, strings),
          ),
          Text(
            strings.developerInfoDetailTitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FetchySurface(
            tone: FetchyTone.sunken,
            borderRadius: AppShape.control,
            elevated: false,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                error.sanitizedDetails.isEmpty
                    ? strings.developerInfoNoAdditionalDetail
                    : error.sanitizedDetails,
                // Engine output is always Latin text; it stays
                // left-to-right even when the UI around it is Arabic.
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small caption above a paragraph of technical prose.
class _LabelledBlock extends StatelessWidget {
  const _LabelledBlock({
    required this.label,
    required this.body,
    this.emphasize = false,
  });

  final String label;
  final String body;

  /// The sanitized engine message itself gets full-contrast text; the
  /// surrounding explanations stay quieter.
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: emphasize ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
