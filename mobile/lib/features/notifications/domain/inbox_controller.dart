import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/inbox_event.dart';
import '../data/inbox_service.dart';

final inboxControllerProvider =
    AsyncNotifierProvider.autoDispose<InboxController, InboxState>(
      InboxController.new,
      retry: (_, _) => null,
    );

@immutable
class InboxState {
  const InboxState({
    required this.items,
    required this.nextCursor,
    required this.unreadOnly,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.isMarkingAllRead = false,
  });

  final List<InboxEvent> items;
  final String? nextCursor;
  final bool unreadOnly;
  final bool isLoadingMore;
  final String? loadMoreError;
  final bool isMarkingAllRead;

  InboxState copyWith({
    List<InboxEvent>? items,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? unreadOnly,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    bool? isMarkingAllRead,
  }) {
    return InboxState(
      items: items ?? this.items,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
      isMarkingAllRead: isMarkingAllRead ?? this.isMarkingAllRead,
    );
  }
}

class InboxController extends AsyncNotifier<InboxState> {
  bool _unreadOnly = false;

  @override
  Future<InboxState> build() async {
    final page = await ref
        .watch(inboxServiceProvider)
        .listPage(unreadOnly: _unreadOnly);
    return InboxState(
      items: page.items,
      nextCursor: page.nextCursor,
      unreadOnly: _unreadOnly,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        current.nextCursor == null ||
        current.isLoadingMore) {
      return;
    }
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );
    final next = await AsyncValue.guard(
      () => ref
          .read(inboxServiceProvider)
          .listPage(cursor: current.nextCursor, unreadOnly: current.unreadOnly),
    );
    state = switch (next) {
      AsyncData(:final value) => AsyncData(
        current.copyWith(
          items: [...current.items, ...value.items],
          nextCursor: value.nextCursor,
          clearNextCursor: value.nextCursor == null,
          isLoadingMore: false,
        ),
      ),
      AsyncError(:final error) => AsyncData(
        current.copyWith(
          isLoadingMore: false,
          loadMoreError: userFacingError(
            error,
            fallback: 'Не удалось загрузить старые уведомления',
          ),
        ),
      ),
      _ => AsyncData(current),
    };
  }

  Future<void> setUnreadOnly(bool value) async {
    if (value == _unreadOnly) {
      return;
    }
    _unreadOnly = value;
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(inboxServiceProvider).listPage(unreadOnly: value),
    );
    state = next.whenData(
      (page) => InboxState(
        items: page.items,
        nextCursor: page.nextCursor,
        unreadOnly: value,
      ),
    );
  }

  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null || current.isMarkingAllRead) {
      return;
    }
    state = AsyncData(
      current.copyWith(isMarkingAllRead: true, clearLoadMoreError: true),
    );
    try {
      await ref.read(inboxServiceProvider).markAllRead();
      final page = await ref
          .read(inboxServiceProvider)
          .listPage(unreadOnly: current.unreadOnly);
      state = AsyncData(
        InboxState(
          items: page.items,
          nextCursor: page.nextCursor,
          unreadOnly: current.unreadOnly,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isMarkingAllRead: false,
          loadMoreError: userFacingError(
            error,
            fallback: 'Не удалось отметить уведомления',
          ),
        ),
      );
    }
  }
}
