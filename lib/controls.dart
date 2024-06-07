import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class ControlsTab extends StatefulWidget {
  final AudioPlayer player;

  const ControlsTab({
    required this.player,
    super.key,
  });

  @override
  State<ControlsTab> createState() => _ControlsTabState();
}

class _ControlsTabState extends State<ControlsTab>
    with AutomaticKeepAliveClientMixin<ControlsTab> {
  String modalInputSeek = '';

  double currentDuration = 0.0;
  ValueNotifier<PlayerState> playerStateNotifier =
      ValueNotifier(PlayerState.stopped);

  @override
  void initState() {
    super.initState();
    widget.player.onDurationChanged.listen(updateDuration);
    widget.player.onPlayerStateChanged.listen(updatePlayerState);
  }

  Future<void> _update(Future<void> Function() fn) async {
    await fn();
    // update everyone who listens to "player"
    //debugPrint("update");
    setState(() {});
  }

  void updateDuration(Duration duration) async {
    setState(() {
      currentDuration = duration.inMilliseconds.toDouble();
    });
    //debugPrint('Duration set to: ${duration.inMilliseconds}ms');
  }

  void updatePlayerState(PlayerState state) {
    setState(() {
      playerStateNotifier.value = state;
    });
    //debugPrint("Player state set to: $state");
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    playerStateNotifier = ValueNotifier(widget.player.state);

    return Center(
      child: Container(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      key: const Key('control-stop'),
                      icon: const Icon(Icons.stop, size: 45.0),
                      onPressed: widget.player.stop,
                    ),
                    ValueListenableBuilder(
                      valueListenable: playerStateNotifier,
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
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<Duration>(
                        stream: widget.player.onPositionChanged,
                        builder: (BuildContext context,
                            AsyncSnapshot<Duration> snapshot) {
                          if (snapshot.hasData) {
                            return Slider(
                              value: snapshot.data!.inMilliseconds.toDouble(),
                              min: 0.0,
                              max: currentDuration,
                              onChanged: (double value) {
                                widget.player.seek(
                                    Duration(milliseconds: value.toInt()));
                              },
                            );
                          } else {
                            //return const CircularProgressIndicator();
                            return const Slider(
                              value: 0.0,
                              min: 0.0,
                              max: 1.0,
                              onChanged: null,
                              activeColor: Colors
                                  .grey, // Optional: change the color to indicate disabled state
                              inactiveColor: Colors.grey,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Slider(
                      value: widget.player.volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (double value) async {
                        await _update(() => widget.player.setVolume(value));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
