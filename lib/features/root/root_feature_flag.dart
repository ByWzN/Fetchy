/// Root Features are fully implemented (see [RootService]/[RootFeaturesPage])
/// but intentionally disabled for the first public release, which ships as a
/// normal non-root app.
///
/// While this is `false`, [RootFeaturesPage] renders a "Coming soon"
/// placeholder instead of its functional UI, and never calls
/// [RootService.getStatus] or [RootService.enable] — no root check runs, no
/// root permission is requested, and `su` is never invoked. The real
/// implementation underneath is untouched; flip this to `true` to bring it
/// back for a future release.
const bool kRootFeaturesEnabled = false;
