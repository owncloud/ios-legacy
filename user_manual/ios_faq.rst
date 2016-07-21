===========
iOS App FAQ
===========

**Issue:**

Enabling the "Background Instant Upload" feature requires that the Owncloud client have access to location services. 

**Resolution:**

The ownCloud iOS App uses the location to wake up the app in background in order to check if there is any new image to be uploaded, if so, images are uploaded.

The iOS App don't send location information to any server.

See https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html for more information.
