# MintSDK iOS

[![Platform](https://img.shields.io/badge/Platform-iOS%2016.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5%2B-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-15.0%2B%20%7C%2016.0%2B-informational.svg)](https://developer.apple.com/xcode/)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

Official iOS SDK for **Investwell Mint**. Integrates mutual funds investment, portfolio tracking, transactions, and KYC onboarding into native iOS and Flutter applications.

Distributed directly via **Swift Package Manager (SPM)** with precompiled binary XCFrameworks.

---

## 📋 Requirements

| Requirement | Supported Version |
| :--- | :--- |
| **iOS Deployment Target** | iOS 16.0+ |
| **Swift Language Version** | **Swift 5 and above** |
| **Xcode Version** | Xcode 15.0+ or Xcode 16.0+ |

> **Note on Swift Version**:  
> In your Xcode project under **Build Settings → Swift Compiler - Language**, ensure **Swift Language Version** is set to **`Swift 5`** or above.

---

## 📦 Installation via Swift Package Manager (SPM)

1. Open your project or workspace in Xcode.
2. Go to **File → Add Package Dependencies...**
3. In the search box, enter the repository URL:
   ```text
   https://github.com/investwell-tools/mint-ios-sdk
   ```
4. Configure the dependency rule:
   - **Dependency Rule**: `Up to Next Major Version` or `Exact Version`
   - **Version**: `1.0.0`
5. Select **MintFrameworks** and add it to your application target.
6. Click **Add Package**.

---

## 🔐 Permissions Setup (`Info.plist`)

Add the following permission strings to your app's `Info.plist`:

```xml
<!-- Camera Permission (KYC / Document Scanning) -->
<key>NSCameraUsageDescription</key>
<string>Camera access is required for scanning KYC documents.</string>

<!-- Photo Library Permission (Document Uploads) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is required to upload investment documents.</string>

<!-- Face ID / Biometric Authentication -->
<key>NSFaceIDUsageDescription</key>
<string>Face ID is required for secure authentication and login.</string>

<!-- Location Permission (Regulatory Compliance) -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is required for regulatory compliance during transactions.</string>

<!-- App Transport Security (Allow secure HTTPS APIs) -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

---

## 🛠 Native iOS (Swift) Integration

### Step 1: Configure `AppDelegate.swift`

Initialize keyboard management in `application(_:didFinishLaunchingWithOptions:)`:

```swift
import UIKit
import IQKeyboardManagerSwift
import IQKeyboardToolbarManager

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Enable Keyboard Manager
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardToolbarManager.shared.isEnabled = true
        return true
    }
}
```

### Step 2: Open Mint SDK

To launch Mint SDK from your view controller:

```swift
import UIKit
import MintFrameworks

class HomeViewController: UIViewController {

    @IBAction func openMintTapped(_ sender: UIButton) {
        guard let navController = self.navigationController else { return }

        // 1. Check if an active session already exists
        let isSessionActive = MintSDKInvoke().isSessionAvailableForNativeApps(navigationController: navController)
        if isSessionActive {
            print("Mint session is already active")
            return
        }

        // 2. Launch Mint SDK with SSO Token
        MintSDKInvoke().invokeMintApp(
            domain: "yourBrokerDomain",              // e.g. "demo"
            token: "userSSOToken",                  // SSO token from auth API
            navigateToview: "",                     // Pass "" for main dashboard
            nav: navController,                     // Host navigation controller
            colorPrimary: "1A73E8",                 // Hex color without '#'
            colorToolbar: "FFFFFF",                 // Hex color without '#'
            launchIcon: UIImage(named: "app_logo"), // Optional splash logo image
            currentTheme: .light                    // .light, .dark, or .system
        )
    }

