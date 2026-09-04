import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/widgets/fetchy_buttons.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../core/domains/domain_matcher.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../quick_fetch_service.dart';

/// The dedicated Watched sites editor — reached only via the "Edit" button
/// on [QuickFetchSettingsPage], so the plain-text editing surface is never
/// sitting open (and accidentally tappable/editable) on the main settings
/// screen. This page owns the one multi-line text field; the settings page
/// only ever shows the saved result as a read-only list.
class WatchedDomainsEditPage extends StatefulWidget {
  const WatchedDomainsEditPage({super.key});

  @override
  State<WatchedDomainsEditPage> createState() => _WatchedDomainsEditPageState();
}

class _WatchedDomainsEditPageState extends State<WatchedDomainsEditPage> {
  final QuickFetchService _quickFetch = QuickFetchService.instance;
  final TextEditingController _controller = TextEditingController();

  bool _loaded = false;
  bool _dirty = false;
  bool _busy = false;

  /// Whether any save actually completed — reported back to the settings
  /// page on pop so it knows to reload the read-only list.
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String text = await _quickFetch.getWatchedDomainsText();
    if (!mounted) return;
    setState(() {
      _controller.text = text;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final String canonical = await _quickFetch.setWatchedDomainsText(_controller.text);
    if (!mounted) return;
    setState(() {
      _controller.text = canonical;
      _dirty = false;
      _busy = false;
      _saved = true;
    });
    Navigator.of(context).pop(true);
  }

  Future<void> _resetToDefaults() async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.watchedDomainsResetConfirmTitle),
        content: Text(strings.watchedDomainsResetConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.commonReset),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    final String text = await _quickFetch.resetWatchedDomainsToDefault();
    if (!mounted) return;
    setState(() {
      _controller.text = text;
      _dirty = false;
      _busy = false;
      _saved = true;
    });
  }

  /// Normalizes locally (reusing the same `DomainNormalizer` the cookie
  /// manager and native side use) so an obviously-invalid entry can be
  /// rejected immediately, then appends the result as a new line — the
  /// user never has to understand domain parsing themselves.
  Future<void> _addUrl() async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextEditingController inputController = TextEditingController();
    final String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.watchedDomainsAddUrl),
        content: TextField(
          controller: inputController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: strings.watchedDomainsExampleHint,
          ),
          keyboardType: TextInputType.url,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(inputController.text),
            child: Text(strings.commonAdd),
          ),
        ],
      ),
    );
    if (input == null || input.trim().isEmpty) return;

    final String? normalized = DomainNormalizer.normalize(input);
    if (!mounted) return;

    if (normalized == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.watchedDomainsInvalidDomain)),
      );
      return;
    }

    final List<String> lines = _controller.text
        .split('\n')
        .map((String l) => l.trim())
        .where((String l) => l.isNotEmpty)
        .toList();
    if (!lines.contains(normalized)) lines.add(normalized);

    setState(() {
      _controller.text = lines.join('\n');
      _dirty = true;
    });
  }

  Future<bool> _confirmDiscardIfDirty() async {
    if (!_dirty) return true;
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.watchedDomainsDiscardTitle),
        content: Text(strings.watchedDomainsDiscardBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.watchedDomainsKeepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.watchedDomainsDiscard),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return PopScope<bool>(
      canPop: !_dirty,
      onPopInvokedWithResult: (bool didPop, bool? result) async {
        if (didPop) return;
        if (await _confirmDiscardIfDirty() && context.mounted) {
          Navigator.of(context).pop(_saved);
        }
      },
      child: FetchyScaffold(
        title: strings.watchedDomainsEditTitle,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () async {
            if (await _confirmDiscardIfDirty() && context.mounted) {
              Navigator.of(context).pop(_saved);
            }
          },
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.lg),
            child: FetchyIconButton(
              icon: Icons.add_link_rounded,
              tooltip: strings.watchedDomainsAddUrl,
              emphasis: true,
              onPressed: _loaded ? _addUrl : null,
            ),
          ),
        ],
        body: !_loaded
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            : Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.md,
                  AppSpacing.page,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.watchedDomainsOnePerLine,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      // A recessed well: this is a text buffer being
                      // edited, so it reads as something you type *into*
                      // rather than as a card sitting on the page.
                      child: FetchySurface(
                        tone: FetchyTone.sunken,
                        elevated: false,
                        child: TextField(
                          controller: _controller,
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          // Domains are always Latin text, even in Arabic.
                          textDirection: TextDirection.ltr,
                          keyboardType: TextInputType.multiline,
                          onChanged: (_) => setState(() => _dirty = true),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            height: 1.6,
                          ),
                          decoration: const InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.all(AppSpacing.lg),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FetchyTonalButton(
                            label: strings.watchedDomainsResetToDefaults,
                            onPressed: _busy ? null : _resetToDefaults,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FetchyPrimaryButton(
                            label: strings.commonSaveChanges,
                            icon: Icons.check_rounded,
                            height: 48,
                            busy: _busy,
                            onPressed: (_dirty && !_busy) ? _save : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
