import 'package:flutter/material.dart';
import 'package:toonplay/theme/theme.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:toonplay/supabase/video_service.dart';
import 'package:toonplay/supabase/favorites_service.dart';

// Individual short container widget with external video controller
class ShortVideoPlayer extends StatefulWidget {
  final Video video;
  final int index;
  final int totalVideos;
  final bool hasMore;
  final bool isCurrentVideo;
  final VideoPlayerController? videoController;
  final bool isInitialized;
  final bool hasError;
  final VoidCallback onRetryVideo;

  const ShortVideoPlayer({
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
  State<ShortVideoPlayer> createState() => _ShortVideoPlayerState();
}

class _ShortVideoPlayerState extends State<ShortVideoPlayer>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  bool _showPlayPauseButton = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;

  final FavoritesService _favoritesService = FavoritesService();
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoadingLike = true;
  bool _isTogglingLike = false;

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

    // Initialize like button animation
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Load like status and count
    _loadLikeData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadLikeData() async {
    if (_isDisposed) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoadingLike = false;
        });
        return;
      }

      // Load both like status and count in parallel
      final results = await Future.wait([
        _favoritesService.isVideoFavorited(
          userId: userId,
          videoId: widget.video.id,
        ),
        _favoritesService.getTotalLikedVideosByAllUsers(widget.video.id),
      ]);

      if (!_isDisposed && mounted) {
        setState(() {
          _isLiked = results[0] as bool;
          _likeCount = results[1] as int;
          _isLoadingLike = false;
        });
      }
    } catch (e) {
      print('Error loading like data: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoadingLike = false;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      // Show snackbar if user is not logged in
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to like videos'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isTogglingLike = true;
    });

    try {
      // Optimistically update UI
      final wasLiked = _isLiked;
      setState(() {
        _isLiked = !_isLiked;
        _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
      });

      // Play animation
      _likeAnimationController.forward().then((_) {
        if (mounted) {
          _likeAnimationController.reverse();
        }
      });

      // Toggle in database
      final newLikedStatus = await _favoritesService.toggleUserFavorite(
        userId: userId,
        videoId: widget.video.id,
      );

      // Verify the toggle worked correctly
      if (newLikedStatus != _isLiked) {
        // Something went wrong, revert
        if (mounted) {
          setState(() {
            _isLiked = wasLiked;
            _likeCount = wasLiked ? _likeCount + 1 : _likeCount - 1;
          });
        }
      }
    } catch (e) {
      print('Error toggling like: $e');
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update like. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingLike = false;
        });
      }
    }
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

  String _formatLikeCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
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

              // Like button with count (bottom right)
              Positioned(
                bottom: 40,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _likeScaleAnimation,
                      child: Container(
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textPrimary.withAlpha(120),
                        ),
                        child: IconButton(
                          onPressed: _isLoadingLike ? null : _toggleLike,
                          icon: _isLoadingLike
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _isLiked
                                      ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                                      : PhosphorIcons.heart(PhosphorIconsStyle.regular),
                                  color: _isLiked ? Colors.red : Colors.white,
                                  size: 28,
                                ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withAlpha(120),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isLoadingLike ? '...' : _formatLikeCount(_likeCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
                        color: AppColors.textPrimary.withAlpha(120),
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
