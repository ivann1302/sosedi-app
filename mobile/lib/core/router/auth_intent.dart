String? safeAppReturnTo(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !uri.path.startsWith('/') ||
      uri.path == '/' ||
      uri.path == '/onboarding' ||
      uri.path == '/update-required' ||
      uri.path == '/auth' ||
      uri.path.startsWith('/auth/')) {
    return null;
  }
  return uri.toString();
}

String publicAuthCancelTarget(String? returnTo) {
  final uri = Uri.tryParse(returnTo ?? '');
  if (uri != null) {
    final segments = uri.pathSegments;
    if (segments.length >= 3 &&
        segments[0] == 'items' &&
        segments[2] == 'booking') {
      return '/items/${segments[1]}';
    }
    if (isPublicAppPath(uri.path)) {
      return uri.toString();
    }
  }
  return '/catalog';
}

bool isPublicAppPath(String path) {
  if (path == '/catalog') {
    return true;
  }
  final segments = Uri(path: path).pathSegments;
  return segments.length == 2 && segments.first == 'items';
}

String routeWithReturnTo(String route, String returnTo) {
  return '$route?returnTo=${Uri.encodeComponent(returnTo)}';
}
