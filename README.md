# Location Services Logging Test

--

This is a primitive test of iOS location services. Right now it's configured to use significant change service.

The basic idea of this implementation is to provide basic location services logging, logging the interesting information in a SQLite database, which it shows in a table view (in reverse cronological order). The "play" button starts the significant change service. The "pause" button stops it. And the map will show a series of MKPolyline overlays, illustrating the path the user has taken. This logs not only the location events, but also routine app delegate events (the idea being you could diagnose the order that the various methods are being called). Remove some of that logging, or add more; whatever you need for your purposes.

This is for testing purposes only. 

Developed in Xcode 4.6.3 for iOS 6.1. It just happens to use autolayout, but you could turn off autolayout and set the project's base iOS to 5.0 and you should be fine.
