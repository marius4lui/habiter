# Habiter Flutter Port (appv2)

This is a manual Flutter scaffold that mirrors the Expo/React Native app in `../mobile`. It includes the full Dart code (models, providers, services, theme, screens, and widgets) so you can keep the same UI/UX and extend with AI later.

Because `flutter create` is blocked by the current Device Guard policy, platform boilerplate was not generated automatically. After lifting the restriction, run the following inside `apps/appv2` to add Android/iOS/web folders and fetch dependencies:

```sh
flutter create .
flutter pub get
```

Then run the app:

```sh
flutter run
```
