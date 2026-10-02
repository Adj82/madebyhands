import 'package:firebase_core/firebase_core.dart';

class Failure {
  final String message;
  Failure([this.message = 'An unexpected error occurred.']);
}

/// Turns an exception into text that is safe to show in a snackbar.
///
/// Strips Dart's `Exception:` / `Bad state:` prefixes and maps the common
/// Firebase codes to plain language.
String friendlyErrorMessage(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to do that.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Network unavailable. Check your connection and try again.';
      case 'not-found':
      case 'object-not-found':
        return 'The requested item no longer exists.';
      case 'unauthorized':
        return 'Upload was not permitted. Please sign in again and retry.';
      case 'canceled':
        return 'The operation was cancelled.';
    }
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) return message;
  }
  var message = error.toString().trim();
  for (final prefix in const ['Exception: ', 'Bad state: ', 'Invalid argument(s): ']) {
    while (message.startsWith(prefix)) {
      message = message.substring(prefix.length).trim();
    }
  }
  return message.isEmpty ? 'Something went wrong. Please try again.' : message;
}
