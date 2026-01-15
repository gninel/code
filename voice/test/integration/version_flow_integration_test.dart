import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:voice_autobiography_flutter/data/repositories/autobiography_version_repository_impl.dart';
import 'package:voice_autobiography_flutter/data/services/database_service.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';

void main() {
  late DatabaseService databaseService;
  late AutobiographyVersionRepositoryImpl versionRepo;

  setUpAll(() {
    // Initialize FFI for desktop/test environment
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Use in-memory database
    databaseService = DatabaseService.forTesting();
    // Ensure DB is initialized
    await databaseService.database;

    versionRepo = AutobiographyVersionRepositoryImpl(databaseService);
  });

  tearDown(() async {
    await databaseService.close();
  });

  test('Integration: Save Version -> Restore -> Verify Persistence', () async {
    const autoId = 'test_auto_id_1';
    const initialContent = 'Initial content';

    // 1. Save a version properly
    print('--- Step 1: Saving Version ---');
    final saveResult = await versionRepo.saveVersion(
      autobiographyId: autoId,
      versionName: 'Version 1',
      content: initialContent,
      chapters: [],
      wordCount: 100,
    );

    expect(saveResult.isRight(), true,
        reason: 'Version should be saved successfully');
    String? versionId;
    saveResult.fold((l) => null, (r) => versionId = r.id);
    print('Saved Version ID: $versionId');

    // 2. Verify it exists in the list
    print('--- Step 2: Verifying Initial List ---');
    final listResult1 = await versionRepo.getVersions(autobiographyId: autoId);
    expect(listResult1.isRight(), true);
    final versions1 = listResult1.fold((l) => [], (r) => r);
    expect(versions1.length, 1, reason: 'Should have 1 version saved');
    expect(versions1.first.id, versionId);

    // 3. Simulate Restore Operation (Update Autobiography)
    // In the real app, this updates the Autobiography entity.
    // Does this affect the version repository? It shouldn't, but let's check.
    // The key is: does the 'autobiographyId' change? Or does the data get wiped?
    print('--- Step 3: Simulating Restore (Update Autobiography Entity) ---');
    final restoredAutobiography = Autobiography(
      id: autoId, // ID must remain same
      title: 'Restored Title',
      content: initialContent,
      generatedAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
      voiceRecordIds: const [],
    );
    // Note: The repository update for Autobiography is separate (FileAutobiographyRepository),
    // but here we verify if accessing versions via the ID still works.

    // 4. Verify persistence after "Restore"
    print('--- Step 4: Verifying List After Restore ---');
    final listResult2 = await versionRepo.getVersions(
        autobiographyId: restoredAutobiography.id);
    expect(listResult2.isRight(), true);
    final versions2 = listResult2.fold((l) => [], (r) => r);

    print('Versions found properly: ${versions2.length}');
    if (versions2.isNotEmpty) {
      print('First version ID: ${versions2.first.id}');
    }

    expect(versions2.length, 1,
        reason: 'Version should persist after restore simulation');
    expect(versions2.first.id, versionId);
  });

  test('Integration: Multi-Version Save and Limit', () async {
    const autoId = 'test_auto_id_limit';

    // Save 25 versions
    for (int i = 0; i < 25; i++) {
      await versionRepo.saveVersion(
        autobiographyId: autoId,
        versionName: 'Version $i',
        content: 'Content $i',
        chapters: [],
        wordCount: 100 + i,
      );
    }

    final listResult = await versionRepo.getVersions(autobiographyId: autoId);
    final versions = listResult.fold((l) => throw l, (r) => r);

    print('Total versions: ${versions.length}');
    expect(versions.length, 20,
        reason: 'Should respect max version limit of 20');
    // The newest should be Version 24
    expect(versions.first.versionName, 'Version 24');
  });
}
