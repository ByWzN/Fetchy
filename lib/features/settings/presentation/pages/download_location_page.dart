import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/widgets/fetchy_buttons.dart';
import '../../../../app/widgets/fetchy_rows.dart';
import '../../../../app/widgets/fetchy_selectors.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../core/storage/storage_settings.dart';
import '../../../../core/storage/storage_settings_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/settings_section.dart';

/// Settings → Download Location.
///
/// Two independent questions, kept visually separate on purpose:
/// "Base folder" (where — Android's own Movies/Music, or a folder the user
/// picks) and "Organization" (whether Fetchy adds its own Videos/Audio
/// subfolder underneath). Every combination of the two is a valid,
/// supported configuration — this page never forces one fixed structure.
///
/// Only decides destination *folders* — filename templates, metadata, and
/// format/quality options are a separate, future feature (see the
/// Download Options entry point on the media preview screen). Mixing the
/// two here would make neither concept clean.
class DownloadLocationPage extends StatefulWidget {
  const DownloadLocationPage({super.key});

  @override
  State<DownloadLocationPage> createState() => _DownloadLocationPageState();
}

class _DownloadLocationPageState extends State<DownloadLocationPage> {
  final StorageSettingsService _service = StorageSettingsService.instance;

  StorageSettings _settings = StorageSettings.defaults;
  bool _loading = true;

