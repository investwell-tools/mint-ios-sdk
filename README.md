### ⚠️ *Remove `pod 'MintFrameworks'` if present in your Podfile*

# **MintSDK iOS – Swift Package Manager Integration Guide**

**Official iOS SDK for Investwell Mint. Integrates mutual funds investment, portfolio tracking, transactions, and KYC onboarding into native iOS and Flutter applications. Distributed via Swift Package Manager (SPM) with precompiled binary XCFrameworks.**

## **Requirements**

| **Requirement** | **Supported Version** |
| --- | --- |
| **iOS Deployment Target** | **iOS 16.0+** |
| **Swift Language Version** | **Swift 5+** |
| **Xcode Version** | **Xcode 15.0+ or 16.0+** |

**Note: In Xcode, under Build Settings → Swift Compiler - Language, ensure Swift Language Version is set to Swift 5 or above.**

## **Repository URL**

**https://github.com/investwell-tools/mint-ios-sdk**

## **Installation via SPM**

1. **Open your project or workspace in Xcode.**
2. **Go to File → Add Package Dependencies.**
3. **Enter the repository URL above in the search box:**  
   `https://github.com/investwell-tools/mint-ios-sdk`
4. **Configure the dependency rule: “Up to Next Major Version” or “Exact Version” — set to 1.1.2 (or latest release).**
5. **Select both `MintFrameworks` and `MintSDK` and add them to your application target.**
6. **Click Add Package.**

## **Permissions Setup (Info.plist)**

Add the following permission strings to your app's `Info.plist`:

- **NSCameraUsageDescription** — Camera access is required for scanning KYC documents.
- **NSPhotoLibraryUsageDescription** — Photo library access is required to upload investment documents.
- **NSFaceIDUsageDescription** — Face ID is required for secure authentication and login.
- **NSLocationWhenInUseUsageDescription** — Location access is required for regulatory compliance during transactions.
- **NSAppTransportSecurity** — set `NSAllowsArbitraryLoads` to `false`.

## **Native iOS (Swift) Integration**

### **Step 1: Configure AppDelegate.swift**

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
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardToolbarManager.shared.isEnabled = true
        return true
    }
}
```

### **Step 2: Open Mint SDK**

```swift
import UIKit
import MintFrameworks

class HomeViewController: UIViewController {

    @IBAction func openMintTapped(_ sender: UIButton) {
        guard let navController = self.navigationController else { return }

        let isSessionActive = MintSDKInvoke().isSessionAvailableForNativeApps(navigationController: navController)
        if isSessionActive {
            print("Mint session is already active")
            return
        }

        MintSDKInvoke().invokeMintApp(
            domain: "yourBrokerDomain",
            token: "userSSOToken",
            navigateToview: "",
            nav: navController,
            colorPrimary: "1A73E8",
            colorToolbar: "FFFFFF",
            launchIcon: UIImage(named: "app_logo"),
            currentTheme: .light
        )
    }

    @IBAction func logoutTapped(_ sender: UIButton) {
        let cleared = MintSDKInvoke().clearSDKSession()
        print("Mint SDK session cleared: \(cleared)")
    }
}
```

## **Flutter Integration (iOS Runner)**

### **Step 1: Add Swift Package to Flutter iOS Project**

1. **Open `ios/Runner.xcworkspace` in Xcode.**
2. **Select the root `Runner` project in the left project navigator.**
3. **Select the Package Dependencies tab.**
4. **Click + and enter:** `https://github.com/investwell-tools/mint-ios-sdk`
5. **Set the version to 1.1.2 and add `MintFrameworks` and `MintSDK` to the Runner target.**

### **Step 2: Update ios/Runner/AppDelegate.swift**

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
                colorPrimary: "1A73E8",
                colorToolbar: "FFFFFF",
                launchIcon: UIImage(named: "app_logo"),
                currentTheme: .light
            )
        }
    }
}
```

### **Step 3: Flutter Dart Implementation**

```dart
import 'package:flutter/services.dart';

class MintSDK {
  static const MethodChannel _channel = MethodChannel('mint-android-app');

