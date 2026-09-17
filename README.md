# Bite Local

Bite Local is a Flutter food-ordering prototype using Indian rupees (₹) for all menu, delivery, and order totals. It is designed to demonstrate the Advanced Mobile Development topics:

- **State management:** `provider` exposes a single `AppState` `ChangeNotifier` for menu filters, cart quantities, loading, errors, and navigation.
- **Location:** `geolocator` requests permission and displays the current coordinates as the delivery destination.
- **Camera and gallery:** `image_picker` plus `permission_handler` support choosing a profile image from either source.
- **Notifications:** `flutter_local_notifications` sends an order-confirmation notification.
- **Reliability:** `runZonedGuarded`, explicit async `try/catch/finally`, visible error messages, and loading states.
- **Performance:** lazy `SliverList.builder`, constrained image dimensions/quality, and immutable menu data.

## Windows setup and run

The `flutter` command is not included with Windows or PowerShell by default. Install the Flutter SDK before running this project:

1. Install Git for Windows and extract the stable Flutter SDK from the [official Flutter installation guide](https://docs.flutter.dev/get-started/install/windows) to a path such as `C:\src\flutter`. Avoid `C:\Program Files` because Flutter needs to update files in its SDK directory.
2. Add `C:\src\flutter\bin` to your **User PATH**. In Windows, search for **Edit environment variables for your account**, open **Path**, choose **New**, and add that folder.
3. Close and reopen PowerShell and VS Code, then verify the installation:

   ```powershell
   flutter --version
   flutter doctor
   ```

4. Install Android Studio and its Android SDK/command-line tools if you want to run the Android version. Accept Android licenses when prompted:

   ```powershell
   flutter doctor --android-licenses
   ```

5. From this project directory, generate the native platform folders and install packages:

   ```powershell
   cd "C:\Users\nandh\OneDrive\Desktop\Advanced Mobile Development"
   flutter create .
   flutter pub get
   ```

6. Add the Android location, camera, photos, and notification permissions to `android/app/src/main/AndroidManifest.xml`. For iOS, add the corresponding `NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription`, and `NSPhotoLibraryUsageDescription` keys to `ios/Runner/Info.plist`.
7. Start an emulator or connect a device, then run:

   ```powershell
   flutter devices
   flutter run
   ```

If `flutter --version` still reports that the command is not recognized, the terminal was opened before PATH was updated. Close all PowerShell/VS Code windows, reopen them, and run the command again. You can also test the SDK directly with `C:\src\flutter\bin\flutter.bat --version`.

To fix only the **current PowerShell window** immediately, run:

```powershell
$env:Path += ";C:\src\flutter\bin"
flutter --version
```

## One-command launch

From any PowerShell window, this single command removes stale generated files, creates the Flutter platform files if needed, installs dependencies, and starts the app:

```powershell
cd "C:\Users\nandh\OneDrive\Desktop\Advanced Mobile Development"; if (Test-Path ".\build") { Remove-Item -LiteralPath ".\build" -Recurse -Force }; & "C:\src\flutter\bin\flutter.bat" create .; if ($?) { & "C:\src\flutter\bin\flutter.bat" pub get }; if ($?) { & "C:\src\flutter\bin\flutter.bat" run }
```

After Flutter has been added to PATH, the shorter version is:

```powershell
cd "C:\Users\nandh\OneDrive\Desktop\Advanced Mobile Development"; flutter create .; if ($?) { flutter pub get }; if ($?) { flutter run }
```

## Fixing locked `build\flutter_assets`

This project is inside OneDrive, which can temporarily lock Flutter's generated files while syncing. Stop the running app, close VS Code terminals that are using this project, pause OneDrive syncing, and run this targeted cleanup command:

```powershell
$buildPath = "C:\Users\nandh\OneDrive\Desktop\Advanced Mobile Development\build"
if (Test-Path $buildPath) { Remove-Item -LiteralPath $buildPath -Recurse -Force }
```

Then run:

```powershell
cd "C:\Users\nandh\OneDrive\Desktop\Advanced Mobile Development"; & "C:\src\flutter\bin\flutter.bat" clean; & "C:\src\flutter\bin\flutter.bat" pub get; & "C:\src\flutter\bin\flutter.bat" run
```

If OneDrive locks the directory again, move or copy the project to a non-synced folder such as `C:\dev\bite_local` and run it there. Flutter projects generally build more reliably outside OneDrive, Dropbox, or other actively synchronized folders.

To add Flutter to your **User PATH permanently** from PowerShell, run this once, then open a new terminal:

```powershell
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*C:\src\flutter\bin*") {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;C:\src\flutter\bin", "User")
}
```

Typing `C:\src\flutter` or `C:\src\flutter\bin` by itself attempts to execute that folder, so it will produce an error. Use the executable path (`C:\src\flutter\bin\flutter.bat`) or add the `bin` folder to PATH as shown above.

The app is intentionally backend-free: placing an order demonstrates the client-side flow and local notification without requiring credentials or a server.
