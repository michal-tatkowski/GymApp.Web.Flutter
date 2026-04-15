enum AuthState {
  /// Token missing or refresh failed.
  unauthenticated,

  /// Valid access token in storage / memory.
  authenticated,
}