    // Call this action on your App's Logout button
    @IBAction func logoutTapped(_ sender: UIButton) {
        let cleared = MintSDKInvoke().clearSDKSession()
        print("Mint SDK session cleared: \(cleared)")
    }
}
```

---

## 📱 Flutter Integration (iOS Runner)

### Step 1: Add Swift Package to Flutter iOS Project

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the root **Runner** project in the left project navigator.
3. Select the **Package Dependencies** tab.
4. Click **`+`** and enter:
   ```text
   https://github.com/investwell-tools/mint-ios-sdk
   ```
5. Set the version to `1.1.4` and add **MintFrameworks** to the **Runner** target.

### Step 2: Update `ios/Runner/AppDelegate.swift`

Replace the contents of `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import MintFrameworks
import IQKeyboardManagerSwift
import IQKeyboardToolbarManager

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardToolbarManager.shared.isEnabled = true

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        let mintChannel = FlutterMethodChannel(
            name: "mint-android-app",
            binaryMessenger: controller.binaryMessenger
        )

        mintChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "openMintLibIOS":
                guard let args = call.arguments as? [String: Any],
                      let ssoToken = args["ssoToken"] as? String,
                      let fcmToken = args["fcmToken"] as? String,
                      let domain = args["domain"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
                    return
                }
                self.invokeMintSDK(ssoToken: ssoToken, fcmToken: fcmToken, domain: domain)
                result("Success")

            case "isValidAuth":
                result(MintSDKInvoke().isSessionAvailable())

            case "clearSession":
                result(MintSDKInvoke().clearSDKSession())

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func invokeMintSDK(ssoToken: String, fcmToken: String, domain: String) {
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            MintSDKInvoke().invokeMintAppFormFlutterApp(
                domain: domain,
                token: ssoToken,
                navigateToview: "",
                controller: rootViewController,
                colorPrimary: "1A73E8",                 // Hex color without '#'
                colorToolbar: "FFFFFF",                 // Hex color without '#'
                launchIcon: UIImage(named: "app_logo"), // Optional splash logo image
                currentTheme: .light                    // .light, .dark, or .system
            )
        }
    }
}
```

### Step 3: Flutter Dart Implementation

In your Flutter app, invoke the SDK using `MethodChannel`:

```dart
import 'package:flutter/services.dart';

class MintSDK {
  static const MethodChannel _channel = MethodChannel('mint-android-app');

  /// Launch the Mint SDK
  static Future<void> open({
    required String ssoToken,
    required String fcmToken,
    required String domain,
  }) async {
    try {
      await _channel.invokeMethod('openMintLibIOS', {
        'ssoToken': ssoToken,
        'fcmToken': fcmToken,
        'domain': domain,
      });
    } on PlatformException catch (e) {
      print("Failed to open Mint SDK: ${e.message}");
    }
  }

  /// Check if session is active
  static Future<bool> isSessionValid() async {
    try {
      final bool isValid = await _channel.invokeMethod('isValidAuth');
      return isValid;
    } on PlatformException catch (e) {
      print("Failed to check auth: ${e.message}");
      return false;
    }
  }

  /// Clear SDK session on app logout
  static Future<void> clearSDKData() async {
    try {
      await _channel.invokeMethod('clearSession');
    } on PlatformException catch (e) {
      print("Failed to clear session: ${e.message}");
    }
  }
}
```

### Step 4: Xcode Build Settings (Flutter)
1. Open `Runner.xcworkspace` in Xcode.
2. Select **Runner** target → **Build Settings**.
3. Search for **User Script Sandboxing** and set it to **`NO`**.

---

## 📖 Parameters Reference

| Parameter | Type | Required | Description |
| :--- | :--- | :---: | :--- |
| `domain` | `String` | **Yes** | Broker / tenant domain identifier (e.g., `"demo"`). |
| `token` | `String` | **Yes** | Single Sign-On (SSO) authentication token. |
| `navigateToview` | `String` | **Yes** | Deep-link target route (pass `""` for the default home dashboard). |
| `nav` / `controller` | `UINavigationController` / `UIViewController` | **Yes** | Host navigation controller (Native) or root view controller (Flutter). |
| `colorPrimary` | `String` | Optional | Primary brand accent color in hex format (e.g. `"1A73E8"`). |
| `colorToolbar` | `String` | Optional | Header and navigation bar background hex color (e.g. `"FFFFFF"`). |
| `launchIcon` | `UIImage?` | Optional | Custom logo image displayed during initial splash loading. |
| `currentTheme` | `SelectedAppTheme` | **Yes** | Theme appearance: `.light`, `.dark`, or `.system`. |
| `layouttype` | `Int` | Optional | Dashboard layout index (default: `1`). |

---

## 🔒 Session Management Methods

| Method | Return | Environment | Purpose |
| :--- | :---: | :---: | :--- |
| `isSessionAvailableForNativeApps(navigationController:)` | `Bool` | Native Swift | Checks if an active session already exists in the navigation stack. |
| `isSessionAvailable()` | `Bool` | Flutter / Native | Checks if valid session credentials are authenticated. |
| `clearSDKSession()` | `Bool` | Flutter / Native | Clears all cached tokens, credentials, and cookies. **Must be called on app logout**. |
