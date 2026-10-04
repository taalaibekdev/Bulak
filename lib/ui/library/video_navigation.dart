import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/video_item.dart';
import '../../state/settings_controller.dart';
import '../player/player_page.dart';
import '../player/widgets/time_up_dialog.dart';

/// Открывает плеер, но сначала проверяет дневной лимит.
///
/// Проверку делаем в одном месте, чтобы её нельзя было случайно обойти
/// с любого экрана.
Future<void> openVideo(BuildContext context, VideoItem video) async {
  final settings = context.read<SettingsController>();
  if (settings.isLimitReached) {
    await showTimeUpDialog(context);
    return;
  }
  await Navigator.of(context).push(PlayerPage.route(video));
}
