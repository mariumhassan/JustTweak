//
//  GeneratedConfigurationAccessor.swift
//  Generated by TweakPropertyGenerator
//

import Foundation
import JustTweak

class GeneratedConfigurationAccessor {

    static let tweakManager: TweakManager = {
        var configurations: [Configuration] = []

        // UserDefaultsConfiguration
        #if DEBUG || CONFIGURATION_DEBUG
        let userDefaultsConfiguration_1 = UserDefaultsConfiguration(userDefaults: UserDefaults.standard)
        configurations.append(userDefaultsConfiguration_1)
        #endif

        // LocalConfiguration
        #if DEBUG
        let jsonFileURL_1 = Bundle.main.url(forResource: "LocalTweakProvider_TopPriority_example", withExtension: "json")!
        let localConfiguration_1 = LocalConfiguration(jsonURL: jsonFileURL_1)
        configurations.append(localConfiguration_1)
        #endif

        // LocalConfiguration
        let jsonFileURL_2 = Bundle.main.url(forResource: "LocalTweakProvider_example", withExtension: "json")!
        let localConfiguration_2 = LocalConfiguration(jsonURL: jsonFileURL_2)
        configurations.append(localConfiguration_2)

        let tweakManager = TweakManager(configurations: configurations)
        tweakManager.useCache = true
        return tweakManager
    }()
        
    private var tweakManager: TweakManager {
        return Self.tweakManager
    }

    @TweakProperty(feature: Features.general,
                   variable: Variables.answerToTheUniverse,
                   tweakManager: tweakManager)
    var meaningOfLife: Int

    @TweakProperty(feature: Features.general,
                   variable: Variables.greetOnAppDidBecomeActive,
                   tweakManager: tweakManager)
    var shouldShowAlert: Bool

    @TweakProperty(feature: Features.general,
                   variable: Variables.tapToChangeColorEnabled,
                   tweakManager: tweakManager)
    var isTapGestureToChangeColorEnabled: Bool

    @TweakProperty(feature: Features.uiCustomization,
                   variable: Variables.displayGreenView,
                   tweakManager: tweakManager)
    var canShowGreenView: Bool

    @TweakProperty(feature: Features.uiCustomization,
                   variable: Variables.displayRedView,
                   tweakManager: tweakManager)
    var canShowRedView: Bool

    @TweakProperty(feature: Features.uiCustomization,
                   variable: Variables.displayYellowView,
                   tweakManager: tweakManager)
    var canShowYellowView: Bool

    @TweakProperty(feature: Features.uiCustomization,
                   variable: Variables.labelText,
                   tweakManager: tweakManager)
    var labelText: String

    @TweakProperty(feature: Features.uiCustomization,
                   variable: Variables.redViewAlphaComponent,
                   tweakManager: tweakManager)
    var redViewAlpha: Double
}
