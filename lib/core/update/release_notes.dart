/// Turns a GitHub release body into something safe and readable to show
/// inside Fetchy.
///
/// Release notes are Markdown written by whoever cut the release. Fetchy
/// deliberately does not pull in a Markdown rendering package for one
/// screen: instead the common inline syntax is reduced to plain text and
/// everything else is dropped. Nothing in the notes can produce a tappable
/// link, an image request, or embedded HTML.
library;

/// One line of sanitized release notes, tagged with how it should be shown.
enum ReleaseNoteLineKind { heading, bullet, paragraph }

class ReleaseNoteLine {
  const ReleaseNoteLine(this.kind, this.text);

  final ReleaseNoteLineKind kind;
  final String text;
}

/// Hard cap on how much of a release body is rendered. Release notes are a
/// summary, not a document, and an enormous body must not be able to lock
/// up the layout.
const int kMaxReleaseNoteLines = 80;

const int _maxLineLength = 400;

/// Parses [body] into a short list of plain, styled lines.
List<ReleaseNoteLine> parseReleaseNotes(String? body) {
  final String? source = body?.trim();
  if (source == null || source.isEmpty) return const <ReleaseNoteLine>[];

  final List<ReleaseNoteLine> lines = <ReleaseNoteLine>[];
  bool inCodeFence = false;
  bool lastWasBlank = true;

  for (final String rawLine in source.split('\n')) {
    if (lines.length >= kMaxReleaseNoteLines) break;

    final String line = rawLine.trimRight();
    final String trimmed = line.trim();

    // Fenced code blocks are skipped entirely — a release note's code
    // sample is not something this screen needs to reproduce.
    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      inCodeFence = !inCodeFence;
      // A fence separates paragraphs, so text on either side of it must not
      // be joined into one run-on line.
      lastWasBlank = true;
      continue;
    }
    if (inCodeFence) continue;

    if (trimmed.isEmpty) {
      lastWasBlank = true;
      continue;
    }

    // A horizontal rule is a separator, not content.
    if (RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(trimmed)) {
      lastWasBlank = true;
      continue;
    }

    final RegExpMatch? heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
    if (heading != null) {
      final String text = _sanitizeInline(heading.group(2) ?? '');
      if (text.isNotEmpty) {
        lines.add(ReleaseNoteLine(ReleaseNoteLineKind.heading, text));
        lastWasBlank = false;
      }
      continue;
    }

    final RegExpMatch? bullet = RegExp(
      r'^\s*(?:[-*+]|\d{1,3}[.)])\s+(.*)$',
    ).firstMatch(line);
    if (bullet != null) {
      final String text = _sanitizeInline(bullet.group(1) ?? '');
      if (text.isNotEmpty) {
        lines.add(ReleaseNoteLine(ReleaseNoteLineKind.bullet, text));
        lastWasBlank = false;
      }
      continue;
    }

    final String text = _sanitizeInline(trimmed);
    if (text.isEmpty) continue;

    // Wrapped paragraph lines are joined back together rather than shown
    // as separate stubby lines.
    if (!lastWasBlank &&
        lines.isNotEmpty &&
        lines.last.kind == ReleaseNoteLineKind.paragraph) {
      final ReleaseNoteLine previous = lines.removeLast();
      final String merged = '${previous.text} $text';
      lines.add(
        ReleaseNoteLine(
          ReleaseNoteLineKind.paragraph,
          merged.length > _maxLineLength
              ? '${merged.substring(0, _maxLineLength)}…'
              : merged,
        ),
      );
    } else {
      lines.add(ReleaseNoteLine(ReleaseNoteLineKind.paragraph, text));
    }
    lastWasBlank = false;
  }

  return List<ReleaseNoteLine>.unmodifiable(lines);
}

/// Strips inline Markdown and any HTML, leaving readable text.
String _sanitizeInline(String input) {
  String text = input;

  // Images first, so their alt text does not survive as a stray link.
  text = text.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '');
  // [label](url) -> label. The URL is discarded: nothing here is tappable.
  text = text.replaceAllMapped(
    RegExp(r'\[([^\]]*)\]\([^)]*\)'),
    (Match match) => match.group(1) ?? '',
  );
  // Any HTML tag, including raw <script>/<img> a release body may contain.
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');
  // Emphasis and code markers.
  text = text.replaceAll(RegExp(r'(\*\*|__|~~|`)'), '');
  text = text.replaceAll(RegExp(r'^\s*>\s?'), '');
  // Collapse the whitespace the removals leave behind.
  text = text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();

  if (text.length > _maxLineLength) {
    return '${text.substring(0, _maxLineLength)}…';
  }
  return text;
}
