import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:toonplay/supabase/video_service.dart';

// Individual reel container widget with external video controller
class CustomVideoPlayer extends StatefulWidget {
  final Video video;
  final int index;
  final int totalVideos;
  final bool hasMore;
  final bool isCurrentVideo;
  final VideoPlayerController? videoController;
  final bool isInitialized;
  final bool hasError;
  final VoidCallback onRetryVideo;

  const CustomVideoPlayer({
    super.key,
    required this.video,
    required this.index,
    required this.totalVideos,
    required this.hasMore,
    required this.isCurrentVideo,
    required this.videoController,
    required this.isInitialized,
    required this.hasError,
    required this.onRetryVideo,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  bool _showPlayPauseButton = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  bool get wantKeepAlive => true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    // Initialize animation controller for fade effect
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (widget.videoController != null && widget.isInitialized) {
      if (widget.videoController!.value.isPlaying) {
        widget.videoController!.pause();
      } else {
        widget.videoController!.play();
      }
    }
  }

  void _showPlayPauseButtonTemporarily() {
    setState(() {
      _showPlayPauseButton = true;
    });

    _animationController.forward();

    // Hide button after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showPlayPauseButton = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Create different shades of red based on video ID hash
    final colorSeed = widget.video.videoId.hashCode.abs();
    final redShade = 150 + (colorSeed % 105);
    final _videoPlayerController = widget.videoController;

    return VisibilityDetector(
      key: Key('ReelsVideoPlayer'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction == 0) {
          // Video is completely off-screen, pause it
          if (!_isDisposed) {
            _videoPlayerController!.pause();
          }
        } else if (visibilityInfo.visibleFraction > 0 &&
            !_videoPlayerController!.value.isPlaying) {
          // Video is visible and not playing, you might want to resume it
          // Or, you can choose to only pause and not automatically play
          if (!_isDisposed) {
            _videoPlayerController.play();
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          _togglePlayPause();
          _showPlayPauseButtonTemporarily();
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.black,
          child: Stack(
            children: [
              // Video player or loading/error state
              if (widget.isInitialized &&
                  !widget.hasError &&
                  widget.videoController != null)
                Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: widget.videoController!.value.aspectRatio,
                    child: VideoPlayer(widget.videoController!),
                  ),
                )
              else
                Container(
                  color: widget.hasError
                      ? Colors.red.shade800
                      : Color.fromARGB(255, redShade, 0, 0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.hasError) ...[
                          const Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load video',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: widget.onRetryVideo,
                            child: const Text('Retry'),
                          ),
                        ] else ...[
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            widget.isCurrentVideo
                                ? 'Loading video...'
                                : 'Preparing video...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Video progress indicator
              if (widget.isInitialized &&
                  !widget.hasError &&
                  widget.videoController != null)
                Positioned(
                  bottom: 0,
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 25,
                    alignment: Alignment.center,
                    child: VideoProgressIndicator(
                      widget.videoController!,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),
                ),

              // YouTube-style play/pause button overlay
              if (_showPlayPauseButton &&
                  widget.isInitialized &&
                  !widget.hasError &&
                  widget.videoController != null)
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.videoController!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
