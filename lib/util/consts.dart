const String gitHash = String.fromEnvironment(
  'GIT_HASH',
  defaultValue: 'unknown',
);

const String gitBranch = String.fromEnvironment(
  'GIT_BRANCH',
  defaultValue: 'unknown',
);

const String buildDate = String.fromEnvironment(
  'BUILD_DATE',
  defaultValue: 'unknown',
);
