import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:playsound/components/clearprefs.dart';
import 'package:playsound/components/drop_down.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final AudioPlayer audioPlayer;

  const SettingsPage({super.key, required this.audioPlayer});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AudioPlayer get audioPlayer => widget.audioPlayer;
  AudioContextConfig audioContextConfig = AudioContextConfig();
  bool autoPlay = false;
  bool stayAwake = true;
  bool autoSave = true;
  String playerMode = "mediaPlayer";

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        autoPlay = prefs.getBool('autoPlay') ?? false;
        stayAwake = prefs.getBool('stayAwake') ?? true;
        autoSave = prefs.getBool('autoSave') ?? true;
        playerMode = prefs.getString('playerMode') ?? "mediaPlayer";
      });
    });
  }

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
                  onChanged: (bool value) async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setBool('stayAwake', value);
                    setState(() {
                      audioContextConfig = AudioContextConfig(stayAwake: value);
                      stayAwake = value;
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

            // TODO: Apply the autosave setting in code
            ListTile(
              title: const Text('Autosave'),
              trailing: Switch(
                value: autoSave,
                onChanged: (bool value) async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setBool('autoSave', value);
                  setState(() {
                    autoSave = value;
                  });
                },
              ),
            ),

            ListTile(
              title: const Text('Player Mode'),
              trailing: Switch(
                value: playerMode == 'mediaPlayer',
                onChanged: (bool value) async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setString(
                      'playerMode', value ? 'mediaPlayer' : 'lowLatency');
                  setState(() {
                    playerMode = value ? 'mediaPlayer' : 'lowLatency';
                  });
                },
              ),
              subtitle: Text(playerMode),
            ),

            ListTile(
              title: const Text('Autoplay'),
              trailing: Switch(
                value: autoPlay,
                onChanged: (bool value) async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setBool('autoPlay', value);
                  setState(() {
                    autoPlay = value;
                  });
                },
              ),
            ),

            const ClearPrefsTile(),
          ],
        ).toList(),
      ),
    );
  }

  void applySettings() {
    audioPlayer.setAudioContext(audioContextConfig.build());
  }
}
