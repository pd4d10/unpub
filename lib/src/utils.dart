// Taken from:
// https://github.com/dart-lang/pub-dartlang-dart/blob/master/app/lib/shared/utils.dart

import 'package:pub_semver/pub_semver.dart' as semver;

/// Compares two versions according to the semantic versioning specification.
///
/// If [pubSorted] is `true` then pub's priorization ordering is used, which
/// will rank pre-release versions lower than stable versions (e.g. it will
/// order "0.9.0-dev.1 < 0.8.0").  Otherwise it will use semantic version
/// sorting (e.g. it will order "0.8.0 < 0.9.0-dev.1").
int compareSemanticVersionsDesc(
    semver.Version a, semver.Version b, bool decreasing, bool pubSorted) {
  if (pubSorted) {
    if (decreasing) {
      return semver.Version.prioritize(b, a);
    } else {
      return semver.Version.prioritize(a, b);
    }
  } else {
    if (decreasing) {
      return b.compareTo(a);
    } else {
      return a.compareTo(b);
    }
  }
}

/// Returns true if [b] is considered newer than [a].
///
/// If [pubSorted] is `true` then pub's priorization ordering is used, which
/// will rank pre-release versions lower than stable versions (e.g. it will
/// order "0.9.0-dev.1 < 0.8.0").  Otherwise it will use semantic version
/// sorting (e.g. it will order "0.8.0 < 0.9.0-dev.1").
bool isNewer(semver.Version a, semver.Version b, {bool pubSorted = true}) =>
    compareSemanticVersionsDesc(a, b, false, pubSorted) < 0;

bool isNewerForVersionString(String a, String b) =>
    isNewer(semver.Version.parse(a), semver.Version.parse(b));
