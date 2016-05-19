===========
iOS App FAQ
===========

**Issue:**

Enabling the instant upload feature requires that the Owncloud client have access to location services. 

**Resolution:**

iOS does not allow any execution in background. The ownCloud iOS App use the location to wake up the app in background in order to check if there is any new image to be uploaded.

The iOS App don't send location information to any server.

See https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html for more information.
