# HealthKit Setup Instructions

## Important: Enable HealthKit Capability in Xcode

For HealthKit authorization to work, you **MUST** enable the HealthKit capability in Xcode:

1. Open your project in Xcode
2. Select the **Preventa** target
3. Go to the **Signing & Capabilities** tab
4. Click the **+ Capability** button
5. Search for and add **HealthKit**
6. Make sure the **Preventa.entitlements** file is selected in the entitlements field

## Verify Setup

1. The `Preventa.entitlements` file should exist and contain:
   - `com.apple.developer.healthkit` set to `true`

2. The `Info.plist` should contain:
   - `NSHealthShareUsageDescription` - Description for reading health data
   - `NSHealthUpdateUsageDescription` - Description for writing health data

## Testing

1. Build and run the app
2. Tap "Connect Apple Health" button
3. The iOS authorization dialog should appear
4. Grant permission
5. Health data should load automatically

## Troubleshooting

If authorization doesn't work:
- Verify HealthKit capability is enabled in Xcode
- Check that entitlements file is included in build
- Verify Info.plist keys are present
- Check Xcode console for HealthKit logs (look for 🔵 HealthKit messages)

