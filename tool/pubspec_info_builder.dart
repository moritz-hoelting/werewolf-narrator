import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:yaml/yaml.dart';

class PubspecInfoBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    r'$package$': ['lib/pubspec_info.g.dart'],
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      log.severe('pubspec.yaml not found!');
      return;
    }

    final content = pubspecFile.readAsStringSync();
    final yamlMap = loadYaml(content);

    final String? repository = yamlMap['repository'] as String?;
    final String? issueTracker = yamlMap['issue_tracker'] as String?;
    final List<String>? funding = (yamlMap['funding'] as YamlList?)
        ?.cast<String>();
    final appAuthor = yamlMap['app_author'] as YamlMap?;
    final String? authorName = appAuthor != null
        ? appAuthor['name'] as String?
        : null;
    final String? authorEmail = appAuthor != null
        ? appAuthor['email'] as String?
        : null;

    final output =
        """
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from pubspec.yaml

// coverage:ignore-file
// ignore_for_file: type=lint

final class PubspecInfo {
  static const String? repositoryUrl = ${repository != null ? "'$repository'" : 'null'};
  static const String? issueTrackerUrl = ${issueTracker != null ? "'$issueTracker'" : 'null'};
  static const List<String>? fundingUrls = ${funding != null ? funding.map((e) => "'$e'").toList().toString() : 'null'};
  static const String? authorName = ${authorName != null ? "'$authorName'" : 'null'};
  static const String? authorEmail = ${authorEmail != null ? "'$authorEmail'" : 'null'};
}
""";

    final outId = AssetId(buildStep.inputId.package, 'lib/pubspec_info.g.dart');
    await buildStep.writeAsString(outId, output);
    log.info('Generated lib/pubspec_info.g.dart');
  }
}
