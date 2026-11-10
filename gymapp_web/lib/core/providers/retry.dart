/// Riverpod 3 retries failed providers automatically (exponential backoff).
/// Our providers fail with HTTP Failures (401, 404, validation...) that retrying
/// will not fix, and every screen has its own "Try again" button - so no
/// automatic retries: errors reach the UI immediately.
Duration? noRetry(int retryCount, Object error) => null;
