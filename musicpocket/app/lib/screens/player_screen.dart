import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/player/player_bloc.dart';
import '../bloc/player/player_event.dart';
import '../bloc/player/player_state.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          final track = state.currentTrack;
          if (track == null) {
            return const Center(child: Text('没有正在播放的音频'));
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // 封面/波形可视化
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 模拟概念图中的波形 logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _bar(12, Colors.black),
                          const SizedBox(width: 4),
                          _bar(28, Colors.black),
                          const SizedBox(width: 4),
                          _bar(40, Colors.black),
                          const SizedBox(width: 4),
                          _bar(8, Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 标题和作者
                Text(
                  track.displayTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${track.durationText}  ${track.audioFormat?.toUpperCase() ?? "MP3"}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  track.displayAuthor,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                const Spacer(),
                // 进度条
                _buildProgressBar(context, state),
                const SizedBox(height: 24),
                // 播放控制
                _buildControls(context, state),
                const SizedBox(height: 24),
                // 底部操作
                _buildBottomActions(context),
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bar(double height, Color color) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, PlayerState state) {
    final pos = state.position;
    final dur = state.duration;
    final total = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: Colors.red,
            inactiveTrackColor: Colors.grey[200],
            thumbColor: Colors.red,
            overlayColor: Colors.red.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: pos.inMilliseconds.toDouble().clamp(0, total),
            max: total,
            onChanged: (v) {
              context.read<PlayerBloc>().add(SeekTo(Duration(milliseconds: v.toInt())));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(pos), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              Text(_formatDuration(dur), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, PlayerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 36),
          onPressed: () => context.read<PlayerBloc>().add(PreviousTrack()),
        ),
        const SizedBox(width: 24),
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          child: IconButton(
            icon: Icon(
              state.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () => context.read<PlayerBloc>().add(TogglePlayPause()),
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 36),
          onPressed: () => context.read<PlayerBloc>().add(NextTrack()),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.favorite_border, color: Colors.grey[600]),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.download_outlined, color: Colors.grey[600]),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.playlist_add, color: Colors.grey[600]),
          onPressed: () {},
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
