// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:voice_autobiography_flutter/core/services/prompt_loader_service.dart'
    as _i679;
import 'package:voice_autobiography_flutter/data/repositories/ai_generation_repository_impl.dart'
    as _i18;
import 'package:voice_autobiography_flutter/data/repositories/autobiography_version_repository_impl.dart'
    as _i799;
import 'package:voice_autobiography_flutter/data/repositories/file_autobiography_repository.dart'
    as _i1015;
import 'package:voice_autobiography_flutter/data/repositories/file_voice_record_repository.dart'
    as _i158;
import 'package:voice_autobiography_flutter/data/repositories/voice_recognition_repository_impl.dart'
    as _i109;
import 'package:voice_autobiography_flutter/data/services/ai_generation_persistence_service.dart'
    as _i724;
import 'package:voice_autobiography_flutter/data/services/audio_recording_service.dart'
    as _i545;
import 'package:voice_autobiography_flutter/data/services/auto_sync_service.dart'
    as _i681;
import 'package:voice_autobiography_flutter/data/services/auto_tagger_service.dart'
    as _i1073;
import 'package:voice_autobiography_flutter/data/services/autobiography_structure_service_impl.dart'
    as _i788;
import 'package:voice_autobiography_flutter/data/services/background_ai_service.dart'
    as _i783;
import 'package:voice_autobiography_flutter/data/services/cloud_sync_service.dart'
    as _i550;
import 'package:voice_autobiography_flutter/data/services/database_service.dart'
    as _i1007;
import 'package:voice_autobiography_flutter/data/services/doubao_ai_service.dart'
    as _i456;
import 'package:voice_autobiography_flutter/data/services/enhanced_audio_recording_service.dart'
    as _i384;
import 'package:voice_autobiography_flutter/data/services/interview_question_pool.dart'
    as _i807;
import 'package:voice_autobiography_flutter/data/services/interview_service.dart'
    as _i656;
import 'package:voice_autobiography_flutter/data/services/permission_service.dart'
    as _i1019;
import 'package:voice_autobiography_flutter/data/services/xunfei_asr_service.dart'
    as _i856;
import 'package:voice_autobiography_flutter/domain/repositories/ai_generation_repository.dart'
    as _i138;
import 'package:voice_autobiography_flutter/domain/repositories/autobiography_repository.dart'
    as _i1000;
import 'package:voice_autobiography_flutter/domain/repositories/autobiography_version_repository.dart'
    as _i473;
import 'package:voice_autobiography_flutter/domain/repositories/voice_recognition_repository.dart'
    as _i924;
import 'package:voice_autobiography_flutter/domain/repositories/voice_record_repository.dart'
    as _i372;
import 'package:voice_autobiography_flutter/domain/services/autobiography_structure_service.dart'
    as _i534;
import 'package:voice_autobiography_flutter/domain/usecases/ai_generation_usecases.dart'
    as _i70;
import 'package:voice_autobiography_flutter/domain/usecases/autobiography_version_usecases.dart'
    as _i1066;
import 'package:voice_autobiography_flutter/domain/usecases/recognition_usecases.dart'
    as _i112;
import 'package:voice_autobiography_flutter/domain/usecases/recording_usecases.dart'
    as _i526;
import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_bloc.dart'
    as _i640;
import 'package:voice_autobiography_flutter/presentation/bloc/auth/auth_bloc.dart'
    as _i776;
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_bloc.dart'
    as _i966;
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography_version/autobiography_version_bloc.dart'
    as _i422;
import 'package:voice_autobiography_flutter/presentation/bloc/integrated_recording/integrated_recording_bloc.dart'
    as _i698;
import 'package:voice_autobiography_flutter/presentation/bloc/interview/interview_bloc.dart'
    as _i849;
import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_bloc.dart'
    as _i56;
