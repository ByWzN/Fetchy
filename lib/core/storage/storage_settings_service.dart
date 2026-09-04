import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform/platform_channels.dart';
import 'storage_settings.dart';

/// Download Location: persistence for [StorageSettings], plus the native
/// calls needed to grant and validate a custom folder. Backed by
/// [SharedPreferences], the same local key-value store every other Fetchy
/// setting uses — no second persistence system.
///
/// Never scans storage on its own. [load] only reads back what was already
/// persisted; [isFolderAccessible] is called explicitly by the Download
/// Location page (and just before a custom-destination download), never at
/// app startup.
class StorageSettingsService {
  StorageSettingsService._();

  static final StorageSettingsService instance = StorageSettingsService._();

  static const String _baseKey = 'fetchy.settings.storage.base';
  static const String _useFetchySubfoldersKey =
      'fetchy.settings.storage.useFetchySubfolders';
  static const String _audioSameAsVideoKey =
      'fetchy.settings.storage.audioSameAsVideo';
  static const String _videoFolderUriKey = 'fetchy.settings.storage.videoFolderUri';
  static const String _videoFolderNameKey = 'fetchy.settings.storage.videoFolderName';
  static const String _audioFolderUriKey = 'fetchy.settings.storage.audioFolderUri';
  static const String _audioFolderNameKey = 'fetchy.settings.storage.audioFolderName';

  Future<StorageSettings> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? videoUri = prefs.getString(_videoFolderUriKey);
    final String? audioUri = prefs.getString(_audioFolderUriKey);

    return StorageSettings(
      base: StorageBase.fromWire(prefs.getString(_baseKey)),
      // Fetchy-organized is the first-run default (see
      // StorageSettings.defaults) — absent means never configured, not
      // "direct".
      useFetchySubfolders: prefs.getBool(_useFetchySubfoldersKey) ?? true,
      audioSameAsVideo: prefs.getBool(_audioSameAsVideoKey) ?? false,
      videoFolder: videoUri == null
          ? null
          : CustomFolder(
              treeUri: videoUri,
              displayName: prefs.getString(_videoFolderNameKey),
            ),
      audioFolder: audioUri == null
          ? null
          : CustomFolder(
              treeUri: audioUri,
              displayName: prefs.getString(_audioFolderNameKey),
            ),
    );
  }

  Future<void> saveBase(StorageBase base) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseKey, base.wireValue);
  }

  Future<void> saveUseFetchySubfolders(bool useFetchySubfolders) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useFetchySubfoldersKey, useFetchySubfolders);
  }

  Future<void> saveAudioSameAsVideo(bool sameAsVideo) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_audioSameAsVideoKey, sameAsVideo);
  }

  Future<void> saveVideoFolder(CustomFolder? folder) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (folder == null) {
      await prefs.remove(_videoFolderUriKey);
      await prefs.remove(_videoFolderNameKey);
    } else {
      await prefs.setString(_videoFolderUriKey, folder.treeUri);
      if (folder.displayName == null) {
        await prefs.remove(_videoFolderNameKey);
      } else {
        await prefs.setString(_videoFolderNameKey, folder.displayName!);
      }
    }
  }

  Future<void> saveAudioFolder(CustomFolder? folder) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (folder == null) {
      await prefs.remove(_audioFolderUriKey);
      await prefs.remove(_audioFolderNameKey);
    } else {
      await prefs.setString(_audioFolderUriKey, folder.treeUri);
      if (folder.displayName == null) {
        await prefs.remove(_audioFolderNameKey);
      } else {
        await prefs.setString(_audioFolderNameKey, folder.displayName!);
      }
    }
  }

  /// Launches Android's system folder picker (Storage Access Framework).
  ///
  /// On Android 11+, the system picker itself refuses to let the user
  /// select a storage root or the Download folder directly — only a
  /// subfolder within one. That is an OS-level restriction Fetchy cannot
  /// override; the caller's copy should nudge the user toward a subfolder
  /// rather than presenting this as a Fetchy limitation.
  ///
  /// On success, native has already taken a persistable permission grant
  /// for the returned tree — this method only reports the result, it does
  /// not itself persist anything into [StorageSettings] (the caller decides
  /// whether it is the video or audio folder and saves it).
  ///
  /// Returns null if the user canceled, closed the picker, or it could not
  /// be opened at all.
  Future<CustomFolder?> pickCustomFolder() async {
    try {
      final Map<Object?, Object?>? result = await PlatformChannels.storageChannel
          .invokeMapMethod<Object?, Object?>(
            PlatformChannels.storagePickCustomDirectory,
          );
      if (result == null) return null;

      final String? treeUri = result['treeUri'] as String?;
      if (treeUri == null || treeUri.isEmpty) return null;

      return CustomFolder(
        treeUri: treeUri,
        displayName: result['displayName'] as String?,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Whether a previously-granted custom folder can still actually be
  /// written to — the permission may have been revoked, or the folder
  /// itself removed/unmounted since it was chosen.
  Future<bool> isFolderAccessible(String treeUri) async {
    try {
      final bool? accessible = await PlatformChannels.storageChannel.invokeMethod<bool>(
        PlatformChannels.storageCheckTreeAccessible,
        <String, Object?>{'treeUri': treeUri},
      );
      return accessible ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Releases a previously-granted folder permission — used when the user
  /// switches away from a custom folder, so Fetchy does not keep holding
  /// access it no longer needs.
  Future<void> releaseFolder(String treeUri) async {
    try {
      await PlatformChannels.storageChannel.invokeMethod<void>(
        PlatformChannels.storageReleaseTree,
        <String, Object?>{'treeUri': treeUri},
      );
    } on PlatformException {
      // Best-effort cleanup; nothing meaningful to recover from here.
    } on MissingPluginException {
      // Native storage channel not present on this build.
    }
  }
}
