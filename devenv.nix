{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  android = {
    enable = true;
    flutter.enable = true;

    platforms.version = ["34" "35" "36"];
    abis = ["arm64-v8a" "x86_64"];
    cmake.version = ["3.22.1"];
    cmdLineTools.version = "8.0";
    buildTools.version = ["35.0.0"];
    emulator.enable = true;
    systemImages.enable = true;
  };

  enterShell = ''
    export CHROME_EXECUTABLE=$(which chromium)
    export ANDROID_HOME=$(which android | sed -E 's/(.*libexec\/android-sdk).*/\1/')
    export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
  '';

  packages = with pkgs; [
    chromium
    git
    just
  ];

  git-hooks.hooks = {
    action-validator.enable = true;
    alejandra.enable = true;
    check-yaml.enable = true;
    dart-analyze.enable = true;
    dart-format.enable = true;
    typos = {
      enable = true;
      settings.exclude = [
        "android/**"
        "ios/**"
        "lib/l10n/app_de.arb"
        "linux/**"
        "macos/**"
        "web/**"
        "windows/**"
      ];
    };
    yamlfmt = {
      enable = true;
      settings.lint-only = false;
    };
    yamllint = {
      enable = true;
      settings = {
        preset = "relaxed";
        strict = false;
      };
    };
  };

  # See full reference at https://devenv.sh/reference/options/
}
