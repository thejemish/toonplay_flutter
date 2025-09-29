import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:toonplay/supabase/video_service.dart';

// Individual short container widget with external video controller
class ShortContainer extends StatefulWidget {
  final Video video;
  final int index;
  final int totalVideos;
  final bool hasMore;
  final bool isCurrentVideo;
  final VideoPlayerController? videoController;
  final bool isInitialized;
  final bool hasError;
  final VoidCallback onRetryVideo;

  const ShortContainer({
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
  State<ShortContainer> createState() => _ShortContainerState();
}

class _ShortContainerState extends State<ShortContainer>
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

    // Create different shades based on video ID hash for variety
    final colorSeed = widget.video.videoId.hashCode.abs();
    final hue = (colorSeed % 360).toDouble();
    final baseColor = HSVColor.fromAHSV(1.0, hue, 0.3, 0.2).toColor();

    final _videoPlayerController = widget.videoController;

    return VisibilityDetector(
      key: Key('ShortsVideoPlayer_${widget.video.videoId}'),
      onVisibilityChanged: (visibilityInfo) {
        if (_videoPlayerController != null) {
          if (visibilityInfo.visibleFraction == 0) {
            // Video is completely off-screen, pause it
            if (!_isDisposed) {
              _videoPlayerController.pause();
            }
          } else if (visibilityInfo.visibleFraction > 0.5 &&
              !_videoPlayerController.value.isPlaying &&
              widget.isCurrentVideo) {
            // Video is more than 50% visible and is the current video, play it
            if (!_isDisposed) {
              _videoPlayerController.play();
            }
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
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: widget.videoController!.value.aspectRatio,
                      child: VideoPlayer(widget.videoController!),
                    ),
                  ),
                )
              else
                Container(
                  color: widget.hasError ? Colors.red.shade900 : baseColor,
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
                          const SizedBox(height: 8),
                          Text(
                            widget.video.title,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
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
                          const SizedBox(height: 8),
                          Text(
                            widget.video.title,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Video info overlay
              if (widget.isInitialized && !widget.hasError)
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.video.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.video.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