  static Future open({
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

  static Future isSessionValid() async {
    try {
      final bool isValid = await _channel.invokeMethod('isValidAuth');
      return isValid;
    } on PlatformException catch (e) {
      print("Failed to check auth: ${e.message}");
      return false;
    }
  }

  static Future clearSDKData() async {
    try {
      await _channel.invokeMethod('clearSession');
    } on PlatformException catch (e) {
      print("Failed to clear session: ${e.message}");
    }
  }
}
```

### **Step 4: Xcode Build Settings (Flutter)**

1. **Open `Runner.xcworkspace` in Xcode.**
2. **Select `Runner` target → Build Settings.**
3. **Search for `User Script Sandboxing` and set it to `NO`.**

## **Session Management Methods**

| **Method** | **Return** | **Environment** | **Purpose** |
| --- | --- | --- | --- |
| **`isSessionAvailableForNativeApps(navigationController:)`** | `Bool` | Native Swift | Checks if an active session already exists in the navigation stack. |
| **`isSessionAvailable()`** | `Bool` | Flutter / Native | Checks if valid session credentials are authenticated. |
| **`clearSDKSession()`** | `Bool` | Flutter / Native | Clears all cached tokens, credentials, and cookies. Must be called on app logout. |

## **Troubleshooting & Common Errors**

### **1. Multiple Commands Produce MintFrameworks.framework / Duplicate Symbols**
- **Error:**
  ```text
  Multiple commands produce '.../MintFrameworks.framework'
  ```
  or duplicate symbol linker errors.
- **Cause:** CocoaPods still references the old `MintFrameworks` pod while Swift Package Manager is also trying to link the framework.
- **Solution:**
  1. Remove `pod 'MintFrameworks'` from your `Podfile`.
  2. In your project root, run:
     ```bash
     pod install
     ```
  3. Clean your build folder in Xcode: **Product → Clean Build Folder** (`Cmd + Shift + K`).
  4. Delete DerivedData:
     ```bash
     rm -rf ~/Library/Developer/Xcode/DerivedData/
     ```

---

### **2. Checksum Mismatch or Package Resolution Failure**
- **Error:**
  ```text
  The checksum of downloaded artifact of binary target does not match checksum from package manifest
  ```
- **Cause:** Xcode cached an older downloaded `.zip` artifact with a different checksum.
- **Solution:**
  1. In Xcode: Select **File → Packages → Reset Package Caches**.
  2. Clear SPM cache from Terminal:
     ```bash
     rm -rf ~/Library/Caches/org.swift.swiftpm/
     rm -rf ~/Library/Developer/Xcode/DerivedData/
     ```
  3. In Xcode: Select **File → Packages → Update to Latest Package Versions**.

---

### **3. Flutter Build Error: User Script Sandboxing (`rsync.sdef` / `PhaseScriptExecution`)**
- **Error:**
  ```text
  Sandbox: rsync.sdef ... Operation not permitted
  Command PhaseScriptExecution failed with a nonzero exit code
  ```
- **Cause:** Xcode 15+ enables script sandboxing by default, which blocks Flutter build and CocoaPods copy scripts.
- **Solution:**
  1. Open `ios/Runner.xcworkspace` in Xcode.
  2. Select the **Runner** target → **Build Settings**.
  3. Search for **User Script Sandboxing** (`ENABLE_USER_SCRIPT_SANDBOXING`).
  4. Set it to **`NO`**.

---

### **4. No Such Module 'MintFrameworks'**
- **Error:**
  ```text
  No such module 'MintFrameworks'
  ```
- **Cause:** The Swift package was added to the project, but the libraries were not linked to the app's target.
- **Solution:**
  1. In Xcode, select your main app target (e.g. `Runner` or native app target).
  2. Go to the **General** tab.
  3. Scroll down to **Frameworks, Libraries, and Embedded Content**.
  4. Click `+` and ensure **both `MintFrameworks` and `MintSDK`** are added.

---

### **5. App Crashes When Opening KYC or Document Upload (Camera / Photos)**
- **Error:**
  ```text
  This app has crashed because it attempted to access privacy-sensitive data without a usage description.
  The app's Info.plist must contain an NSCameraUsageDescription key with a string value...
  ```
- **Cause:** Missing required privacy permission descriptions in `Info.plist`.
- **Solution:**
  Add the required privacy keys into your `Info.plist`:
  - `NSCameraUsageDescription`
  - `NSPhotoLibraryUsageDescription`
  - `NSFaceIDUsageDescription`
  - `NSLocationWhenInUseUsageDescription`

---

### **6. Minimum iOS Deployment Target Error**
- **Error:**
  ```text
  Compiling for iOS 14.0/15.0, but module 'MintFrameworks' has a minimum deployment target of iOS 16.0
  ```
- **Cause:** The host app target has a deployment target lower than iOS 16.0.
- **Solution:**
  1. In Xcode, select your Project and Target.
  2. Under **General → Minimum Deployments**, set **iOS 16.0** or higher.
  3. If using CocoaPods, update your `Podfile`:
     ```ruby
     platform :ios, '16.0'
     ```

---

### **7. Keyboard Overlapping or Presentation Issues**
- **Error:** Text fields covered by the keyboard or missing toolbar navigation.
- **Cause:** `IQKeyboardManager` is either not initialized or disabled.
- **Solution:**
  Ensure both managers are enabled inside `AppDelegate.swift` in `application(_:didFinishLaunchingWithOptions:)`:
  ```swift
  IQKeyboardManager.shared.isEnabled = true
  IQKeyboardToolbarManager.shared.isEnabled = true
  ```

