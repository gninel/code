import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/library/library_bloc.dart';
import '../bloc/library/library_event.dart';
import '../bloc/library/library_state.dart';
import '../bloc/player/player_bloc.dart';
import '../bloc/player/player_event.dart';
import '../models/audio_task.dart';
import 'player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LibraryBloc>().add(LoadLibrary());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('音频库', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
        ],
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state is LibraryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LibraryLoaded) {
            if (state.audios.isEmpty) {
              return _buildEmptyState();
            }
            return _buildList(state.audios);
          }
          if (state is LibraryError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('还没有音频', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 8),
          Text('转换视频链接后，音频会自动保存到这里',
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildList(List<AudioTask> audios) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: audios.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final audio = audios[index];
        return _buildAudioTile(audio, index, audios);
      },
    );
  }

  Widget _buildAudioTile(AudioTask audio, int index, List<AudioTask> allAudios) {
    return Dismissible(
      key: Key(audio.taskId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<LibraryBloc>().add(DeleteAudio(audio.taskId));
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_note, color: Colors.black54),
        ),
        title: Text(
          audio.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          '${audio.displayAuthor}  ${audio.durationText}  ${audio.audioFormat?.toUpperCase() ?? "MP3"}',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite_border, size: 20),
              onPressed: () {
                context.read<LibraryBloc>().add(ToggleFavorite(audio.taskId));
              },
            ),
            _buildPlatformBadge(audio.platform),
          ],
        ),
        onTap: () {
          final playerBloc = context.read<PlayerBloc>();
          playerBloc.add(SetPlaylist(tasks: allAudios, startIndex: index));
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PlayerScreen()));
        },
      ),
    );
  }

  Widget _buildPlatformBadge(String platform) {
    final labels = {
      'douyin': '抖音',
      'tiktok': 'TT',
      'bilibili': 'B站',
      'xiaohongshu': '小红书',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        labels[platform] ?? platform,
        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: _AudioSearchDelegate(context.read<LibraryBloc>()),
    );
  }
}

class _AudioSearchDelegate extends SearchDelegate<String> {
  final LibraryBloc libraryBloc;
  _AudioSearchDelegate(this.libraryBloc);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));
  }

  @override
  Widget buildResults(BuildContext context) {
    libraryBloc.add(SearchLibrary(query));
    return BlocBuilder<LibraryBloc, LibraryState>(
      bloc: libraryBloc,
      builder: (context, state) {
        if (state is LibraryLoaded) {
          return ListView.builder(
            itemCount: state.audios.length,
            itemBuilder: (context, i) {
              final audio = state.audios[i];
              return ListTile(
                title: Text(audio.displayTitle),
                subtitle: Text(audio.displayAuthor),
                onTap: () => close(context, audio.taskId),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
