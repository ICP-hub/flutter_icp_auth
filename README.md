# flutter_icp_auth:

This Flutter package simplifies integrating ICP internet identity authentication flow within your Flutter application.

## **✨ Features**

* **LOG IN**: Enables users to log in using internet identity.
* **AUTO LOGIN**: Allows users to log in automatically.
* **RELOAD**: Automatically logs in users when the app is reloaded or opened, based on session data/delegationObject.
* **LOGOUT**: Provides functionality for users to log out.

## **🚀 Getting Started & Usage**

### **1. Setup**

* **Add the package in *pubspec.yaml*:**

  ```
  dependencies:
    flutter_icp_auth: ^1.0.0
  ```

* **Import the package in you *main.dart*:**

  ``` 
  import 'package:flutter_icp_auth/flutter_icp_auth.dart';
  ```

* **Configure Deep Linking in AndroidManifest.XML:**

  Open android → app → src → main → AndroidManifest.XML, , add the following snippet, and replace `android:scheme` and `android:host` with your app's values:

  ```
  <meta-data android:name="flutter_deeplinking_enabled" android:value="true" />
              <intent-filter android:autoVerify="true">
                  <action android:name="android.intent.action.VIEW"/>
                  <category android:name="android.intent.category.DEFAULT"/>
                  <category android:name="android.intent.category.BROWSABLE" />
                  <data android:scheme="your_app_scheme" android:host="your_app_callback" />
                  <data android:scheme="https" />
              </intent-filter>
  ```

### **2. Initialization**

* **Declare your variables:**

  ```
  bool isLocal =
        false; // To confirm if you running your project locally or using main-net. Change it to true if running locally
  StreamSubscription? _sub;
  late List<Object> delegationObject;
  String canisterId =
        'cni7b-uaaaa-aaaag-qc6ra-cai'; // Replace it with your backend canister id
  Service idlService =
        FieldsMethod.idl;
  ```

* **Define the initState and dispose methods:**

  ``` 
  // Add this in the app to check the login state when app is opened
    @override
    void initState() {
      super.initState();
      _checkIfLoggedIn();
      if (isLoggedIn == false) {
        _initUniLinks();
      }
    }

    // Add this to cancel the sub and dispose the state
    @override
    void dispose() {
      _sub?.cancel();
      super.dispose();
    } 
  ```

* **Handle incoming deep links:**

  ```
  Future<void> _initUniLinks() async {
    Future<void> processUri(Uri? uri) async {
      if (uri != null) {
        try {
          delegationObject =
              await IIDLoginState.fetchAgent(uri.queryParameters, isLocal);
          log("Delegation Object: $delegationObject");
          customLoader.showSuccess("Login Successful");
          whoAmI();
        } catch (e) {
          log("fetchAgent Error: $e");
        }
      }
    }

    try {
      final initialLink = await getInitialUri();
      await processUri(initialLink);
    } catch (e) {
      log("initialLink Error: $e");
    }

    _sub = uriLinkStream.listen(
      (Uri? uri) async {
        await processUri(uri);
      },
      onError: (err) {
        log("uriLinkStream Error: $err");
      },
    );
  }
  ```

### **3. Authentication Methods**

You can customize these functions based on your app functionality and design requirements. But, call the below functions inside the mentioned functions to get the data.

* **_checkIfLoggedIn():** Call the `readData()` to get the delegationObject after being validated.

    ```
    delegationObject = await IIDLoginState.readData();
        isLoggedIn = delegationObject.whereType<bool>().first;
    ```    

* **whoAmI():** Call the `getActor()`/`getAllActors()` to get the canisterActor created using the `HttpAgent`

    ```
    CanisterActor newActor = IIDLoginState.getActor(canisterId, idlService);
    ```    

### **4. Using the IIDLogin Button**

When passing argument in the IIDLogin button, remember to pass your app:host and app:callback:

  ```
  IIDLogin(
            text: "Sign In With Internet Identity",
            isComplete: true,
            scheme: "example",
            host: "exampleCallback")
  ```

## **ℹ️ Additional Info:**

#### 📄 Example file location: `example/lib/login.dart`

#### This package depends on the following dependencies:

* agent_dart: ^1.0.0-dev.22
* fluttertoast: ^8.2.5
* uni_links: ^0.5.1
* flutter_custom_tabs: ^2.0.0+1
* flutter_secure_storage: ^9.0.0

#### Your app should have the following dependencies:

* uni_links: ^0.5.1
* agent_dart: ^1.0.0-dev.22