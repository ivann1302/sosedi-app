bool isCleanPublicHttpsUri(Uri? uri) {
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return false;
  }

  final host = uri.host.toLowerCase();
  return host.contains('.') &&
      !host.endsWith('.') &&
      !host.contains(':') &&
      !_ipv4Pattern.hasMatch(host) &&
      !_reservedHostSuffixes.any(host.endsWith);
}

const _reservedHostSuffixes = [
  '.local',
  '.localhost',
  '.test',
  '.invalid',
  '.example',
];
final _ipv4Pattern = RegExp(r'^\d{1,3}(?:\.\d{1,3}){3}$');
