import 'package:flutter/material.dart';

import '../../../../app/widgets/fetchy_surface.dart';

/// A titled group of settings rows.
///
/// Kept as a thin alias over [FetchyGroup] so the several screens built
/// around this name (Download Location, Quick Fetch, Connected Accounts,
/// Root Features, and the Download Options sheet) all pick up the shared
/// group surface — one raised card, hairlines between rows, and the shared
/// section caption — without each having to be rewired to the new widget.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.trailing,
    this.dividerIndent = 60,
  });

  final String title;
  final List<Widget> children;

  /// Optional small icon shown before [title].
  final IconData? icon;

  /// Optional action aligned to the far end of the caption row.
  final Widget? trailing;

  /// How far row separators are inset from the leading edge. Sections whose
  /// rows have no leading icon pass 0 so the hairline spans the full width.
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    return FetchyGroup(
      title: title,
      icon: icon,
      trailing: trailing,
      dividerIndent: dividerIndent,
      children: children,
    );
  }
}
