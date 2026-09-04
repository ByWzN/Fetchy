import '../../l10n/generated/app_localizations.dart';
import 'extraction_error_mapper.dart';

/// The user-facing copy for each [ExtractionFailureKind] — one place, reused
/// by both the "Why?" dialog and the Developer information page, so the two
/// can never end up describing the same failure with different words. Every
/// function here takes [AppLocalizations] and returns a localized string —
/// [ExtractionErrorMapper] itself stays a pure, unlocalized classifier (its
/// own `.message`/`.details` are for logs and the sanitized developer detail
/// block, never shown to a normal user directly).
String extractionCategoryTitle(ExtractionFailureKind kind, AppLocalizations strings) {
  switch (kind) {
    case ExtractionFailureKind.authRequired:
      return strings.errorTitleAuthRequired;
    case ExtractionFailureKind.sessionExpired:
      return strings.errorTitleSessionExpired;
    case ExtractionFailureKind.sessionInvalid:
      return strings.errorTitleSessionInvalid;
    case ExtractionFailureKind.platformRestricted:
      return strings.errorTitlePlatformRestricted;
    case ExtractionFailureKind.antiBot:
    case ExtractionFailureKind.impersonationUnavailable:
      return strings.errorTitleAntiBot;
    case ExtractionFailureKind.networkError:
      return strings.errorTitleNetworkError;
    case ExtractionFailureKind.unsupported:
      return strings.errorTitleUnsupported;
    case ExtractionFailureKind.extractorError:
      return strings.errorTitleExtractorError;
    case ExtractionFailureKind.unknown:
      return strings.errorTitleUnknown;
  }
}

/// The short, plain-language message shown as the primary reason on the
/// Fetch/download result card and atop the "Why?" dialog — mirrors exactly
/// the branching [ExtractionErrorMapper.map] uses to pick an English
/// message, just localized. [platform] is the same value already computed
/// at every call site (e.g. `ExtractionErrorMapper.platformForUrl(url)`).
String extractionMessageFor(
  MappedExtractionError error,
  AppLocalizations strings, {
  String? platform,
}) {
  final String subject = platform ?? strings.errorSubjectThisLink;
  switch (error.kind) {
    case ExtractionFailureKind.authRequired:
      return platform == 'TikTok'
          ? strings.errorMessageAuthRequiredTikTok
          : strings.errorMessageAuthRequiredGeneric;
    case ExtractionFailureKind.sessionExpired:
      return strings.errorMessageSessionExpired;
    case ExtractionFailureKind.sessionInvalid:
      return strings.errorMessageSessionInvalid;
    case ExtractionFailureKind.impersonationUnavailable:
      return platform == null
          ? strings.errorMessageImpersonationGeneric
          : strings.errorMessageImpersonationWithPlatform(platform);
    case ExtractionFailureKind.antiBot:
      return strings.errorMessageAntiBot;
    case ExtractionFailureKind.platformRestricted:
      return strings.errorMessagePlatformRestricted;
    case ExtractionFailureKind.networkError:
      return platform == null
          ? strings.errorMessageNetworkGeneric
          : strings.errorMessageNetworkWithPlatform(platform);
    case ExtractionFailureKind.unsupported:
      return platform == 'TikTok'
          ? strings.errorMessageUnsupportedTikTok
          : strings.errorMessageUnsupportedWithSubject(subject);
    case ExtractionFailureKind.extractorError:
      return strings.errorMessageExtractor;
    case ExtractionFailureKind.unknown:
      // Mirrors ExtractionErrorMapper.map's own distinction: no raw engine
      // text at all reads as "could not be fetched", anything unrecognized
      // reads as the more generic "something went wrong".
      return error.details.trim().isEmpty
          ? strings.errorMessageUnknownEmpty(subject)
          : strings.errorMessageUnknownGeneric;
  }
}

