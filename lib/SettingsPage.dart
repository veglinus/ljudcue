import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:playsound/components/drop_down.dart';

class SettingsPage extends StatefulWidget {
  final AudioPlayer audioPlayer;

  const SettingsPage({super.key, required this.audioPlayer});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AudioPlayer get audioPlayer => widget.audioPlayer;

  AudioContextConfig audioContextConfig = AudioContextConfig();

  // rest of your code
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            if (Platform.isAndroid || Platform.isIOS) ...[
              ListTile(
                title: const Text('Keep awake'),
                trailing: Switch(
                  value: audioContextConfig.stayAwake,
                  onChanged: (bool value) {
                    setState(() {
                      audioContextConfig = AudioContextConfig(stayAwake: value);
                      applySettings();
                    });
                  },
                ),
              ),
              LabeledDropDown<AudioContextConfigRoute>(
                label: 'Audio Route',
                key: const Key('audioRoute'),
                options: {
                  for (final e in AudioContextConfigRoute.values) e: e.name
                },
                selected: audioContextConfig.route,
                onChange: (v) => setState(() {
                  audioContextConfig = AudioContextConfig(route: v!);
                  applySettings();
                }),
              ),
            ],
            /*
            ListTile(
              title: Text('Setting 1'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Handle tap
              },
            ),*/
          ],
        ).toList(),
      ),
    );
  }

  void applySettings() {
    audioPlayer.setAudioContext(audioContextConfig.build());
  }
}
