import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/connection/database_connection_native.dart';

/// The desktop app has one database path and no way to point a run elsewhere,
/// so testing a migration or a sync meant running it over the user's real
/// budget. `MYBUDGET_DB_DIR` moves a debug run onto a copy instead.
///
/// The whole risk of the escape hatch is that it also moves a release run, so
/// most of what is checked here is that it does not.
void main() {
  group('sandboxDatabaseDirectory', () {
    test('a debug run follows the variable', () {
      expect(
        sandboxDatabaseDirectory(
          {'MYBUDGET_DB_DIR': r'C:\tmp\sandbox'},
          isDebugBuild: true,
        ),
        r'C:\tmp\sandbox',
      );
    });

    test('a release run ignores it', () {
      // An installed app whose data location can be moved by an environment
      // variable is a way to lose a database. The variable is not read at all
      // outside debug, rather than trusted not to be set.
      expect(
        sandboxDatabaseDirectory(
          {'MYBUDGET_DB_DIR': r'C:\tmp\sandbox'},
          isDebugBuild: false,
        ),
        isNull,
      );
    });

    test('an unset variable leaves the installed location alone', () {
      expect(sandboxDatabaseDirectory({}, isDebugBuild: true), isNull);
    });

    test('an empty or blank value is not a directory', () {
      // `set MYBUDGET_DB_DIR=` is how a shell unsets a variable it has already
      // exported, and an empty path would resolve to `db.sqlite` in whatever
      // the working directory happened to be.
      expect(
        sandboxDatabaseDirectory({'MYBUDGET_DB_DIR': ''}, isDebugBuild: true),
        isNull,
      );
      expect(
        sandboxDatabaseDirectory(
          {'MYBUDGET_DB_DIR': '   '},
          isDebugBuild: true,
        ),
        isNull,
      );
    });

    test('a path is passed through untrimmed', () {
      // Trailing spaces are legal in a path on the platforms this runs on, and
      // guessing which ones the caller meant to type is how a run silently
      // lands in a different folder from the one that was prepared.
      expect(
        sandboxDatabaseDirectory(
          {'MYBUDGET_DB_DIR': '/tmp/sandbox '},
          isDebugBuild: true,
        ),
        '/tmp/sandbox ',
      );
    });
  });
}
