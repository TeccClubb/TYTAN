#!/bin/bash

# Build and install the app using xcodebuild directly
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug -destination "platform=iOS,id=00008120-000A43000A28C01E" -allowProvisioningUpdates build

# Install the app
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug -destination "platform=iOS,id=00008120-000A43000A28C01E" -allowProvisioningUpdates install
