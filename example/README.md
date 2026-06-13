# pip Example

This app demonstrates Android and iOS Picture in Picture integration for the
`pip` plugin.

## Run

```bash
flutter pub get
flutter run
```

## Android

The Android example:

- enables `android:supportsPictureInPicture="true"` in
  `android/app/src/main/AndroidManifest.xml`
- makes `MainActivity` extend `org.opentraa.pip.PipActivity`
- configures aspect ratio, source rect hint, and external state monitoring

This setup shows how to keep Android PiP lifecycle hooks wired through the host
activity.

## iOS

The iOS example uses `example/packages/native_plugin` to:

- create a native source view handle
- create a native PiP content view handle
- pass those native view IDs into `PipOptions`

This helper package exists only to demonstrate the native-view requirement for
iOS PiP. Real apps can provide those native views through their own host-side
code.
