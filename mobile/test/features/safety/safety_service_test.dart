import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/safety/data/safety_service.dart';

import '../../support/network_fakes.dart';

void main() {
  test('reports, blocks, lists and unblocks through actor endpoints', () async {
    var requestIndex = 0;
    final adapter = CallbackAdapter((options) {
      requestIndex += 1;
      if (requestIndex == 1) {
        return jsonResponse({
          'success': true,
          'data': {
            'id': 'report-1',
            'targetType': 'ITEM',
            'targetId': 'item-1',
            'reason': 'UNSAFE_ITEM',
            'description': 'У вещи повреждён защитный кожух.',
            'status': 'OPEN',
            'createdAt': '2026-07-30T00:00:00.000Z',
          },
          'error': null,
        });
      }
      if (requestIndex == 2) {
        return jsonResponse({
          'success': true,
          'data': blockedUserJson(),
          'error': null,
        });
      }
      if (requestIndex == 3) {
        return jsonResponse({
          'success': true,
          'data': [blockedUserJson()],
          'error': null,
        });
      }
      return jsonResponse({
        'success': true,
        'data': {'blockedUserId': 'user-2', 'blocked': false},
        'error': null,
      });
    });
    final service = SafetyService(Dio()..httpClientAdapter = adapter);

    await service.createReport(
      targetType: 'ITEM',
      targetId: 'item-1',
      reason: 'UNSAFE_ITEM',
      description: '  У вещи повреждён защитный кожух.  ',
    );
    await service.blockUser('user-2');
    final blocked = await service.listBlockedUsers();
    await service.unblockUser('user-2');

    expect(blocked.single.blocked.name, 'Анна');
    expect(adapter.requests, hasLength(4));
    expect(adapter.requests[0].path, '/reports');
    expect(adapter.requests[0].data, {
      'targetType': 'ITEM',
      'targetId': 'item-1',
      'reason': 'UNSAFE_ITEM',
      'description': 'У вещи повреждён защитный кожух.',
    });
    expect(adapter.requests[1].path, '/users/blocks/user-2');
    expect(adapter.requests[1].method, 'POST');
    expect(adapter.requests[2].path, '/users/blocks');
    expect(adapter.requests[2].method, 'GET');
    expect(adapter.requests[3].path, '/users/blocks/user-2');
    expect(adapter.requests[3].method, 'DELETE');
  });
}

Map<String, Object?> blockedUserJson() => {
  'id': 'block-1',
  'blocked': {'id': 'user-2', 'name': 'Анна'},
  'createdAt': '2026-07-30T00:00:00.000Z',
};
