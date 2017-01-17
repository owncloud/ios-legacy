===========
iOS App FAQ
===========

**Issue:**

Enabling the "Background Instant Upload" feature requires that the Owncloud client have access to location services. 

**Resolution:**

The ownCloud iOS App uses the location to wake up the app in background in order to check if there is any new image to be uploaded, if so, images are uploaded.

The iOS App don't send location information to any server.
Files marked "available offline" aren't available offline after editing
-----------------------------------------------------------------------

See https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html for more information.
Currently, there is a limitation in the “Available Offline” feature in the iOS
client application. 
A file *is* editable offline. 
However, after the first edit, if the file is closed it goes into a *"ready to
be synced"* state.
When this happens, until it is synced, only the old version will be available.
The reason why is that each change is, internally, queued separately for syncing
with the remote ownCloud server.
And, these changes are not merged locally until the remote sync finishes. 
What’s more, if a file is edited multiple times, when it is eventually synced
with the remote server, conflicts in the document may also occur.
