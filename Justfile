default:
    @just --list

generate:
    flutter pub get
    flutter gen-l10n