import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../data/services/cloud_sync_service.dart';
import '../../../domain/repositories/voice_record_repository.dart';
import '../../../domain/repositories/autobiography_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CloudSyncService _cloudSyncService;
  final VoiceRecordRepository _voiceRecordRepository;
  final AutobiographyRepository _autobiographyRepository;

  AuthBloc(
    this._cloudSyncService,
    this._voiceRecordRepository,
    this._autobiographyRepository,
  ) : super(const AuthState()) {
    on<InitAuth>(_onInitAuth);
    on<Login>(_onLogin);
    on<Register>(_onRegister);
    on<Logout>(_onLogout);
    on<UploadData>(_onUploadData);
    on<DownloadData>(_onDownloadData);
  }

  Future<void> _onInitAuth(InitAuth event, Emitter<AuthState> emit) async {
    try {
      await _cloudSyncService.init();
      if (_cloudSyncService.isLoggedIn) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: _cloudSyncService.currentUser,
        ));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLogin(Login event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));

    try {
      final user = await _cloudSyncService.login(event.email, event.password);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRegister(Register event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));

    try {
      final user = await _cloudSyncService.register(
        event.email, 
        event.password,
        nickname: event.nickname,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLogout(Logout event, Emitter<AuthState> emit) async {
    await _cloudSyncService.logout();
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
    ));
  }

  Future<void> _onUploadData(UploadData event, Emitter<AuthState> emit) async {
    if (!_cloudSyncService.isLoggedIn) {
      emit(state.copyWith(
        syncStatus: SyncStatus.error,
        syncMessage: '请先登录',
      ));
      return;
    }

    emit(state.copyWith(syncStatus: SyncStatus.uploading, syncMessage: null));

    try {
      // 获取本地数据
      final voiceRecordsResult = await _voiceRecordRepository.getAllVoiceRecords();
      final autobiographiesResult = await _autobiographyRepository.getAllAutobiographies();

      final voiceRecords = voiceRecordsResult.fold(
        (failure) => throw Exception(failure.message),
        (records) => records,
      );

      final autobiographies = autobiographiesResult.fold(
        (failure) => throw Exception(failure.message),
        (autos) => autos,
      );

      // 上传到云端
      await _cloudSyncService.uploadData(
        voiceRecords: voiceRecords,
        autobiographies: autobiographies,
      );

      emit(state.copyWith(
        syncStatus: SyncStatus.success,
        syncMessage: '上传成功！共上传 ${voiceRecords.length} 条录音，${autobiographies.length} 篇自传',
      ));
    } catch (e) {
      emit(state.copyWith(
        syncStatus: SyncStatus.error,
        syncMessage: '上传失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDownloadData(DownloadData event, Emitter<AuthState> emit) async {
    if (!_cloudSyncService.isLoggedIn) {
      emit(state.copyWith(
        syncStatus: SyncStatus.error,
        syncMessage: '请先登录',
      ));
      return;
    }

    emit(state.copyWith(syncStatus: SyncStatus.downloading, syncMessage: null));

    try {
      // 从云端下载数据
      final data = await _cloudSyncService.downloadData();

      // 保存语音记录到本地
      for (final record in data.voiceRecords) {
        await _voiceRecordRepository.insertVoiceRecord(record);
      }

      // 保存自传到本地
      for (final auto in data.autobiographies) {
        await _autobiographyRepository.insertAutobiography(auto);
      }

      emit(state.copyWith(
        syncStatus: SyncStatus.success,
        syncMessage: '恢复成功！共恢复 ${data.voiceRecords.length} 条录音，${data.autobiographies.length} 篇自传',
      ));
    } catch (e) {
      emit(state.copyWith(
        syncStatus: SyncStatus.error,
        syncMessage: '恢复失败: ${e.toString()}',
      ));
    }
  }
}