List<String> extractionPossibleReasons(
  ExtractionFailureKind kind,
  AppLocalizations strings, {
  String? platform,
}) {
  final String subject = platform ?? strings.errorSubjectFallback;
  switch (kind) {
    case ExtractionFailureKind.authRequired:
      return <String>[
        strings.errorReasonAuthRequired1,
        strings.errorReasonAuthRequired2(subject),
        strings.errorReasonAuthRequired3,
      ];
    case ExtractionFailureKind.sessionExpired:
      return <String>[
        strings.errorReasonSessionExpired1,
        strings.errorReasonSessionExpired2(subject),
      ];
    case ExtractionFailureKind.sessionInvalid:
      return <String>[
        strings.errorReasonSessionInvalid1(subject),
        strings.errorReasonSessionInvalid2,
      ];
    case ExtractionFailureKind.platformRestricted:
      return <String>[
        strings.errorReasonPlatformRestricted1,
        strings.errorReasonPlatformRestricted2,
        strings.errorReasonPlatformRestricted3(subject),
      ];
    case ExtractionFailureKind.antiBot:
      return <String>[
        strings.errorReasonAntiBot1(subject),
        strings.errorReasonAntiBot2,
        strings.errorReasonAntiBot3,
      ];
    case ExtractionFailureKind.impersonationUnavailable:
      return <String>[
        strings.errorReasonImpersonation1(subject),
        strings.errorReasonImpersonation2,
      ];
    case ExtractionFailureKind.networkError:
      return <String>[
        strings.errorReasonNetwork1,
        strings.errorReasonNetwork2(subject),
      ];
    case ExtractionFailureKind.unsupported:
      return <String>[strings.errorReasonUnsupported1];
    case ExtractionFailureKind.extractorError:
      return <String>[
        strings.errorReasonExtractor1(subject),
        strings.errorReasonExtractor2,
      ];
    case ExtractionFailureKind.unknown:
      // The exact category couldn't be determined, so this falls back to
      // the same general explanation given in Settings → Technical
      // information → Limitations, rather than guessing at specifics.
      return <String>[
        strings.errorReasonUnknown1(subject),
        strings.errorReasonUnknown2,
        strings.errorReasonUnknown3(subject),
        strings.errorReasonUnknown4,
        strings.errorReasonUnknown5,
      ];
  }
}

/// A single, compact, more technically-framed sentence per category — the
/// "relevant known limitation" shown on the Developer information page.
/// Deliberately terser than [extractionPossibleReasons]: that list is meant
/// to be read by anyone, this is meant to be scanned by someone debugging.
String extractionKnownLimitation(ExtractionFailureKind kind, AppLocalizations strings) {
  switch (kind) {
    case ExtractionFailureKind.authRequired:
      return strings.errorLimitationAuthRequired;
    case ExtractionFailureKind.sessionExpired:
      return strings.errorLimitationSessionExpired;
    case ExtractionFailureKind.sessionInvalid:
      return strings.errorLimitationSessionInvalid;
    case ExtractionFailureKind.platformRestricted:
      return strings.errorLimitationPlatformRestricted;
    case ExtractionFailureKind.antiBot:
      return strings.errorLimitationAntiBot;
    case ExtractionFailureKind.impersonationUnavailable:
      return strings.errorLimitationImpersonation;
    case ExtractionFailureKind.networkError:
      return strings.errorLimitationNetwork;
    case ExtractionFailureKind.unsupported:
      return strings.errorLimitationUnsupported;
    case ExtractionFailureKind.extractorError:
      return strings.errorLimitationExtractor;
    case ExtractionFailureKind.unknown:
      return strings.errorLimitationUnknown;
  }
}

/// Whether this category is the kind of thing that plausibly has an open
/// yt-dlp issue worth checking — used to decide whether the Developer
/// information page points at the issue tracker or says "Not applicable"
/// rather than fabricating a specific issue link. Purely a boolean
/// classification, so it needs no localized strings of its own.
bool extractionMayHaveUpstreamIssue(ExtractionFailureKind kind) {
  switch (kind) {
    case ExtractionFailureKind.antiBot:
    case ExtractionFailureKind.impersonationUnavailable:
    case ExtractionFailureKind.extractorError:
    case ExtractionFailureKind.unsupported:
      return true;
    case ExtractionFailureKind.authRequired:
    case ExtractionFailureKind.sessionExpired:
    case ExtractionFailureKind.sessionInvalid:
    case ExtractionFailureKind.platformRestricted:
    case ExtractionFailureKind.networkError:
    case ExtractionFailureKind.unknown:
      return false;
  }
}
