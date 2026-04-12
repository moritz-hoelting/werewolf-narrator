git_hash := `git rev-parse --short HEAD`
date := `date -u +"%Y-%m-%dT%H:%M:%SZ"`

default_device := `flutter devices --machine | jq -r '(map(select(.id == "chrome")) | .[0].id) // .[0].id'`

[private]
default:
    @just --list


# Run code and asset generation
[group("init")]
generate: && generate-assets generate-code
    flutter pub get

# Run asset generation
[group("init")]
generate-assets:
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create
    dart run flutter_app_name_localization

# Run code generation
[group("init")]
generate-code:
    dart run build_runner build --delete-conflicting-outputs
    flutter gen-l10n

# Run tests
[group("dev")]
test:
    flutter test

# Run static analysis
[group("dev")]
analyze:
    flutter analyze

# Run the app on a specified device
[arg("device", help="The device to run the app on. Use 'flutter devices' to list available devices.")]
[arg("flavor", help="The flavor to build.", long, pattern="|prod|dev|staging")]
[group("dev")]
run device=default_device flavor="dev" *args:
    flutter run --device-id={{device}} \
        --dart-define=GIT_HASH={{git_hash}} --dart-define=BUILD_DATE={{date}} \
        {{if flavor == "" { "" } else { "--flavor=" + flavor }}} \
        {{if device == "chrome" { "--web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp" } else { "" }}} \
        {{args}}

# Build the app for a specified executable
[arg("executable", help="The executable to build.")]
[group("build")]
build executable *args:
    flutter build {{executable}} --dart-define=GIT_HASH={{git_hash}} --dart-define=BUILD_DATE={{date}} {{args}}

# Build single apk for android
[group("build")]
build-apk *args: (build "apk" args)

# Build split apks for android
[group("build")]
build-split-apk *args: (build "apk" "--split-per-abi" args)

# Build app bundle for android
[group("build")]
build-appbundle *args: (build "appbundle" args)

# Build web app with WASM enabled
[group("build")]
build-web *args: (build "web" "--wasm" args)

# Build iOS app as an IPA file
[group("build")]
build-ios *args: (build "ipa" args)

# Build macOS app
[group("build")]
build-macos *args: (build "macos" args)

# Build Windows app
[group("build")]
build-windows *args: (build "windows" args)
