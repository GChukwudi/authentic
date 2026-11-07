#!/usr/bin/env bash
# Creates the android/ and ios/ folders around the existing Dart code,
# without letting `flutter create` touch our files.
set -euo pipefail
cd "$(dirname "$0")/.."

backup="$(mktemp -d)"
cp pubspec.yaml analysis_options.yaml "$backup"/
cp lib/main.dart "$backup"/main.dart

flutter create . --org com.godsfavour --project-name authentic --platforms android,ios

cp "$backup"/pubspec.yaml pubspec.yaml
cp "$backup"/analysis_options.yaml analysis_options.yaml
cp "$backup"/main.dart lib/main.dart
rm -f test/widget_test.dart

flutter pub get
echo
echo "Done. Two manual steps remain (see README): iOS camera text, Android minSdk."
