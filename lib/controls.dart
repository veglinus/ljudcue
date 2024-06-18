import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class ControlsTab extends StatefulWidget {
  final AudioPlayer player;
  final Function(int) callback;

  const ControlsTab({
    required this.player,
    super.key,
    required this.callback,
  });

  @override
  State<ControlsTab> createState() => _ControlsTabState();
}

class _ControlsTabState extends State<ControlsTab> {
  final _playerState = ValueNotifier<PlayerState>(PlayerState.stopped);
  Duration? _duration;
  Duration? _position;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;
  String get _durationText => _duration?.toString().split('.').first ?? '';
  String get _positionText => _position?.toString().split('.').first ?? '';
  AudioPlayer get player => widget.player;

  Future<void> _update(Future<void> Function() fn) async {
    await fn();
    // update everyone who listens to "player"
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Use initial values from player
    _playerState.value = player.state;
    player.getDuration().then(
          (value) => setState(() {
            _duration = value;
          }),
        );
    player.getCurrentPosition().then(
          (value) => setState(() {
            _position = value;
          }),
        );
    _initStreams();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
                onPressed: () {
                  widget.callback(-1);
                },
                icon: const Icon(Icons.skip_previous, size: 45.0)),
            IconButton(
              key: const Key('control-stop'),
              icon: const Icon(Icons.stop, size: 45.0),
              onPressed: widget.player.stop,
            ),
            ValueListenableBuilder(
              valueListenable: _playerState,
              builder: (context, value, child) {
                return IconButton(
                  key: const Key('control-play-pause'),
                  icon: Icon(
                    value == PlayerState.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 50.0,
                  ),
                  onPressed: () {
                    if (value == PlayerState.playing) {
                      widget.player.pause();
                    } else {
                      widget.player.resume();
                    }
                  },
                );
              },
            ),
            IconButton(
              key: const Key('control-loop'),
              icon: Icon(
                widget.player.releaseMode == ReleaseMode.loop
                    ? Icons.repeat_on
                    : Icons.repeat,
                size: 45.0,
              ),
              onPressed: () async {
                await _update(() => widget.player.setReleaseMode(
                    widget.player.releaseMode == ReleaseMode.loop
                        ? ReleaseMode.stop
                        : ReleaseMode.loop));
              },
            ),
            IconButton(
                onPressed: () {
                  widget.callback(1);
                },
                icon: const Icon(Icons.skip_next, size: 45.0)),
          ],
        ),
        Slider(
          onChanged: (value) {
            // TODO: If in low latency mode, warn user that seek doesn't work
            final duration = _duration;
            if (duration == null) {
              return;
            }
            final position = value * duration.inMilliseconds;
            player.seek(Duration(milliseconds: position.round()));
          },
          value: (_position != null &&
                  _duration != null &&
                  _position!.inMilliseconds > 0 &&
                  _position!.inMilliseconds < _duration!.inMilliseconds)
              ? _position!.inMilliseconds / _duration!.inMilliseconds
              : 0.0,
        ),
        Text(
          _position != null
              ? '$_positionText / $_durationText'
              : _duration != null
                  ? _durationText
                  : '',
          style: const TextStyle(fontSize: 16.0),
        ),
      ],
    );
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _playerState.value = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState.value = state;
      });
    });
  }
}
