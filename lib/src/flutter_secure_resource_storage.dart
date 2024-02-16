// Copyright 2024 The Cached Resource Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:resource_storage/resource_storage.dart';

/// The name of encrypted SharedPreference file on android
const kResourceStorageEncryptedSharedPrefsName = 'resource_storage';

/// Factory to provide instance of [FlutterSecureResourceStorage].
class FlutterSecureResourceStorageProvider implements ResourceStorageProvider {
  /// Creates factory of [FlutterSecureResourceStorage].
  const FlutterSecureResourceStorageProvider();

  @override
  ResourceStorage<K, V> createStorage<K, V>({
    required String storageName,
    StorageDecoder<V>? decode,
    StorageExecutor? executor,
    TimestampProvider? timestampProvider,
    Logger? logger,
  }) {
    return FlutterSecureResourceStorage(
      storageName: storageName,
      decode: ArgumentError.checkNotNull(decode, 'decode'),
      executor: executor ?? syncStorageExecutor,
      timestampProvider: timestampProvider ?? const TimestampProvider(),
      logger: logger,
    );
  }
}

/// Secure persistent resource storage implementation based on
/// flutter_secure_storage plugin. Stores a value as JSON string.
class FlutterSecureResourceStorage<K, V> implements ResourceStorage<K, V> {
  /// Creates secure persistent resource storage based on
  /// flutter_secure_storage plugin.
  ///
  /// Stores a value as JSON string, so [decode] should be provided to be able
  /// to decode a value back.
  ///
  /// [storageName] is used as namespace (prefix) for key in the storage and
  /// used in [clear] method to clear the storage - delete all keys within
  /// given namespace. Keep it unique and short.
  ///
  /// For large json data consider providing a custom [executor] that runs task
  /// in separate isolate.
  ///
  /// Custom [timestampProvider] could be used in test to mock storeTime.
  ///
  /// Provide [Logger] if you want to see logs like errors during JSON parsing.
  ///
  /// Set custom [storage] if you need custom configuration
  /// or want to use it externally.
  ///
  /// Note: On Android if custom [storage] was not provided all data are stored
  /// using EncryptedSharedPreferences in a single file
  /// with name [kResourceStorageEncryptedSharedPrefsName].
  /// As by default Android backups data on Google Drive, it can cause
  /// exception java.security.InvalidKeyException:Failed to unwrap key.
  /// You need to:
  ///
  ///  * disable autobackup:
  ///    https://developer.android.com/guide/topics/data/autobackup#EnablingAutoBackup
  ///  * or exclude sharedprefs [kResourceStorageEncryptedSharedPrefsName]
  ///    used by the storage by default:
  ///    https://developer.android.com/guide/topics/data/autobackup#IncludingFiles
  ///
  ///
  FlutterSecureResourceStorage({
    required this.storageName,
    required StorageDecoder<V> decode,
    StorageExecutor executor = syncStorageExecutor,
    TimestampProvider timestampProvider = const TimestampProvider(),
    FlutterSecureStorage storage = const FlutterSecureStorage(
      iOptions:
          IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device),
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        sharedPreferencesName: kResourceStorageEncryptedSharedPrefsName,
        resetOnError: true,
      ),
    ),
    Logger? logger,
  })  : _logger = logger,
        _timestampProvider = timestampProvider,
        _storage = storage,
        _storageAdapter = JsonStorageAdapter<V>(
          decode: decode,
          executor: executor,
          logger: logger,
        );

  final String storageName;
  final JsonStorageAdapter<V> _storageAdapter;
  final FlutterSecureStorage _storage;
  final Logger? _logger;

  /// Set custom timestamp provider if you need it in tests
  final TimestampProvider _timestampProvider;

  /// Clears all data in the storage regardless [storageName]
  Future<void> clearAllStorage() => _storage.deleteAll();

  @override
  Future<void> clear() async {
    final entries = await _storage.readAll();
    final namespace = '$storageName:';
    for (final entry in entries.entries) {
      if (entry.key.startsWith(namespace)) {
        await _storage.delete(key: entry.key);
      }
    }
  }

  @override
  Future<CacheEntry<V>?> getOrNull(K key) async {
    final storageKey = _resolveStorageKey(key);
    final cache = await _storage.read(key: storageKey);
    if (cache != null) {
      try {
        final (storeTime, dataJson) = _parseStorageEntry(cache);
        final data = await _storageAdapter.decodeFromJson(dataJson);
        return CacheEntry(data, storeTime: storeTime);
      } catch (e, trace) {
        _logger?.trace(
            LoggerLevel.error,
            'Error on load resource from [$storageName] by key [$storageKey]',
            e,
            trace);
      }
    }
    return null;
  }

  @override
  Future<void> put(K key, V data, {int? storeTime}) async {
    final storageKey = _resolveStorageKey(key);
    final dataJson = await _storageAdapter.encodeToJson(data);
    final time = storeTime ?? _timestampProvider.getTimestamp();
    final entry = _createStorageEntry(storeTime: time, dataJson: dataJson);
    await _storage.write(key: storageKey, value: entry);
  }

  @override
  Future<void> remove(K key) async {
    final boxKey = _resolveStorageKey(key);
    await _storage.delete(key: boxKey);
  }

  String _createStorageEntry({
    required int storeTime,
    required String dataJson,
  }) =>
      '$storeTime:$dataJson';

  (int storeTime, String dataJson) _parseStorageEntry(String entry) {
    final dividerIndex = entry.indexOf(':');
    final timestamp = entry.substring(0, dividerIndex);
    final data = entry.substring(dividerIndex + 1);
    return (int.parse(timestamp), data);
  }

  String _resolveStorageKey(K key) => '$storageName:${_keyToString(key)}';

  String _keyToString(K key) {
    if (key is String) return key;
    // Try to resolve resource key
    final dynamic dynamicKey = key;
    try {
      return dynamicKey.resourceKey;
    } catch (ignore) {
      //ignore
    }
    _logger?.trace(
      LoggerLevel.warning,
      'Complex storage key used: [$key]. Fallback to [key.toString()].'
      ' Try to use String as key or implement [String resourceKey] field.'
      ' Or ensure that toString method returns a value'
      ' that can be used as identifier of resource',
    );
    return key.toString();
  }

  @override
  String toString() => 'FlutterSecureResourceStorage($storageName)';
}
