import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/widgets/fetchy_buttons.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../core/engine/engine_update_service.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Settings → About → Engine: the one and only place the yt-dlp runtime
/// version and update control live. Shows the actual active version and
/// lets the user manually check for an update — reusing
/// [EngineUpdateService], the same version/update path the automatic
/// startup update already uses. Purely additive: it never touches
/// extraction, downloads, or any other engine behavior.
///
/// Laid out like the "App version" row beside it (leading icon, title,
/// content) rather than as its own card, since there is exactly one Engine
/// entry in Settings now.
class EngineInfoTile extends StatefulWidget {
  const EngineInfoTile({super.key});

  @override
  State<EngineInfoTile> createState() => _EngineInfoTileState();
}

enum _UpdatePhase { idle, updating, updated, alreadyUpToDate, verificationFailed, failed }

class _EngineInfoTileState extends State<EngineInfoTile> {
  final EngineUpdateService _engine = EngineUpdateService.instance;

  String? _version;
  bool _versionLoading = true;
  _UpdatePhase _phase = _UpdatePhase.idle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  /// Only reads the version already-initialized engine warm-up produced —
  /// never triggers engine initialization itself, so opening Settings
  /// never makes app startup slower or starts work that would not already
  /// be happening.
  Future<void> _loadVersion() async {
    final String? version = await _engine.getVersion();
    if (!mounted) return;
    setState(() {
      _version = version;
      _versionLoading = false;
    });
  }

  Future<void> _runUpdate() async {
    setState(() {
      _phase = _UpdatePhase.updating;
      _errorMessage = null;
    });

    try {
      final EngineUpdateResult result = await _engine.update();
      if (!mounted) return;
      setState(() {
        switch (result.kind) {
          case EngineUpdateResultKind.updated:
            _phase = _UpdatePhase.updated;
            _version = result.version;
          case EngineUpdateResultKind.alreadyUpToDate:
            _phase = _UpdatePhase.alreadyUpToDate;
            _version = result.version;
          case EngineUpdateResultKind.verificationFailed:
            _phase = _UpdatePhase.verificationFailed;
        }
      });
    } on EngineUpdateFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _phase = _UpdatePhase.failed;
        _errorMessage = failure.message;
      });
    }
  }

  String _buttonLabel(AppLocalizations strings) {
    switch (_phase) {
      case _UpdatePhase.updating:
        return strings.engineUpdating;
      case _UpdatePhase.failed:
        return strings.commonRetry;
      case _UpdatePhase.idle:
      case _UpdatePhase.updated:
      case _UpdatePhase.alreadyUpToDate:
      case _UpdatePhase.verificationFailed:
        return strings.engineCheckForUpdates;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool busy = _phase == _UpdatePhase.updating;
    final (String, TextStyle?)? status = _statusText(colorScheme, strings);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const FetchyLeadingIcon(icon: Icons.code_rounded),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.engineTileTitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _versionLoading
                      ? '${strings.engineYtDlpLabel} · ${strings.engineCheckingVersion}'
                      : '${strings.engineYtDlpLabel} · '
                            '${strings.engineCurrentVersion(_version ?? strings.engineVersionUnknown)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  strings.engineBundledInfo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (status != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(status.$1, style: status.$2),
                ],
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FetchyTonalButton(
                    label: _buttonLabel(strings),
                    icon: Icons.sync_rounded,
                    expand: false,
                    height: 40,
                    busy: busy,
                    onPressed: busy ? null : _runUpdate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// (message, style) for the current phase, or null when there's nothing
  /// to say beyond the version line itself. [_errorMessage] (when present)
  /// comes straight from the native failure and is deliberately left as-is
  /// rather than localized — see [EngineUpdateFailure].
  (String, TextStyle?)? _statusText(ColorScheme colorScheme, AppLocalizations strings) {
    final TextStyle? base = Theme.of(context).textTheme.bodySmall;
    switch (_phase) {
      case _UpdatePhase.idle:
        return null;
      case _UpdatePhase.updating:
        return (strings.engineUpdatingStatus, base?.copyWith(color: colorScheme.onSurfaceVariant));
      case _UpdatePhase.alreadyUpToDate:
        return (
          strings.engineAlreadyUpToDate,
          base?.copyWith(color: colorScheme.onSurfaceVariant),
        );
      case _UpdatePhase.updated:
        return (
          strings.engineUpdatedSuccessfully,
          base?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
        );
      case _UpdatePhase.verificationFailed:
        return (
          strings.engineVerificationFailed,
          base?.copyWith(color: colorScheme.error),
        );
      case _UpdatePhase.failed:
        return (
          '${strings.engineUpdateFailed}${_errorMessage != null ? ' ${_errorMessage!}' : ''}',
          base?.copyWith(color: colorScheme.error),
        );
    }
  }
}
