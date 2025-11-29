#!/bin/bash

# Git commit script for FreeRideTracker refactoring
# This script stages and commits the refactoring changes in logical groups

set -e

echo "🚀 Preparing to commit FreeRideTracker refactoring..."

# Stage and commit new utility files
echo "📦 Committing new utility files..."
git add FreeRideTracker/Utilities/Logger.swift
git add FreeRideTracker/Utilities/Constants.swift
git add FreeRideTracker/Models/ValidationError.swift

git commit -m "feat: add core utility files for improved logging and validation

- Add Logger.swift with centralized os.log-based logging system
- Add Constants.swift with validation thresholds and configuration
- Add ValidationError.swift with typed error system and user-friendly messages

These utilities provide the foundation for improved error handling,
debugging, and data validation throughout the app."

# Stage and commit critical app initialization fix
echo "🔧 Committing critical app initialization fix..."
git add FreeRideTracker/FreeRideTrackerApp.swift

git commit -m "fix: replace fatalError with graceful error handling in app initialization

- Remove fatalError that would crash app on ModelContainer failure
- Add DataStorageErrorView for user-friendly error display
- Implement graceful degradation with proper error logging
- Provide recovery steps to users

This critical fix prevents app crashes on storage initialization failures."

# Stage and commit data model improvements
echo "📊 Committing data model validation improvements..."
git add FreeRideTracker/Models/RideSession.swift
git add FreeRideTracker/Models/LocationPoint.swift

git commit -m "refactor: add comprehensive validation to data models

RideSession improvements:
- Add validation for all calculated properties (duration, pace, speed)
- Implement division by zero protection
- Add NaN and infinity checks for floating-point operations
- Add bounds checking for location points (max 50,000 per ride)
- Validate distance and elevation calculations

LocationPoint improvements:
- Add validation on initialization for all location data
- Implement automatic clamping to valid ranges
- Add validation helpers for coordinates, altitude, speed, course
- Prevent invalid data from corrupting the database

These changes prevent crashes from invalid calculations and ensure data integrity."

# Stage and commit LocationManager refactoring
echo "📍 Committing LocationManager refactoring..."
git add FreeRideTracker/Services/LocationManager.swift

git commit -m "refactor: improve LocationManager thread safety and validation

- Add @MainActor for thread-safe UI updates
- Implement comprehensive location data validation
- Fix memory leaks with weak self in closures
- Replace print statements with structured logging
- Add error recovery mechanisms and proper error state tracking
- Add deinit for resource cleanup
- Validate coordinates, accuracy, timestamps, speed, and altitude

This refactoring significantly improves location tracking stability and reliability."

# Stage and commit service manager improvements
echo "🔄 Committing service manager improvements..."
git add FreeRideTracker/Services/iCloudAuthManager.swift
git add FreeRideTracker/Services/LiveActivityManager.swift
git add FreeRideTracker/Services/NotificationManager.swift

git commit -m "refactor: enhance service managers with better error handling

iCloudAuthManager:
- Fix memory leaks in async closures with proper weak self
- Sanitize error messages to prevent exposing internal details
- Add comprehensive logging for authentication flow
- Improve error handling with user-friendly messages

LiveActivityManager:
- Add update throttling (1s minimum interval) to prevent excessive API calls
- Implement input validation for all update values
- Add proper error handling for start/update/stop operations
- Improve state management and prevent duplicate activities

NotificationManager:
- Enhance logging for all permission states
- Add detailed error handling
- Add openNotificationSettings() helper method

These improvements enhance reliability and user experience across all service managers."

# Stage and commit view improvements
echo "🎨 Committing view improvements..."
git add FreeRideTracker/Views/NewRide/NewRideView.swift

git commit -m "refactor: improve NewRideView error handling and validation

- Add input validation for custom ride titles (max 100 chars)
- Implement automatic trimming and sanitization
- Fix memory leaks in permission request callbacks
- Enhance error logging for save failures
- Improve state management during ride creation
- Add graceful handling when save fails but tracking started

These changes improve user experience and prevent memory leaks."

# Stage and commit project file changes
echo "📝 Committing project configuration..."
git add FreeRideTracker.xcodeproj/project.pbxproj
git add FreeRideTracker/FreeRideTracker-Info.plist

git commit -m "chore: update project configuration for new utility files

- Add new utility files to Xcode project
- Update Info.plist configuration
- Maintain project structure and build settings"

# Remove the commit message file
rm -f COMMIT_MESSAGE.md

echo "✅ All changes committed successfully!"
echo ""
echo "📋 Summary:"
git log --oneline -7
echo ""
echo "🎯 Next steps:"
echo "  1. Review commits: git log"
echo "  2. Push to remote: git push origin main"
echo "  3. Create a pull request if needed"
