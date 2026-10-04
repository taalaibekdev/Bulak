/// Почему видео не удалось запустить.
///
/// Нужно, чтобы вместо технической ошибки показать ребёнку и родителю
/// понятную подсказку.
enum PlaybackFailureReason {
  /// Ссылка не распознана как ссылка YouTube.
  invalidLink,

  /// Нет подключения к интернету.
  offline,

  /// YouTube не отдаёт поток: видео удалено, приватное или с ограничением.
  notPlayable,

  /// Поток получен, но проигрыватель не смог его открыть.
  playerError,

  /// Любая другая непредвиденная ошибка.
  unknown,
}

/// Итог попытки подготовить воспроизведение.
class PlaybackResult {
  const PlaybackResult._(this.url, this.reason);

  /// Успех: есть адрес прямого потока.
  const PlaybackResult.success(Uri url) : this._(url, null);

  /// Неудача с указанием причины.
  const PlaybackResult.failure(PlaybackFailureReason reason)
    : this._(null, reason);

  final Uri? url;
  final PlaybackFailureReason? reason;

  bool get isSuccess => url != null;
}
