# flutter_icp_auth:

This Flutter package simplifies integrating ICP internet identity authentication flow within your Flutter application.

## **✨ Features**

* **LOG IN**: Enables users to log in using internet identity.
* **AUTO LOGIN**: Allows users to log in automatically.
* **RELOAD**: Automatically logs in users when the app is reloaded or opened, based on session data/delegationObject.
* **LOGOUT**: Provides functionality for users to log out.

## **⚠️ Important Info**

#### 1. `isLocal` is used to denote whether you are running your application using mainnet links or locally.

* Change the bool value based on your apps requirement.
* If `isLocal` is *true* then replace the values of `backendCanisterId` and `middlePageCanisterId` with the locally deployed canister ids.
* If `isLocal` is *false* then  replace the values of `backendCanisterId` and `middlePageCanisterId` with the main-net deployed canister ids.

#### 2. For local or main-net `backendCanisterId` make sure you have the following function in your backend:

* Rust:

   ```rust
   use ic_cdk::api::caller;
   #[ic_cdk::query]
   fn whoami() -> String {
       let principal_id = caller().to_string();
       format!("principal id - : {:?}", principal_id)
   }
   ```

* Motoko:

   ```motoko
   import Principal "mo:base/Principal";
   actor {
       public shared (msg) func whoami() : async Text {
           Principal.toText(msg.caller);
       };
   };
   ```

  For main-net you can use our canisterId as well: `cni7b-uaaaa-aaaag-qc6ra-cai`

#### 3. For local or main-net `middlePageCanisterId` make sure you have the following:

* **Local:**

  Clone the repo from here and deploy locally: https://github.com/SomyaRanjanSahu/flutter_icp_auth_middleware

* **Main-net:**

  a. You can deploy the cloned [middlePage](https://github.com/SomyaRanjanSahu/flutter_icp_auth_middleware) to main net and use the main net canister id.

  b. You can use our main-net id as well: `nplfj-4yaaa-aaaag-qjucq-cai`

#### 4. For IDL and Services:

* You can use [candid_dart](https://pub.dev/packages/candid_dart) to generate the did files and the IDL services and then use them in the app as demonstrated in the example app.

* You can add/write the file or code manually and then use them accordingly.

## **🚀 Getting Started & Usage**

### **1. Setup**

* **Add these packages in *pubspec.yaml*:**

  ```
  dependencies:
    flutter_icp_auth: ^1.0.0
    uni_links: ^0.5.1
    agent_dart: ^1.0.0-dev.22
    shared_preferences: ^2.2.3
  ```

* **Import the packages in you *main.dart*:**

  ``` 
  import 'package:uni_links/uni_links.dart';
  import 'package:agent_dart/agent_dart.dart';
  import 'package:flutter_icp_auth/flutter_icp_auth.dart';
  import 'package:shared_preferences/shared_preferences.dart';
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
  bool _initialized = false;
  bool isLocal =
      false; // To confirm if you running your project locally or using main-net. Change it to true if running locally
  StreamSubscription? _sub;
  String backendCanisterId =
      'cni7b-uaaaa-aaaag-qc6ra-cai'; // Replace it with your backend canisterId
  String middlePageCanisterId =
      'nplfj-4yaaa-aaaag-qjucq-cai'; // Replace it with your middlePage canisterId
  Service idlService =
      FieldsMethod.idl; // Idl service (Location: lib/services/integration.dart)
  ```

* **Define the initState and dispose methods:**

  ``` 
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  } 
  ```

* **Handle incoming deep links:**

  `isLoggedIn` and `_principalId` are used to change the state of the log in/log out button and principal text. You can modify them according to your applications need.

  ```
  Future<void> initPlatformState() async {
    try {
      // Checking initial link
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      log("Initial Link Error: $e");
    }

    // Attaching listener for later links
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleUri(uri);
      }
    }, onError: (err) {
      log("Later Link Error: $err");
    });
  }

  void _handleUri(uri) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_initialized) {
      // Handling URI when coming from middle page
      String status = uri.queryParameters['status'].toString();
      List<Object> delegationObject = await AuthLogIn.fetchAgent(
          uri.queryParameters, isLocal, backendCanisterId, idlService);

      setState(() {
        isLoggedIn = status == "true" ? true : false;
        _principalId = delegationObject[0].toString();
      });
    } else {
      // Handling URI when app is reloaded or opened directly
      String? savedUri = prefs.getString('last_uri');
      if (savedUri == uri) {
        log('Ignoring last saved URI');
      } else {
        // Performing action based on the URI
        List<Object> validatedDelegation = await AuthLogIn.getDelegations();

        setState(() {
          isLoggedIn = validatedDelegation.whereType<bool>().first == true
              ? true
              : false;
        });
        if (isLoggedIn == true) {
          setState(() {
            _principalId = validatedDelegation[1].toString();
          });
        }
        prefs.setString('last_uri', uri.toString());
      }
      _initialized = true;
    }
  }
  ```    

### **3. Using the IIDLogin Button**

When passing argument in the IIDLogin button, remember to pass your app:host and app:callback:

#### For login button call:

`AuthLogIn.authenticate(isLocal, middlePageCanisterId,
"exampleCallback", "example");`

#### For logout button call:

`List<Object> logoutValidation =
await AuthLogout.logout();`

## **ℹ️ Additional Info:**

#### 📄 Example file location: `example/lib/main.dart`

#### This package depends on the following dependencies:

* agent_dart: ^1.0.0-dev.22
* fluttertoast: ^8.2.5
* uni_links: ^0.5.1
* flutter_custom_tabs: ^2.0.0+1
* flutter_secure_storage: ^9.0.0