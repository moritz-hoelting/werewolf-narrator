const String gitHash = String.fromEnvironment(
  'GIT_HASH',
  defaultValue: 'unknown',
);

const String buildDate = String.fromEnvironment(
  'BUILD_DATE',
  defaultValue: 'unknown',
);
