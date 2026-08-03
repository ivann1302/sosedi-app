import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermission { location, camera, photos, notifications }

abstract interface class AppPermissionGateway {
  Future<PermissionStatus> request(AppPermission permission);

  Future<bool> openSettings();
}

final appPermissionGatewayProvider = Provider<AppPermissionGateway>((ref) {
  return PermissionHandlerGateway(const PluginPermissionClient());
});

class PermissionHandlerGateway implements AppPermissionGateway {
  const PermissionHandlerGateway(this._client);

  final PermissionClient _client;

  @override
  Future<PermissionStatus> request(AppPermission permission) {
    return _client.request(_platformPermission(permission));
  }

  @override
  Future<bool> openSettings() => _client.openSettings();

  Permission _platformPermission(AppPermission permission) {
    return switch (permission) {
      AppPermission.location => Permission.locationWhenInUse,
      AppPermission.camera => Permission.camera,
      AppPermission.photos => Permission.photos,
      AppPermission.notifications => Permission.notification,
    };
  }
}

abstract interface class PermissionClient {
  Future<PermissionStatus> request(Permission permission);

  Future<bool> openSettings();
}

class PluginPermissionClient implements PermissionClient {
  const PluginPermissionClient();

  @override
  Future<PermissionStatus> request(Permission permission) =>
      permission.request();

  @override
  Future<bool> openSettings() => openAppSettings();
}
