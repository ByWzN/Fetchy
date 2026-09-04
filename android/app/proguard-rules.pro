# Tink (pulled in transitively by androidx.security:security-crypto, used
# for Connected Accounts/Sessions' encrypted local cookie storage) declares
# annotations from these libraries as compile-time-only dependencies —
# error-prone and JSR-305 tooling annotations that guide static analysis
# and are never invoked at runtime. Tink's own published artifact (1.8.0)
# does not ship a consumer-proguard rule covering them, which is why R8
# reports them as missing: the actual resolved runtime dependency graph
# (`tink-android:1.8.0` -> `gson` + `jspecify`) never pulls these classes
# in at all, so they can never be loaded regardless.
#
# These are the exact six classes R8 itself names in
# build/app/outputs/mapping/release/missing_rules.txt — nothing broader.
# ---------------------------------------------------------------------------
# Apache Commons Compress — reflectively instantiated ZIP extra fields.
#
# youtubedl-android unpacks its bundled Python/FFmpeg payloads
# (libpython.zip.so, libffmpeg.zip.so) through commons-compress' ZipFile /
# ZipArchiveInputStream, which is on the critical path of engine init.
#
# ExtraFieldUtils' static initializer registers every ZipExtraField
# implementation by calling Class.newInstance() on it and then invoking
# getHeaderId() on the result. Those calls are invisible to R8, so it strips
# the no-arg constructors and interface overrides as unused. The static
# initializer then throws, and every later touch of the class surfaces as
# "NoClassDefFoundError: org.apache.commons.compress.archivers.zip.ExtraFieldUtils"
# — which is what broke extraction in release builds while debug (unminified)
# worked.
#
# Scoped to implementations of one interface: the members below are exactly
# what is reached reflectively or through the ZipExtraField interface.
-keepclassmembers class * implements org.apache.commons.compress.archivers.zip.ZipExtraField {
    <init>();
    public *;
}

# ---------------------------------------------------------------------------
# Tink annotation references (see below).
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy
