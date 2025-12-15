import 'dart:io';
import 'dart:typed_data';

/// 用于写入和更新 WAV 文件头的工具类
class WavHeaderWriter {
  /// 写入初始 WAV 头
  /// [file] 目标文件
  /// [sampleRate] 采样率
  /// [channels] 通道数
  /// [bitsPerSample] 位深
  static Future<void> writeHeader(
    File file, {
    int sampleRate = 16000,
    int channels = 1,
    int bitsPerSample = 16,
  }) async {
    final header = _buildHeader(0, sampleRate, channels, bitsPerSample);
    await file.writeAsBytes(header, mode: FileMode.write);
  }

  /// 更新 WAV 头中的文件大小信息
  /// [file] 目标文件
  /// [sampleRate] 采样率
  /// [channels] 通道数
  /// [bitsPerSample] 位深
  static Future<void> updateHeader(
    File file, {
    int sampleRate = 16000,
    int channels = 1,
    int bitsPerSample = 16,
  }) async {
    final length = await file.length();
    final dataLength = length - 44; // 减去头部长度
    
    // 重新构建头部，填入实际数据长度
    final header = _buildHeader(dataLength.toInt(), sampleRate, channels, bitsPerSample);
    
    // 使用 RandomAccessFile 更新头部
    final raf = await file.open(mode: FileMode.writeOnly);
    await raf.setPosition(0);
    await raf.writeFrom(header);
    await raf.close();
  }

  /// 构建 WAV 头字节数组
  static Uint8List _buildHeader(
    int dataLength,
    int sampleRate,
    int channels,
    int bitsPerSample,
  ) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final totalDataLen = dataLength + 36;

    final header = Uint8List(44);
    final view = ByteData.view(header.buffer);

    // RIFF chunk
    _writeString(view, 0, 'RIFF');
    view.setUint32(4, totalDataLen, Endian.little);
    _writeString(view, 8, 'WAVE');

    // fmt chunk
    _writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, Endian.little); // Subchunk1Size
    view.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    view.setUint16(22, channels, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, blockAlign, Endian.little);
    view.setUint16(34, bitsPerSample, Endian.little);

    // data chunk
    _writeString(view, 36, 'data');
    view.setUint32(40, dataLength, Endian.little);

    return header;
  }

  static void _writeString(ByteData view, int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      view.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}
