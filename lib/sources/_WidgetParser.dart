import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playsound/ProjectManager.dart';
import 'package:playsound/sources/SourceTile.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

Future<SourceTile> getCorrectWidget(
  int index,
  dynamic input,
  AudioPlayer player,
  ProjectManager project,
  void Function(Widget sourceWidget) removeSourceWidget,
  void Function() onEditSave,
  final ValueNotifier<PlayerState> playerState,
  final ValueNotifier<Source?> currentlyPlayingSource,
  final ValueNotifier<int> currentlyPlayingIndex,
) async {
  Source source;
  bool invalid = false;

  // Fix for projects that are copied (files are in relation to folder)

  switch (input['type']) {
    case 'AssetSource':
      bool assetExists = await _isAssetExists(input['source']);
      if (!assetExists) {
        invalid = true;
      }
      source = AssetSource(input['source']);
      break;
    case 'DeviceFileSource':
      if (input['projectCopied'] != null) {
        String dirpath = path.dirname(project.currentProject.value);
        String newPath = "$dirpath/${input['source']}";
        input['source'] = newPath;
      }
      File file = File(input['source']);
      bool fileExists = await file.exists();
      if (!fileExists) {
        invalid = true;
      }
      source = DeviceFileSource(input['source']);
      break;
    case 'UrlSource':
      bool isPlayable = await _isUrlPlayable(input['source']);
      if (!isPlayable) {
        invalid = true;
      }
      source = UrlSource(input['source']);
      break;
    default:
      source = AssetSource('Invalid asset');
      invalid = true;
      break;
  }

  if (invalid) {
    return SourceTile(
      key: UniqueKey(),
      setSource: () {
        debugPrint("set source");
        player.setSource(source);
        currentlyPlayingSource.value = source;
        currentlyPlayingIndex.value = index;
      },
      play: () => player.play(source),
      removeSource: removeSourceWidget,
      source: source,
      onEditSave: () => onEditSave,
      //setSourceKey: const Key('setSource-asset-invalid'),
      title: "Invalid Asset",
      subtitle: input['subtitle'],
      buttonColor: Colors.red,
      currentlyPlayingSource: currentlyPlayingSource,
      playerState: playerState,
    );
  } else {
    return SourceTile(
      key: UniqueKey(),
      setSource: () {
        debugPrint("set source");
        player.setSource(source);
        currentlyPlayingSource.value = source;
        currentlyPlayingIndex.value = index;
      },
      play: () => player.play(source),
      removeSource: removeSourceWidget,
      source: source,
      onEditSave: () => onEditSave,
      //setSourceKey: input['setSourceKey'],
      title: input['title'],
      subtitle: input['subtitle'],
      currentlyPlayingSource: currentlyPlayingSource,
      playerState: playerState,
    );
  }
}

Future<bool> _isAssetExists(String assetName) async {
  try {
    await rootBundle.load(assetName);
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> _isUrlPlayable(String url) async {
  try {
    final response = await http.head(Uri.parse(url));

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      //debugPrint("Content type of $url: $contentType");

      if (contentType != null) {
        // Maybe be more specific here, rn as long as link is valid file is valid
        return true;
      }
    }
  } catch (e) {
    return false;
  }
  return false;
}
