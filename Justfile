[private]
default:
    @just --list

generate:
    flutter pub get
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create
    dart run build_runner build --delete-conflicting-outputs
    dart run flutter_app_name_localization
    flutter gen-l10n