  /// Set once a saved custom folder has been checked against reality —
  /// null means "not checked yet" (or not applicable), never "checked and
  /// fine" by assumption.
  bool? _videoFolderAccessible;
  bool? _audioFolderAccessible;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final StorageSettings settings = await _service.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
    // Only validated here, on demand — never at app startup.
    unawaited(_validateCustomFolders(settings));
  }

  Future<void> _validateCustomFolders(StorageSettings settings) async {
    if (settings.base != StorageBase.custom) return;

    final CustomFolder? video = settings.videoFolder;
    if (video != null) {
      final bool ok = await _service.isFolderAccessible(video.treeUri);
      if (mounted) setState(() => _videoFolderAccessible = ok);
    }

    if (!settings.audioSameAsVideo) {
      final CustomFolder? audio = settings.audioFolder;
      if (audio != null) {
        final bool ok = await _service.isFolderAccessible(audio.treeUri);
        if (mounted) setState(() => _audioFolderAccessible = ok);
      }
    }
  }

  Future<void> _setBase(StorageBase base) async {
    setState(() => _settings = _settings.copyWith(base: base));
    await _service.saveBase(base);
    if (base == StorageBase.custom) {
      unawaited(_validateCustomFolders(_settings));
    }
  }

  Future<void> _setUseFetchySubfolders(bool value) async {
    setState(() => _settings = _settings.copyWith(useFetchySubfolders: value));
    await _service.saveUseFetchySubfolders(value);
  }

  Future<void> _pickVideoFolder() async {
    final CustomFolder? folder = await _service.pickCustomFolder();
    if (folder == null || !mounted) return;
    setState(() {
      _settings = _settings.copyWith(videoFolder: folder);
      _videoFolderAccessible = true;
    });
    await _service.saveVideoFolder(folder);
  }

  Future<void> _pickAudioFolder() async {
    final CustomFolder? folder = await _service.pickCustomFolder();
    if (folder == null || !mounted) return;
    setState(() {
      _settings = _settings.copyWith(audioFolder: folder);
      _audioFolderAccessible = true;
    });
    await _service.saveAudioFolder(folder);
  }

  Future<void> _setAudioSameAsVideo(bool value) async {
    setState(() => _settings = _settings.copyWith(audioSameAsVideo: value));
    await _service.saveAudioSameAsVideo(value);
    if (!value) {
      unawaited(_validateCustomFolders(_settings));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return FetchyScaffold(
      title: strings.downloadLocationTitleLabel,
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.hero,
              ),
              children: <Widget>[
                _buildIntro(context),
                const SizedBox(height: AppSpacing.lg),
                _buildSummary(context),
                const SizedBox(height: AppSpacing.xxl),
                _buildBaseSection(context),
                const SizedBox(height: AppSpacing.xxl),
                _buildOrganizationSection(context),
              ],
            ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return FetchyBanner(
      message: AppLocalizations.of(context).downloadLocationIntro,
    );
  }

  /// The live, at-a-glance answer to "where does my video/audio actually
  /// go?" — always reflects the current Base + Organization combination
  /// below, so the user never has to work it out themselves.
  ///
  /// This is the "full configuration inside" half of the Settings pattern:
  /// the row that opens this page says only "Default" or "Custom", and the
  /// resolved paths live here.
  Widget _buildSummary(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SummaryRow(
            icon: Icons.movie_outlined,
            label: strings.downloadLocationVideoLabel,
            value: _settings.videoLocationLabel(strings),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            icon: Icons.audiotrack_outlined,
            label: strings.downloadLocationAudioLabel,
            value: _settings.audioLocationLabel(strings),
          ),
        ],
      ),
    );
  }

  /// Where files go. The two bases are a pair of tonal option tiles rather
  /// than radio rows — the choice is a fill change, and the custom folder
  /// rows appear underneath only once Custom is actually selected.
  Widget _buildBaseSection(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return SettingsSection(
      title: strings.downloadLocationBaseFolderTitle,
      icon: Icons.folder_outlined,
      dividerIndent: 0,
      children: <Widget>[
        for (final StorageBase base in StorageBase.values) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: FetchyOptionTile(
              label: base.label(strings),
              description: base.description(strings),
              isSelected: _settings.base == base,
              onTap: () => _setBase(base),
            ),
          ),
          if (base == StorageBase.custom && _settings.base == StorageBase.custom) ...<Widget>[
            _DestinationRow(
              icon: Icons.movie_outlined,
              title: strings.downloadLocationVideoLocationTitle,
              folderName: _settings.videoFolder == null
                  ? null
                  : (_settings.videoFolder!.displayName ??
                        strings.storageSelectedFolderFallback),
              accessible: _videoFolderAccessible,
              onChoose: _pickVideoFolder,
            ),
            if (_settings.audioSameAsVideo)
              _AudioSameAsVideoRow(onDisable: () => _setAudioSameAsVideo(false))
            else
              _DestinationRow(
                icon: Icons.audiotrack_outlined,
                title: strings.downloadLocationAudioLocationTitle,
                folderName: _settings.audioFolder == null
                    ? null
                    : (_settings.audioFolder!.displayName ??
                          strings.storageSelectedFolderFallback),
                accessible: _audioFolderAccessible,
                onChoose: _pickAudioFolder,
                trailingExtra: _settings.videoFolder == null
                    ? null
                    : TextButton(
                        onPressed: () => _setAudioSameAsVideo(true),
                        child: Text(strings.downloadLocationSameAsVideo),
                      ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _buildOrganizationSection(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return SettingsSection(
      title: strings.downloadLocationOrganizationTitle,
      icon: Icons.rule_folder_outlined,
      dividerIndent: 0,
      children: <Widget>[
        FetchyListRow(
          leading: const FetchyLeadingIcon(icon: Icons.create_new_folder_outlined),
          title: strings.downloadLocationUseSubfolders,
          subtitle: _settings.useFetchySubfolders
              ? strings.downloadLocationUseSubfoldersOnDescription
              : strings.downloadLocationUseSubfoldersOffDescription,
          trailing: Switch(
            value: _settings.useFetchySubfolders,
            onChanged: _setUseFetchySubfolders,
          ),
          onTap: () => _setUseFetchySubfolders(!_settings.useFetchySubfolders),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 17, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DestinationRow extends StatelessWidget {
  const _DestinationRow({
    required this.icon,
    required this.title,
    required this.folderName,
    required this.accessible,
    required this.onChoose,
    this.trailingExtra,
  });

  final IconData icon;
  final String title;
  final String? folderName;
  final bool? accessible;
  final VoidCallback onChoose;
  final Widget? trailingExtra;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    final bool isSet = folderName != null;
    final bool isProblem = isSet && accessible == false;

    return FetchyListRow(
      leading: FetchyLeadingIcon(
        icon: isProblem ? Icons.error_outline_rounded : icon,
        destructive: isProblem,
      ),
      title: title,
      subtitle: isProblem
          ? strings.downloadLocationFolderInaccessible
          : (isSet ? folderName! : strings.downloadLocationNoFolderChosen),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ?trailingExtra,
          FetchyTonalButton(
            label: isSet ? strings.commonChange : strings.downloadLocationChooseFolder,
            expand: false,
            height: 38,
            emphasis: !isSet || isProblem,
            onPressed: onChoose,
          ),
        ],
      ),
    );
  }
}

class _AudioSameAsVideoRow extends StatelessWidget {
  const _AudioSameAsVideoRow({required this.onDisable});

  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyListRow(
      leading: const FetchyLeadingIcon(icon: Icons.audiotrack_outlined),
      title: strings.downloadLocationAudioLocationTitle,
      subtitle: strings.downloadLocationSameFolderAsVideo,
      trailing: TextButton(
        onPressed: onDisable,
        child: Text(strings.downloadLocationDifferentFolder),
      ),
    );
  }
}
