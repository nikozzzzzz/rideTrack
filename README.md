# RideTrack iOS App

A simplistic sports tracking application built with SwiftUI, SwiftData, and CloudKit for iOS 18+.
Track your running, cycling, motorcycle rides, skiing, and walking activities with real-time GPS tracking, detailed statistics, and iCloud synchronization.

## Features

### 🏃‍♂️ Activity Tracking
- **Multiple Activity Types**: Running, Cycling, Motorcycle, Skiing, Walking
- **Real-time GPS Tracking**: High-accuracy location tracking with background support
- **Live Statistics**: Distance, duration, speed, pace tracking during activities
- **Route Visualization**: Interactive maps showing your tracked routes

### 📊 Dashboard & Analytics
- **Activity History**: View all your past rides with detailed statistics
- **Statistics Cards**: Total distance, time, and ride count summaries
- **Search & Filter**: Find specific rides by activity type or search terms
- **Route Maps**: Mini-map previews for each recorded activity

### 👤 User Profile & Cloud Sync
- **iCloud Authentication**: Secure user profile management
- **Profile Statistics**: Personal activity summaries and achievements
- **Cloud Synchronization**: Sync data across all your Apple devices
- **Profile Customization**: Personal information and activity preferences

### 🌍 Internationalization
- **Multi-language Support**: English, Russian, Indonesian, Greek
- **Runtime Language Switching**: Change language without app restart
- **Localized Content**: All UI elements properly localized

### ⚙️ Settings & Customization
- **Unit Preferences**: Metric/Imperial system support
- **Language Selection**: Choose from 4 supported languages
- **Data Management**: Export/import functionality
- **Privacy Controls**: Location and data sharing preferences

##  Architecture

### 🏗️ iOS Development Stack
- **SwiftUI**: Declarative UI framework for iOS 18+
- **SwiftData**: Core Data successor for data persistence
- **CloudKit**: Apple's cloud database for data synchronization
- **Core Location**: High-accuracy GPS tracking with background support
- **MapKit**: Route visualization and mapping

### 📱 App Structure
```
rideTrack/
├── Models/                 # SwiftData models
│   ├── RideSession.swift   # Main ride tracking model
│   ├── LocationPoint.swift # GPS coordinate storage
│   ├── ActivityType.swift  # Activity type definitions
│   ├── UserProfile.swift   # User profile with CloudKit
│   └── UserSettings.swift  # App preferences
├── Views/                  # SwiftUI views
│   ├── Dashboard/          # Main dashboard screens
│   ├── NewRide/           # Activity selection and start
│   ├── CurrentRide/       # Real-time tracking interface
│   ├── Profile/           # User profile management
│   └── Settings/          # App configuration
├── Services/              # Business logic services
│   ├── LocationManager.swift    # GPS tracking service
│   └── iCloudAuthManager.swift  # CloudKit authentication
└── Localization/         # Multi-language translation files
    ├── LocalizationManager.swift
    ├── en.lproj/         # English strings
    ├── ru.lproj/         # Russian strings
    ├── id.lproj/         # Indonesian strings
    └── el.lproj/         # Greek strings
```

### 🔧 Key Components

#### LocationManager
- High-accuracy GPS tracking
- Background location updates
- Battery-optimized tracking
- Route recording and storage

#### iCloudAuthManager
- CloudKit account management
- User authentication flow
- Profile data synchronization
- Cross-device data sync

#### LocalizationManager
- Runtime language switching
- Comprehensive string localization
- Multi-language support system

## Requirements

- **iOS**: 18.0+
- **Xcode**: 16.0+
- **Swift**: 5.9+
- **Device**: iPhone with GPS capability
- **iCloud**: Optional for cloud sync features

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/rideTrack.git
   cd rideTrack
   ```

2. **Open in Xcode**
   ```bash
   open rideTrack.xcodeproj
   ```

3. **Configure Bundle Identifier**
   - Update the bundle identifier in project settings
   - Ensure it matches your Apple Developer account

4. **Enable Capabilities**
   - Background Modes (Location updates)
   - CloudKit (for data synchronization)
   - Location Services

5. **Build and Run**
   - Select your target device or simulator
   - Build and run the project (⌘+R)

## Permissions

The app requires the following permissions:

- **Location Services**: For GPS tracking during activities
- **Background App Refresh**: For continued tracking when app is backgrounded
- **iCloud**: For data synchronization across devices
- **Photo Library**: For profile picture management

## Usage

### Starting a New Activity
1. Open the app and tap "New Ride"
2. Select your activity type (Running, Cycling, etc.)
3. Optionally add a custom title
4. Tap "Start Ride" to begin tracking

### During an Activity
- View real-time statistics (distance, time, speed)
- See your route on the interactive map
- Pause/resume tracking as needed
- Stop the activity when complete

### Viewing History
- Browse all activities in the Dashboard
- Filter by activity type or search by name
- Tap any ride to view detailed statistics
- See route maps and performance data

### Profile Management
- Sign in with iCloud for data sync
- View personal statistics and achievements
- Customize profile information
- Manage activity preferences

## Localization

The app supports 4 languages with complete localization:

- **English** (en) - Default
- **Russian** (ru) - Русский
- **Indonesian** (id) - Bahasa Indonesia  
- **Greek** (el) - Ελληνικά

### Adding New Languages

1. Add new `.lproj` folder in the project
2. Create `Localizable.strings` file with translations
3. Update `AppLanguage` enum in `LocalizationManager.swift`
4. Test language switching functionality

## Future Enhancements

### Planned Features
- **Apple Watch Integration**: Native watchOS companion app
- **Live Activities**: Lock screen real-time updates during rides
- **HealthKit Integration**: Share workout data with Apple Health
- **Push Notifications**: Ride reminders and milestone achievements
- **Advanced Analytics**: Performance trends and insights
- **Social Features**: Share rides and compete with friends
- **Offline Maps**: Download maps for offline tracking
- **Custom Workouts**: Interval training and structured workouts

### Technical Improvements
- **Background Location Optimization**: Enhanced battery efficiency
- **Data Export**: GPX, TCX, and CSV export formats
- **Theme System**: Dark/light mode and custom themes (in the future)
- **Unit Conversion**: Comprehensive metric/imperial support
- **Conflict Resolution**: Advanced CloudKit sync handling

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
6. If you don't get any reply in 2-3 days, please, contact me on nikozzzzzz@gmail.com

### Development Guidelines
- Follow Swift coding conventions
- Add unit tests for new features if you can
- Update localization files for UI changes
- Test on multiple device sizes if you have
- Ensure CloudKit integration works properly

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

### Open Source & App Store Compatible

This project uses the Apache 2.0 license, which allows:
- ✅ **Commercial Use**: Can be used in commercial applications
- ✅ **App Store Publishing**: Compatible with App Store distribution
- ✅ **Modification**: Can be modified and extended
- ✅ **Distribution**: Can be redistributed
- ✅ **Private Use**: Can be used privately
- ⚠️ **Attribution Required**: Must include original copyright notice
- ⚠️ **License Notice**: Must include copy of license in distributions

### Contributing to Open Source

When using this project, please:
1. **Keep Attribution**: Include the original copyright notice
2. **Link Back**: Reference this original repository in your project
3. **Share Improvements**: Consider contributing back improvements via pull requests
4. **Follow License**: Comply with Apache 2.0 license terms... or don't, it is up to you

This ensures the open-source community benefits while allowing commercial use.

