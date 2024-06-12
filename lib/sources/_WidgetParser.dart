import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playsound/ProjectManager.dart';
import 'package:playsound/sources/SourceTile.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

Future<SourceTile> getCorrectWidget(
  dynamic input,
  AudioPlayer player,
  ProjectManager project,
  void Function(Widget sourceWidget) removeSourceWidget,
  void Function() onEditSave,
  ValueNotifier<PlayerState> playerState,
  ValueNotifier<Source?> currentlyPlayingSource,
) async {
  Source source;
  bool invalid = false;

  // Fix for projects that are copied (files are in relation to folder)

  switch (input['type']) {
    case 'AssetSource':
      bool assetExists = await isAssetExists(input['source']);
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
      bool isPlayable = await isUrlPlayable(input['source']);
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
      setSource: () => player.setSource(source),
      play: () => player.play(source),
      removeSource: removeSourceWidget,
      source: source,
      onEditSave: () => onEditSave,
      //setSourceKey: const Key('setSource-asset-invalid'),
      title: "Invalid Asset - ${input['title']}",
      subtitle: input['subtitle'],
      buttonColor: Colors.red,
      sourceNotifier: currentlyPlayingSource,
      playerState: playerState,
    );
  } else {
    return SourceTile(
      key: UniqueKey(),
      setSource: () => player.setSource(source),
      play: () => player.play(source),
      removeSource: removeSourceWidget,
      source: source,
      onEditSave: () => onEditSave,
      //setSourceKey: input['setSourceKey'],
      title: input['title'],
      subtitle: input['subtitle'],
      sourceNotifier: currentlyPlayingSource,
      playerState: playerState,
    );
  }
}

Future<bool> isAssetExists(String assetName) async {
  try {
    await rootBundle.load(assetName);
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> isUrlPlayable(String url) async {
  try {
    final response = await http.head(Uri.parse(url));

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      debugPrint("Content type of $url: $contentType");

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
