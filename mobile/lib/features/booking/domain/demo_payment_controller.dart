import 'package:flutter_riverpod/flutter_riverpod.dart';

const demoPaymentDelay = Duration(milliseconds: 500);

enum DemoPaymentResult { idle, processing, succeeded, declined }

final demoPaymentProvider = NotifierProvider.autoDispose
    .family<DemoPaymentController, DemoPaymentResult, String>(
      DemoPaymentController.new,
    );

class DemoPaymentController extends Notifier<DemoPaymentResult> {
  DemoPaymentController(this.bookingId);

  final String bookingId;

  @override
  DemoPaymentResult build() => DemoPaymentResult.idle;

  Future<void> succeed() => _complete(DemoPaymentResult.succeeded);

  Future<void> decline() => _complete(DemoPaymentResult.declined);

  Future<void> _complete(DemoPaymentResult result) async {
    if (state == DemoPaymentResult.processing || state == result) {
      return;
    }
    state = DemoPaymentResult.processing;
    await Future<void>.delayed(demoPaymentDelay);
    if (ref.mounted) {
      state = result;
    }
  }
}
