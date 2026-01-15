// AutobiographyBloc 测试
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_state.dart';
import 'package:voice_autobiography_flutter/domain/repositories/autobiography_repository.dart';
import 'package:voice_autobiography_flutter/domain/repositories/voice_record_repository.dart';
import 'package:voice_autobiography_flutter/domain/usecases/recording_usecases.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/chapter.dart';

import 'autobiography_bloc_test.mocks.dart';

@GenerateMocks([
  AutobiographyRepository,
  VoiceRecordRepository,
  RecordingUseCases,
])
void main() {
  late AutobiographyBloc bloc;
  late MockAutobiographyRepository mockRepository;
  late MockVoiceRecordRepository mockVoiceRepository;
  late MockRecordingUseCases mockRecordingUseCases;

  setUp(() {
    mockRepository = MockAutobiographyRepository();
    mockVoiceRepository = MockVoiceRecordRepository();
    mockRecordingUseCases = MockRecordingUseCases();

    bloc = AutobiographyBloc(
      mockRepository,
      mockVoiceRepository,
      mockRecordingUseCases,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('AutobiographyBloc', () {
    test('初始状态应该正确', () {
      expect(bloc.state.autobiographies, isEmpty);
      expect(bloc.state.isLoading, false);
    });

    final tAutobiography = Autobiography(
      id: '1',
      title: 'Title',
      content: 'Content',
      generatedAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
      chapters: [
        Chapter(
            id: 'c1',
            title: 'Ch1',
            content: 'C1',
            order: 0,
            lastModifiedAt: DateTime.now()),
      ],
    );
    final tAutobiographies = [tAutobiography];

    blocTest<AutobiographyBloc, AutobiographyState>(
      'LoadAutobiographies: 成功时应该更新列表',
      build: () {
        when(mockRepository.getAllAutobiographies())
            .thenAnswer((_) async => Right(tAutobiographies));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadAutobiographies()),
      expect: () => [
        const AutobiographyState(isLoading: true),
        isA<AutobiographyState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having(
                (s) => s.autobiographies, 'autobiographies', tAutobiographies),
      ],
    );

    blocTest<AutobiographyBloc, AutobiographyState>(
      'AddAutobiography: 成功时应该重新加载',
      build: () {
        when(mockRepository.insertAutobiography(any))
            .thenAnswer((_) async => const Right(null));
        when(mockRepository.getAllAutobiographies())
            .thenAnswer((_) async => Right(tAutobiographies));
        return bloc;
      },
      act: (bloc) => bloc.add(AddAutobiography(tAutobiography)),
      expect: () => [
        const AutobiographyState(isLoading: true),
        const AutobiographyState(isLoading: true), // Load triggered
        isA<AutobiographyState>().having(
            (s) => s.autobiographies, 'autobiographies', tAutobiographies)
      ],
    );

    blocTest<AutobiographyBloc, AutobiographyState>(
      'DeleteAutobiography: 成功时应该重新加载',
      build: () {
        when(mockRepository.deleteAutobiography(any))
            .thenAnswer((_) async => const Right(null));
        when(mockRepository.getAllAutobiographies())
            .thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) => bloc.add(const DeleteAutobiography('1')),
      expect: () => [
        const AutobiographyState(isLoading: true),
        const AutobiographyState(isLoading: true),
        isA<AutobiographyState>()
            .having((s) => s.autobiographies, 'autobiographies', isEmpty)
      ],
    );
  });
}
