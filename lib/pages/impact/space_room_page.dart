import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:thittam1hub/models/space.dart';
import 'package:thittam1hub/supabase/space_service.dart';

// TODO: Replace with your Agora App ID
const String _agoraAppId = '39225255a2c349c693a479421b8a5142';
const String _agoraToken = '007eJxTYPCbL3m2zJb/WaTLLf937r1t8f8v4X+Z4V7V5L/v/9f3/a4KDGnJKSZppoZGSUZpZiaGhqZJJqmpSUbJJmkmRiYWRhamBgavpDQEMjKc/uVlYIRgZAMEg/CsDEwNzA0MjYyMAAATax9m';

class SpaceRoomPage extends StatefulWidget {
  final Space space;

  const SpaceRoomPage({Key? key, required this.space}) : super(key: key);

  @override
  State<SpaceRoomPage> createState() => _SpaceRoomPageState();
}

class _SpaceRoomPageState extends State<SpaceRoomPage> {
  final SpaceService _spaceService = SpaceService();
  late final RtcEngine _engine;
  bool _isSpeaker = true; // For now, everyone is a speaker
  bool _isMuted = false;

  late final Stream<List<SpaceSpeaker>> _speakersStream;
  late final Stream<List<SpaceAudience>> _audienceStream;

  @override
  void initState() {
    super.initState();
    _speakersStream = _spaceService.getSpeakersStream(widget.space.id);
    _audienceStream = _spaceService.getAudienceStream(widget.space.id);
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: _agoraAppId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          print('Successfully joined channel: ${connection.channelId}');
          _spaceService.joinSpace(widget.space.id, asSpeaker: _isSpeaker);
        },
        onUserJoined: (connection, remoteUid, elapsed) {},
        onUserOffline: (connection, remoteUid, reason) {},
      ),
    );

    await _engine.joinChannel(
      token: _agoraToken,
      channelId: widget.space.id,
      uid: 0, // 0 means Agora will assign a UID
      options: ChannelMediaOptions(
        clientRoleType: _isSpeaker ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
  }

  @override
  void dispose() {
    _leaveSpace();
    super.dispose();
  }

  Future<void> _leaveSpace() async {
    await _engine.leaveChannel();
    await _engine.release();
    await _spaceService.leaveSpace(widget.space.id);
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _engine.muteLocalAudioStream(_isMuted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.space.topic),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _leaveSpace,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Speakers', style: Theme.of(context).textTheme.titleLarge),
          ),
          _buildSpeakersGrid(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Audience', style: Theme.of(context).textTheme.titleLarge),
          ),
          _buildAudienceGrid(),
          const Spacer(),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildSpeakersGrid() {
    return StreamBuilder<List<SpaceSpeaker>>(
      stream: _speakersStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final speakers = snapshot.data!;
        return GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
          itemCount: speakers.length,
          itemBuilder: (context, index) {
            final speaker = speakers[index];
            return Column(
              children: [
                const CircleAvatar(radius: 30), // Placeholder for user avatar
                const SizedBox(height: 8),
                Text(speaker.userId, overflow: TextOverflow.ellipsis), // Placeholder for user name
                if (speaker.isMuted) const Icon(Icons.mic_off, size: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAudienceGrid() {
    return StreamBuilder<List<SpaceAudience>>(
      stream: _audienceStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final audience = snapshot.data!;
        return GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
          itemCount: audience.length,
          itemBuilder: (context, index) {
            final member = audience[index];
            return const CircleAvatar(radius: 25); // Placeholder
          },
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _leaveSpace,
            icon: const Icon(Icons.call_end),
            label: const Text('Leave Quietly'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
          if (_isSpeaker)
            IconButton(
              icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
              onPressed: _toggleMute,
              iconSize: 32,
            ),
        ],
      ),
    );
  }
}
