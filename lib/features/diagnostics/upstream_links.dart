/// Official upstream project links shown as compact rows in Technical
/// information → Upstream resources. Kept as data here rather than
/// hard-coded into widget body text, per the "Keep the UI clean" rule for
/// that section.
///
/// [label] is the project name (yt-dlp, youtubedl-android, FFmpeg) and
/// stays exactly as-is in every locale — translating a project name would
/// be incorrect. [kind] drives the localized row description (see
/// `AppLocalizations.upstreamYtDlpRepo`/`upstreamYtDlpIssues`/
/// `upstreamDocumentation`).
enum UpstreamLinkKind { repository, issues, documentation }

class UpstreamLink {
  const UpstreamLink({required this.label, required this.kind, required this.url});

  final String label;
  final UpstreamLinkKind kind;
  final String url;
}

const List<UpstreamLink> upstreamLinks = <UpstreamLink>[
  UpstreamLink(
    label: 'yt-dlp',
    kind: UpstreamLinkKind.repository,
    url: 'https://github.com/yt-dlp/yt-dlp',
  ),
  UpstreamLink(
    label: 'yt-dlp',
    kind: UpstreamLinkKind.issues,
    url: 'https://github.com/yt-dlp/yt-dlp/issues',
  ),
  UpstreamLink(
    label: 'youtubedl-android',
    kind: UpstreamLinkKind.repository,
    url: 'https://github.com/yausername/youtubedl-android',
  ),
  UpstreamLink(
    label: 'youtubedl-android',
    kind: UpstreamLinkKind.issues,
    url: 'https://github.com/yausername/youtubedl-android/issues',
  ),
  UpstreamLink(
    label: 'FFmpeg',
    kind: UpstreamLinkKind.documentation,
    url: 'https://ffmpeg.org/documentation.html',
  ),
];
