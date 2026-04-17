git_hash := `git rev-parse --short HEAD`
git_branch := `git branch --show-current`
date := `date -u +"%Y-%m-%dT%H:%M:%SZ"`

default_device := `flutter devices --machine | jq -r '(map(select(.id == "chrome")) | .[0].id) // .[0].id'`
default_dev_flavor := "dev"
default_build_flavor := "prod"

alias t := test
alias a := analyze
alias r := run
alias g := generate

# The default recipe run when just is invoked without arguments. It lists all available recipes.
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

# Run code and asset generation and watch for changes
[group("dev")]
codegen-watch:
    dart run build_runner watch --delete-conflicting-outputs

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
run device=default_device flavor=default_dev_flavor *args:
    flutter run --device-id={{device}} \
        --dart-define=GIT_HASH={{git_hash}} --dart-define=GIT_BRANCH={{git_branch}} --dart-define=BUILD_DATE={{date}} \
        {{if flavor == "" { "" } else { "--flavor=" + flavor + " --dart-define=FLAVOR=" + flavor }}} \
        {{if device == "chrome" { "--web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp" } else { "" }}} \
        {{args}}

# Build the app for a specified executable
[private]
[arg("executable", help="The executable to build.")]
[group("build")]
build executable *args:
    flutter build {{executable}} --dart-define=GIT_HASH={{git_hash}} --dart-define=GIT_BRANCH={{git_branch}} --dart-define=BUILD_DATE={{date}} {{args}}

# Build single apk for android
[arg("flavor", help="The flavor to build.", long, pattern="|prod|dev|staging")]
[group("build")]
build-apk flavor=default_build_flavor *args: (build "apk" f"--flavor={{flavor}}" args)

# Build split apks for android
[arg("flavor", help="The flavor to build.", long, pattern="|prod|dev|staging")]
[group("build")]
build-split-apk flavor=default_build_flavor *args: (build-apk flavor "--split-per-abi" args)

# Build app bundle for android
[arg("flavor", help="The flavor to build.", long, pattern="|prod|dev|staging")]
[group("build")]
build-appbundle flavor=default_build_flavor *args: (build "appbundle" f"--flavor={{flavor}}" args)

# Build linux app
[arg("flavor", help="The flavor to build.", long, pattern="|prod|dev|staging")]
[group("build")]
[linux]
build-linux flavor=default_build_flavor *args: (build "linux" f"--dart-define=FLAVOR={{flavor}}" args)

# Build web app with WASM enabled
[arg("flavor", help="The flavor to build.", long, pattern="|prod|dev|staging")]
[group("build")]
build-web flavor=default_build_flavor *args: (build "web" "--wasm" f"--dart-define=FLAVOR={{flavor}}" args)

# Build iOS app as an IPA file
[arg("flavor", help="The flavor to build.", long, pattern="|prod|dev|staging")]
[group("build")]
[macos]
build-ios flavor=default_build_flavor *args: (build "ipa" f"--flavor={{flavor}}" args)

# Build macOS app
[arg("flavor", help="The flavor to build.", long, pattern="|prod|dev|staging")]
[group("build")]
[macos]
build-macos flavor=default_build_flavor *args: (build "macos" f"--flavor={{flavor}}" args)

# Build Windows app
[arg("flavor", help="The flavor to build.", long, pattern="|prod|dev|staging")]
[group("build")]
[windows]
build-windows flavor=default_build_flavor *args: (build "windows" f"--dart-define=FLAVOR={{flavor}}" args)

# Launch the built linux app
[group("preview")]
[linux]
preview-linux:
    ./build/linux/x64/release/bundle/werewolf_narrator

# Launch the built web app using miniserve with appropriate headers for COOP and COEP
[group("preview")]
preview-web:
    miniserve ./build/web/ --index index.html --header="Cross-Origin-Opener-Policy:same-origin" --header="Cross-Origin-Embedder-Policy:require-corp"