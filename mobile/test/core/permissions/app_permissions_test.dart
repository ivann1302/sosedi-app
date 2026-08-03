import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/permissions/app_permissions.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  test('maps every app capability to its narrow platform permission', () async {
    final client = _FakePermissionClient();
    final gateway = PermissionHandlerGateway(client);

    for (final permission in AppPermission.values) {
      expect(await gateway.request(permission), PermissionStatus.denied);
    }

    expect(client.requested, [
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.photos,
      Permission.notification,
    ]);
  });
}

class _FakePermissionClient implements PermissionClient {
  final requested = <Permission>[];

  @override
  Future<PermissionStatus> request(Permission permission) async {
    requested.add(permission);
    return PermissionStatus.denied;
  }

  @override
  Future<bool> openSettings() async => true;
}
