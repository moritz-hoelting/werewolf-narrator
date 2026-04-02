import 'package:flutter/services.dart' show rootBundle;

Future<String> loadChangelog() async {
  final regex = RegExp(
    r"# Changelog[\s\S]*?\[Semantic Versioning\]\(https://semver\.org/spec/v\d+\.\d+\.\d+\.html\)\.",
  );

  final String assetString = await rootBundle.loadString('CHANGELOG.md');

  return assetString.replaceFirst(regex, "").trim();
}
