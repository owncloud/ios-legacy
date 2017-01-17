===========
iOS App FAQ
===========

Enabling "Background Instant Upload" requires the Owncloud client to have access to location services 
-----------------------------------------------------------------------------------------------------

In order to check for new images to be uploaded, the ownCloud iOS application
uses location services to wake the application in background. 
If new images are ready to be uploaded, they are then uploaded.

.. NOTE::
   The iOS App don't send location information to any server.

See https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html for more information.

Files marked "available offline" aren't available offline after editing
-----------------------------------------------------------------------

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
