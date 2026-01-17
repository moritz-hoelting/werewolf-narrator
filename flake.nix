{
  description = "Flutter environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          android_sdk.accept_license = true;
        };
        androidEnv = pkgs.androidenv.override { licenseAccepted = true; };
        androidComposition = androidEnv.composeAndroidPackages {
          cmdLineToolsVersion = "8.0"; # emulator related: newer versions are not only compatible with avdmanager
          platformToolsVersion = "36.0.2";
          buildToolsVersions = [ "35.0.0" ];
          platformVersions = [ "28" "31" "32" "33" "34" "35" "36" ];
          cmakeVersions = [ "3.22.1" ];
          abiVersions = [ "x86_64" ]; # emulator related: on an ARM machine, replace "x86_64" with
          # either "armeabi-v7a" or "arm64-v8a", depending on the architecture of your workstation.
          includeNDK = true;
          ndkVersions = [ "28.2.13676358" ];
          includeSystemImages = true; # emulator related: system images are needed for the emulator.
          systemImageTypes = [ "google_apis" "google_apis_playstore" ];
          includeEmulator = true; # emulator related: if it should be enabled or not
          useGoogleAPIs = true;
          extraLicenses = [
            "android-googletv-license"
            "android-sdk-arm-dbt-license"
            "android-sdk-license"
            "android-sdk-preview-license"
            "google-gdk-license"
            "intel-android-extra-license"
            "intel-android-sysimage-license"
            "mips-android-sysimage-license"
          ];
        };
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell = with pkgs; mkShell rec {
          NIX_ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
          NIX_ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          JAVA_HOME = jdk21.home;
          NIX_FLUTTER_ROOT = flutter;
          QT_QPA_PLATFORM = "wayland;xcb"; # emulator related: try using wayland, otherwise fall back to X.
          # NB: due to the emulator's bundled qt version, it currently does not start with QT_QPA_PLATFORM="wayland".
          # Maybe one day this will be supported.
          buildInputs = [
            androidSdk
            flutter
            qemu_kvm
            gradle
            jdk21
          ];
          # emulator related: vulkan-loader and libGL shared libs are necessary for hardware decoding
          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [vulkan-loader libGL]}";
          # Globally installed packages, which are installed through `dart pub global activate package_name`,
          # are located in the `$PUB_CACHE/bin` directory.
          shellHook = ''
            export FLUTTER_ROOT=$HOME/.cache/flutter-sdk
            export DART_ROOT="$FLUTTER_ROOT/bin/cache/dart-sdk"

            if [ ! -d "$FLUTTER_ROOT" ] || [ ! -f "$FLUTTER_ROOT/version" ] || [ "$(cat "$FLUTTER_ROOT/version")" != "$(cat "$NIX_FLUTTER_ROOT/version")" ]; then
              mkdir -p "$FLUTTER_ROOT"
              cp -R "$NIX_FLUTTER_ROOT/." "$FLUTTER_ROOT/"
              chmod -R u+w "$FLUTTER_ROOT"
            fi

            get_sdk_version() {
              if [ -f "$1" ]; then
                grep "^Pkg.Revision=" "$1" | cut -d= -f2
              else
                echo ""
              fi
            }

            export ANDROID_SDK_ROOT="$HOME/.cache/android-sdk"
            export ANDROID_HOME="$HOME/.cache/android-sdk"

            LOCAL_SDK_VERSION=$(get_sdk_version "$ANDROID_SDK_ROOT/platform-tools/source.properties")
            NIX_SDK_VERSION=$(get_sdk_version "$NIX_ANDROID_SDK_ROOT/platform-tools/source.properties")

            unset get_sdk_version

            if [ ! -d "$HOME/.cache/android-sdk" ] || [ "$LOCAL_SDK_VERSION" != "$NIX_SDK_VERSION" ]; then
              cp -R "$NIX_ANDROID_SDK_ROOT" "$HOME/.cache/android-sdk"
            fi

            export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
            
            if [ -z "$PUB_CACHE" ]; then
              export PATH="$PATH:$HOME/.pub-cache/bin"
            else
              export PATH="$PATH:$PUB_CACHE/bin"
            fi
          '';
        };
      }
    );
}