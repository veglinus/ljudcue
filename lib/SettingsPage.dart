import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:playsound/components/clearprefs.dart';
import 'package:playsound/components/random.dart';
import 'package:playsound/components/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final AudioPlayer player;

  const SettingsPage({super.key, required this.player});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin<SettingsPage> {
  static GlobalAudioScope get _global => AudioPlayer.global;

  AudioPlayer get player => widget.player;

  /// Set config for all platforms
  AudioContextConfig audioContextConfig = AudioContextConfig();

  /// Set config for each platform individually
  AudioContext audioContext = AudioContext();

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Settings'),
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
                      updateConfig(audioContextConfig.copy(stayAwake: value));
                    });
                  },
                ),
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
            const ListTile(
              title: Text("These settings are non persistent for now:"),
            ),
            _genericTab(),
            if (Platform.isAndroid) ...[
              _androidTab(),
            ],
            if (Platform.isIOS) ...[
              _iosTab(),
            ],
            const ClearPrefsTile(),
          ],
        ).toList(),
      ),
    );
  }

  void updateConfig(AudioContextConfig newConfig) {
    try {
      final context = newConfig.build();
      setState(() {
        audioContextConfig = newConfig;
        audioContext = context;
      });
    } on AssertionError catch (e) {
      toast(e.message.toString());
    }
  }

  void updateAudioContextAndroid(AudioContextAndroid contextAndroid) {
    setState(() {
      audioContext = audioContext.copy(android: contextAndroid);
    });
  }

  void updateAudioContextIOS(AudioContextIOS Function() buildContextIOS) {
    try {
      final context = buildContextIOS();
      setState(() {
        audioContext = audioContext.copy(iOS: context);
      });
    } on AssertionError catch (e) {
      toast(e.message.toString());
    }
  }

  Widget _genericTab() {
    return TabContent(
      children: [
        LabeledDropDown<AudioContextConfigRoute>(
          label: 'Audio Route',
          key: const Key('audioRoute'),
          options: {for (final e in AudioContextConfigRoute.values) e: e.name},
          selected: audioContextConfig.route,
          onChange: (v) => updateConfig(
            audioContextConfig.copy(route: v),
          ),
        ),
        LabeledDropDown<AudioContextConfigFocus>(
          label: 'Audio Focus',
          key: const Key('audioFocus'),
          options: {for (final e in AudioContextConfigFocus.values) e: e.name},
          selected: audioContextConfig.focus,
          onChange: (v) => updateConfig(
            audioContextConfig.copy(focus: v),
          ),
        ),
        Cbx(
          'Respect Silence',
          value: audioContextConfig.respectSilence,
          ({value}) =>
              updateConfig(audioContextConfig.copy(respectSilence: value)),
        ),
        Cbx(
          'Stay Awake',
          value: audioContextConfig.stayAwake,
          ({value}) => updateConfig(audioContextConfig.copy(stayAwake: value)),
        ),
      ],
    );
  }

  Widget _androidTab() {
    return TabContent(
      children: [
        Cbx(
          'isSpeakerphoneOn',
          value: audioContext.android.isSpeakerphoneOn,
          ({value}) => updateAudioContextAndroid(
            audioContext.android.copy(isSpeakerphoneOn: value),
          ),
        ),
        Cbx(
          'stayAwake',
          value: audioContext.android.stayAwake,
          ({value}) => updateAudioContextAndroid(
            audioContext.android.copy(stayAwake: value),
          ),
        ),
        LabeledDropDown<AndroidContentType>(
          label: 'contentType',
          key: const Key('contentType'),
          options: {for (final e in AndroidContentType.values) e: e.name},
          selected: audioContext.android.contentType,
          onChange: (v) => updateAudioContextAndroid(
            audioContext.android.copy(contentType: v),
          ),
        ),
        LabeledDropDown<AndroidUsageType>(
          label: 'usageType',
          key: const Key('usageType'),
          options: {for (final e in AndroidUsageType.values) e: e.name},
          selected: audioContext.android.usageType,
          onChange: (v) => updateAudioContextAndroid(
            audioContext.android.copy(usageType: v),
          ),
        ),
        LabeledDropDown<AndroidAudioFocus?>(
          key: const Key('audioFocus'),
          label: 'audioFocus',
          options: {for (final e in AndroidAudioFocus.values) e: e.name},
          selected: audioContext.android.audioFocus,
          onChange: (v) => updateAudioContextAndroid(
            audioContext.android.copy(audioFocus: v),
          ),
        ),
        LabeledDropDown<AndroidAudioMode>(
          key: const Key('audioMode'),
          label: 'audioMode',
          options: {for (final e in AndroidAudioMode.values) e: e.name},
          selected: audioContext.android.audioMode,
          onChange: (v) => updateAudioContextAndroid(
            audioContext.android.copy(audioMode: v),
          ),
        ),
      ],
    );
  }

  Widget _iosTab() {
    final iosOptions = AVAudioSessionOptions.values.map(
      (option) {
        final options = {...audioContext.iOS.options};
        return Cbx(
          option.name,
          value: options.contains(option),
          ({value}) {
            updateAudioContextIOS(() {
              final iosContext = audioContext.iOS.copy(options: options);
              if (value ?? false) {
                options.add(option);
              } else {
                options.remove(option);
              }
              return iosContext;
            });
          },
        );
      },
    ).toList();
    return TabContent(
      children: <Widget>[
        LabeledDropDown<AVAudioSessionCategory>(
          key: const Key('category'),
          label: 'category',
          options: {for (final e in AVAudioSessionCategory.values) e: e.name},
          selected: audioContext.iOS.category,
          onChange: (v) => updateAudioContextIOS(
            () => audioContext.iOS.copy(category: v),
          ),
        ),
        ...iosOptions,
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class LabeledDropDown<T> extends StatelessWidget {
  final String label;
  final Map<T, String> options;
  final T selected;
  final void Function(T?) onChange;

  const LabeledDropDown({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChange,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: CustomDropDown<T>(
        options: options,
        selected: selected,
        onChange: onChange,
      ),
    );
  }
}

class CustomDropDown<T> extends StatelessWidget {
  final Map<T, String> options;
  final T selected;
  final void Function(T?) onChange;
  final bool isExpanded;

  const CustomDropDown({
    required this.options,
    required this.selected,
    required this.onChange,
    this.isExpanded = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      isExpanded: isExpanded,
      value: selected,
      onChanged: onChange,
      items: options.entries
          .map<DropdownMenuItem<T>>(
            (entry) => DropdownMenuItem<T>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
    );
  }
}
