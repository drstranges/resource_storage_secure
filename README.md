## Secure Resource Storage
[![pub package](https://img.shields.io/pub/v/resource_storage_secure.svg)](https://pub.dev/packages/resource_storage_secure)

Simple implementation of secure persistent resource storage for [cached_resource](https://pub.dev/packages/cached_resource) package,
based on [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage).

## Components

1. `FlutterSecureResourceStorage`: secure persistent resource storage based on `flutter_secure_storage`.
2. `FlutterSecureResourceStorageProvider`: factory to use for configuration of `cached_resource`.

## Note: usage on Android

Note: On Android if custom `storage` configuration is not provided for [FlutterSecureResourceStorage]
then all the data are stored using EncryptedSharedPreferences in a single file 
with name `resource_storage` (See `kResourceStorageEncryptedSharedPrefsName` constant).
As by default Android backups data on Google Drive, it can cause exception 
`java.security.InvalidKeyException:Failed to unwrap key`.
You need to:

 * disable autobackup: https://developer.android.com/guide/topics/data/autobackup#EnablingAutoBackup
 * or exclude sharedprefs: https://developer.android.com/guide/topics/data/autobackup#IncludingFiles
