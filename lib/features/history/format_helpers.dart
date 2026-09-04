/// Small formatting helpers shared by history and download UI. Kept
/// separate from any single widget so Home, History, and the progress
/// cards format the same kind of value identically.
library;

import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';

String formatFileSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const List<String> units = <String>['B', 'KB', 'MB', 'GB'];
  double value = bytes.toDouble();
  int unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  final String formatted = unitIndex == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$formatted ${units[unitIndex]}';
}

String formatEta(int seconds) {
  final int minutes = seconds ~/ 60;
  final int remaining = seconds % 60;
  final String paddedSeconds = remaining.toString().padLeft(2, '0');
  if (minutes > 0) return '$minutes:$paddedSeconds';
  return '0:$paddedSeconds';
}

String formatSpeed(double bytesPerSecond) {
  if (bytesPerSecond <= 0) return '';
  const List<String> units = <String>['B/s', 'KB/s', 'MB/s', 'GB/s'];
  double value = bytesPerSecond;
  int unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  final String formatted = unitIndex == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$formatted ${units[unitIndex]}';
}

String detectPlatformName(String url) {
  final String lower = url.toLowerCase();
  if (lower.contains('youtu.be') || lower.contains('youtube.com')) {
    return 'YouTube';
  }
  if (lower.contains('tiktok.com')) {
    return 'TikTok';
  }
  if (lower.contains('instagram.com')) {
    return 'Instagram';
  }
  if (lower.contains('twitter.com') || lower.contains('x.com')) {
    return 'X';
  }
  return 'Web';
}

/// [strings] both supplies the "just now"/"m ago"/"h ago"/"d ago" wording
/// and, via [AppLocalizations.localeName], drives the locale-aware month
/// name once a date is old enough to need one — so an Arabic device shows
/// real Arabic month names, not a hand-rolled English abbreviation table.
String formatRelativeTime(DateTime time, AppLocalizations strings) {
  final Duration diff = DateTime.now().difference(time);

  if (diff.inSeconds < 60) return strings.historyJustNow;
  if (diff.inMinutes < 60) return strings.historyMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return strings.historyHoursAgo(diff.inHours);
  if (diff.inDays < 7) return strings.historyDaysAgo(diff.inDays);

  return DateFormat.yMMMd(strings.localeName).format(time);
}
