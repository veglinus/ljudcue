# ljudcue
A simple audio player for playing stems. Made for live sound engineers.
Built in Flutter for all platforms.

## Todo:

### In progress:
- [ ] https://denis-korovitskii.medium.com/flutter-demo-audioplayers-on-background-via-audio-service-c95d65c90ae1
- [ ] Display waveforms
- - [ ] Advanced seek with waveform display and choosing area to play
- [ ] Change how individual stems are played (playback, volume, etc.)
- [ ] MSIX installer
- [ ] Sample project included

### Optional:
- [ ] Webserver for LAN remote control

### Done:
- [x] Change output device on desktop
- [x] Seek (scrubbing)
- [x] Save session
- [x] Load session
- [x] Some kind of session management
- [x] Next, previous stems in controls
- [x] Keep awake setting always on
- [x] Save projects with all stems included so they can be shared

# How to run

## Windows
Build with `flutter build windows` or create msix package with `flutter pub run msix:create`.

## Linux
Following this tutorial: https://medium.com/@fluttergems/packaging-and-distributing-flutter-desktop-apps-the-missing-guide-part-3-linux-24ef8d30a5b4

Build with `flutter_distributor release --name=dev --jobs=release-dev-linux-deb`