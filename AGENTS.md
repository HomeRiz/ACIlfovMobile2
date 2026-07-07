## Imported Claude Cowork project instructions

## Mobile build and install workflow

When testing this app on an Android emulator, iOS simulator, or a physical device, remove any previously installed variants of the app before installing a new build. For Android, check for related packages such as `ro.acilfov.mobile` and older package ids before installing the freshly built APK. Build for the target device ABI: x86/x64 builds are for emulators, while physical Android devices need ARM libraries such as `arm64-v8a` or `armeabi-v7a`.