import 'package:voice_autobiography_flutter/presentation/bloc/voice_recognition/voice_recognition_bloc.dart'
    as _i54;
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_bloc.dart'
    as _i369;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.factory<_i526.GenerateAutobiographyUseCase>(
        () => _i526.GenerateAutobiographyUseCase());
    gh.singleton<_i679.PromptLoaderService>(() => _i679.PromptLoaderService());
    gh.singleton<_i545.AudioRecordingService>(
        () => _i545.AudioRecordingService());
    gh.singleton<_i1007.DatabaseService>(() => _i1007.DatabaseService());
    gh.singleton<_i807.InterviewQuestionPool>(
        () => _i807.InterviewQuestionPool());
    gh.singleton<_i1019.PermissionService>(() => _i1019.PermissionService());
    gh.singleton<_i856.XunfeiAsrService>(() => _i856.XunfeiAsrService());
    gh.lazySingleton<_i1073.AutoTaggerService>(
        () => _i1073.AutoTaggerService());
    gh.lazySingleton<_i783.BackgroundAiService>(
        () => _i783.BackgroundAiService());
    gh.lazySingleton<_i724.AiGenerationPersistenceService>(() =>
        _i724.AiGenerationPersistenceService(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i1000.AutobiographyRepository>(
        () => _i1015.FileAutobiographyRepository());
    gh.lazySingleton<_i550.CloudSyncService>(
        () => _i550.CloudSyncService(dio: gh<_i361.Dio>()));
    gh.lazySingleton<_i372.VoiceRecordRepository>(
        () => _i158.FileVoiceRecordRepository());
    gh.lazySingleton<_i924.VoiceRecognitionRepository>(() =>
        _i109.VoiceRecognitionRepositoryImpl(gh<_i856.XunfeiAsrService>()));
    gh.singleton<_i384.EnhancedAudioRecordingService>(() =>
        _i384.EnhancedAudioRecordingService(gh<_i856.XunfeiAsrService>()));
    gh.singleton<_i681.AutoSyncService>(() => _i681.AutoSyncService(
          gh<_i550.CloudSyncService>(),
          gh<_i372.VoiceRecordRepository>(),
          gh<_i1000.AutobiographyRepository>(),
        ));
    gh.lazySingleton<_i473.AutobiographyVersionRepository>(() =>
        _i799.AutobiographyVersionRepositoryImpl(gh<_i1007.DatabaseService>()));
    gh.singleton<_i456.DoubaoAiService>(
        () => _i456.DoubaoAiService.init(gh<_i679.PromptLoaderService>()));
    gh.singleton<_i656.InterviewService>(() => _i656.InterviewService(
          gh<_i456.DoubaoAiService>(),
          gh<_i372.VoiceRecordRepository>(),
          gh<_i1007.DatabaseService>(),
          gh<_i807.InterviewQuestionPool>(),
        ));
    gh.factory<_i112.RecognitionUseCases>(() =>
        _i112.RecognitionUseCases(gh<_i924.VoiceRecognitionRepository>()));
    gh.factory<_i698.IntegratedRecordingBloc>(() =>
        _i698.IntegratedRecordingBloc(
            gh<_i384.EnhancedAudioRecordingService>()));
    gh.factory<_i54.VoiceRecognitionBloc>(
        () => _i54.VoiceRecognitionBloc(gh<_i112.RecognitionUseCases>()));
    gh.lazySingleton<_i138.AiGenerationRepository>(
        () => _i18.AiGenerationRepositoryImpl(gh<_i456.DoubaoAiService>()));
    gh.factory<_i776.AuthBloc>(() => _i776.AuthBloc(
          gh<_i550.CloudSyncService>(),
          gh<_i681.AutoSyncService>(),
          gh<_i372.VoiceRecordRepository>(),
          gh<_i1000.AutobiographyRepository>(),
        ));
    gh.factory<_i534.AutobiographyStructureService>(() =>
        _i788.AutobiographyStructureServiceImpl(gh<_i456.DoubaoAiService>()));
    gh.factory<_i1066.AutobiographyVersionUseCases>(() =>
        _i1066.AutobiographyVersionUseCases(
            gh<_i473.AutobiographyVersionRepository>()));
    gh.factory<_i849.InterviewBloc>(
        () => _i849.InterviewBloc(gh<_i656.InterviewService>()));
    gh.factory<_i526.RecordingUseCases>(() => _i526.RecordingUseCases(
          gh<_i372.VoiceRecordRepository>(),
          gh<_i1000.AutobiographyRepository>(),
          gh<_i138.AiGenerationRepository>(),
          gh<_i526.GenerateAutobiographyUseCase>(),
        ));
    gh.factory<_i369.VoiceRecordBloc>(() => _i369.VoiceRecordBloc(
          gh<_i372.VoiceRecordRepository>(),
          gh<_i526.RecordingUseCases>(),
          gh<_i1073.AutoTaggerService>(),
        ));
    gh.factory<_i70.AiGenerationUseCases>(
        () => _i70.AiGenerationUseCases(gh<_i138.AiGenerationRepository>()));
    gh.factory<_i422.AutobiographyVersionBloc>(() =>
        _i422.AutobiographyVersionBloc(
            gh<_i1066.AutobiographyVersionUseCases>()));
    gh.factory<_i966.AutobiographyBloc>(() => _i966.AutobiographyBloc(
          gh<_i1000.AutobiographyRepository>(),
          gh<_i372.VoiceRecordRepository>(),
          gh<_i526.RecordingUseCases>(),
        ));
    gh.factory<_i640.AiGenerationBloc>(() => _i640.AiGenerationBloc(
          gh<_i70.AiGenerationUseCases>(),
          gh<_i1000.AutobiographyRepository>(),
          gh<_i783.BackgroundAiService>(),
          gh<_i724.AiGenerationPersistenceService>(),
        ));
    gh.factory<_i56.RecordingBloc>(
        () => _i56.RecordingBloc(gh<_i526.RecordingUseCases>()));
    return this;
  }
}
