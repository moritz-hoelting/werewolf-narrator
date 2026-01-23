default:
    @just --list

generate:
    flutter pub get
    dart run flutter_app_name_localization
    flutter gen-l10n