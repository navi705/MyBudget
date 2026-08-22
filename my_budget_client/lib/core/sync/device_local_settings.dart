/// Setting keys that describe THIS device and must never travel to another.
///
/// The settings table is keyed by `key` alone, so syncing these would make
/// every device converge on one identity and one set of credentials:
/// `local_device_id` is what both sync paths use to tell "my writes" from a
/// peer's, and the `server_sync_*` / `sync_folder_path` values are per-device
/// connection config - `server_sync_token` is a secret that has no business
/// being uploaded to the very server it authenticates against, nor written
/// into a shared folder every peer can read.
///
/// Shared by both sync engines on purpose. They filter at different layers -
/// the server path in SQL as it collects a push, the folder path in the DAO
/// that logs a change - and a key added to one list but not the other would
/// leak on whichever path was forgotten.
const Set<String> kDeviceLocalSettingKeys = {
  'local_device_id',
  'server_sync_enabled',
  'server_sync_url',
  'server_sync_token',
  'sync_enabled',
  'sync_folder_path',
};
