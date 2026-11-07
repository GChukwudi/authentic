import 'package:mobile/app/providers.dart';
import 'package:mobile/data/mock/mock_world.dart';
import 'package:mobile/features/scan/scan_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockWorld world;

  setUpAll(() async {
    world = await MockWorld.create();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [mockWorldProvider.overrideWithValue(world)],
    );
    addTearDown(container.dispose);
    // Keep the autoDispose view model alive for the whole test.
    container.listen(scanViewModelProvider, (_, __) {});
    return container;
  }

  for (var i = 0; i < 6; i++) {
    test('demo tag $i ends in its expected verdict', () async {
      final container = makeContainer();
      final tag = world.demoTags[i];

      await container.read(scanViewModelProvider.notifier).onCode(tag.raw);

      final state = container.read(scanViewModelProvider);
      expect(state, isA<ScanDone>());
      expect((state as ScanDone).outcome.verdict.kind, tag.expected);
    });
  }

  test('text that is not a tag fails', () async {
    final container = makeContainer();
    await container.read(scanViewModelProvider.notifier).onCode('hello');
    expect(container.read(scanViewModelProvider), isA<ScanFailed>());
  });

  test('a finished check is added to the history', () async {
    final container = makeContainer();
    final before = world.history.current.length;
    await container
        .read(scanViewModelProvider.notifier)
        .onCode(world.demoTags[1].raw);
    expect(world.history.current.length, before + 1);
  });
}
