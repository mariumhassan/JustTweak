![JustTweak Banner](./img/just_tweak_banner.png)

# JustTweak

[![Build Status](https://travis-ci.org/justeat/JustTweak.svg?branch=master)](https://travis-ci.org/justeat/JustTweak)
[![Version](https://img.shields.io/cocoapods/v/JustTweak.svg?style=flat)](http://cocoapods.org/pods/JustTweak)
[![License](https://img.shields.io/cocoapods/l/JustTweak.svg?style=flat)](http://cocoapods.org/pods/JustTweak)
[![Platform](https://img.shields.io/cocoapods/p/JustTweak.svg?style=flat)](http://cocoapods.org/pods/JustTweak)

JustTweak is a framework for feature flagging and A/B testing for iOS apps.
It provides a simple facade interface interacting with multiple providers that are queried respecting a given priority.
Tweaks represent flags used to drive decisions in the client code. 

With JustTweak you can achieve the following:

- use a JSON local configuration providing default values for experimentation 
- use a number of remote configuration providers such as Firebase and Optmizely to run A/B tests and feature flagging   
- enable, disable, and customize features locally at runtime
- provide a dedicated UI for customization (this comes particularly handy for feature that are under development to showcase it to stakeholders)


## Installation

JustTweak is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod "JustTweak"
```

## Implementation

### Integration

- Define a `LocalConfiguration` JSON file including your features. Refer to `LocalTweakProvider_example.json` for a starting point.
- Configure the stack

To configure the stack, you have two options: 

- implement the stack manually
- leverage the code generator tool

#### Manual integration

- Configure the JustTweak stack as following:

```swift
static let tweakManager: TweakManager = {
    var configurations: [Configuration] = []

    // Mutable configuration (to override tweaks from other configurations)
    let userDefaultsConfiguration = UserDefaultsConfiguration(userDefaults: UserDefaults.standard)
    configurations.append(userDefaultsConfiguration)
    
    // Optimizely (remote configuration)
    let optimizelyTweakProvider = OptimizelyTweaksConfiguration()
    optimizelyTweakProvider.userId = UUID().uuidString
    configurations.append(optimizelyTweakProvider)

    // Firebase Remote Config (remote configuration)
    let firebaseTweakProvider = FirebaseTweaksConfiguration()
    configurations.append(firebaseTweakProvider)

    // local JSON configuration (default tweaks)
    let jsonFileURL = Bundle.main.url(forResource: "LocalTweakProvider_example", withExtension: "json")!
    let localConfiguration = LocalConfiguration(jsonURL: jsonFileURL)
    configurations.append(localConfiguration)
    
    return TweakManager(configurations: configurations)
}()
```

- Implement the properties and constants for your features, backed by the `LocalConfiguration`. Refer to `ConfigurationAccessor.swift` for a starting point.

#### Using the code generator tool

- Define the stack configuration in a `.json` file in the following format:

```
{
    "configurations": [
        {
            "type": "UserDefaultsConfiguration",
            "parameter": "UserDefaults.standard",
            "macros": ["DEBUG", "CONFIGURATION_DEBUG"]
        },
        {
            "type": "LocalConfiguration",
            "parameter": "LocalTweakProvider_TopPriority_example",
            "macros": ["DEBUG"]
        },
        {
            "type": "LocalConfiguration",
            "parameter": "LocalTweakProvider_example"
        }
    ],
    "shouldCacheTweaks": true,
    "stackName": "GeneratedConfigurationAccessor"
}
```

In the case whereby a custom configuration is needed, its setup code should be implemented in the configuration. E.g.

```
...
{
    "type": "CustomConfiguration",
    "parameter": "let fc = FirebaseTweakProvider()\n\t\tfc.someValue = true",
    "propertyName": "fc",
    "macros": ["CONFIGURATION_APPSTORE"]
},
...
```

- Add the following to your `Podfile`

```
script_phase :name => '<your_app_target_name>',
             :script => '$PODS_ROOT/JustTweak/Assets/TweakPropertyGenerator.bundle/TweakPropertyGenerator \
             -l $SRCROOT/<path_to_the_local_configuration_json_file> \
             -o $SRCROOT/<path_to_the_output_folder_for_the_generated_code> \
             -c $SRCROOT/<path_to_the_configuration_json_file>',
             :execution_position => :before_compile
```

Every time the target is built, the code generator tool will regenerate the code for the stack. It will include all the properties backing the features defined in the `LocalConfiguration`.

- Add the generated files to you project and start using the stack.

### Implementation details

The order of the objects in the `configurations` array defines the priority of the configurations.

The `MutableConfiguration` with the highest priority, such as `UserDefaultsConfiguration` in the example above, will be used to reflect the changes made in the UI (`TweakViewController`). The `LocalConfiguration` should have the lowest priority as it provides the default values from a local configuration and it's the one used by the `TweakViewController` to populate the UI.


### Usage (basic)

If you have used the code generator tool, the generated stack includes all the feature flags. Simply allocate the accessor object (which name you have defined in the `.json` configuration and use it to access the feature flags.

```
let accessor = GeneratedConfigurationAccessor()
if accessor.meaningOfLife == 42 {
    ...
}
```

See `GeneratedConfigurationAccessor.swift` and `GeneratedConfigurationAccessor+Constants.swift` for an example of generated code.

### Usage (advanced)

If you decided to implement the stack code yourself, you'll have to implemented code for accessing the features via the `TweakManager`.

The three main features of JustTweak can be accessed from the `TweakManager` instance to drive code path decisions.

1. Checking if a feature is enabled

```swift
// check for a feature to be enabled
let enabled = tweakManager.isFeatureEnabled("some_feature")
if enabled {
    // enable the feature
} else {
    // default behaviour
}
```

2. Get the value of a flag for a given feature. `TweakManager` will return the value from the configuration with the highest priority and automatically fallback to the others if no set value is found.

Use either `tweakWith(feature:variable:)` or the provided property wrappers.

```swift
// check for a tweak value
let tweak = tweakManager.tweakWith(feature: "some_feature", variable: "some_flag")
if let tweak = tweak {
    // tweak was found in some configuration, use tweak.value
} else {
    // tweak was not found in any configuration
}
```

`@TweakProperty` and `@OptionalTweakProperty` property wrappers are available to mark properties representing feature flags. Mind that by using these property wrappers, a static instance of `TweakManager` is needed. 

```
@TweakProperty(fallbackValue: <#fallback_value#>,
               feature: <#feature_key#>,
               variable: <#variable_key#>,
               tweakManager: <#TweakManager#>)
var labelText: String
```

```
@OptionalTweakProperty(fallbackValue: <#nillable_fallback_value#>,
                       feature: <#feature_key#>,
                       variable: <#variable_key#>,
                       tweakManager: <#TweakManager#>)
var meaningOfLife: Int?
```

3. Run an A/B test

```swift
// check for a tweak value
let variation = tweakManager.activeVariation(for: "some_experiment")
if let variation = variation {
    // act according to the kind of variation (e.g. "control", "variation_1")
} else {
    // default behaviour
}
```

See `ConfigurationAccessor.swift` for more info.


### Caching

The `TweakManager` provides the option to cache the tweak values in order to improve performance. Caching is disabled by default but can be enabled via the `useCache` property. When enabled, there are two ways to reset the cache:

- call the `resetCache` method on the  `TweakManager`
- post a `TweakConfigurationDidChangeNotification` notification


### Update a configuration at runtime

JustTweak comes with a ViewController that allows the user to edit the `MutableConfiguration` with the highest priority.

```swift
func presentTweakViewController() {
    let tweakViewController = TweakViewController(style: .grouped, tweakManager: <#TweakManager#>)

    // either present it modally
    let tweaksNavigationController =     UINavigationController(rootViewController:tweakViewController)
    tweaksNavigationController.navigationBar.prefersLargeTitles = true
    present(tweaksNavigationController, animated: true, completion: nil)

    // or push it on an existing UINavigationController
    navigationController?.pushViewController(tweakViewController, animated: true)
}
```

When a value is modified in any `MutableConfiguration`, a notification is fired to give the clients the opportunity to react and reflect changes in the UI.

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.defaultCenter().addObserver(self,
                                                   selector: #selector(updateUI),
                                                   name: TweakConfigurationDidChangeNotification,
                                                   object: nil)
}

@objc func updateUI() {
    // update the UI accordingly
}
```


### Customization

JustTweak comes with three configurations out-of-the-box:

- `UserDefaultsConfiguration` which is mutable and uses `UserDefaults` as a key/value store 
- `LocalConfiguration` which is read-only and uses a JSON configuration file that is meant to be the default configuration
- `EphemeralConfiguration` which is simply an instance of `NSMutableDictionary`

In addition, JustTweak defines `Configuration` and `MutableConfiguration` protocols you can implement to create your own configurations to fit your needs. In the example project you can find a few example configurations which you can use as a starting point.


### Notes for the maintainers

The `TweakPropertyGenerator` scheme generates the executable that is shipped as part of JustTweak. When releasing a new version that includes changes in `TweakPropertyGenerator`, make sure that the new binary is copied from the `Build/Products` folder  in the `TweakPropertyGenerator.bundle`.


## License

JustTweak is available under the Apache 2.0 license. See the LICENSE file for more info.


- Just Eat iOS team
