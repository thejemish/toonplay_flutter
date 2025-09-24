import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:toonplay/supabase/video_service.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() {
    return _ReelsScreenState();
  }
}

class _ReelsScreenState extends State<ReelsScreen> {
  static const _pageSize = 10;
  static const _cacheRange = 2; // Cache 2 videos ahead and 1 behind

  late PageController _pageController;
  final VideoService _videoService = VideoService();
  List<Video> _allVideos = [];
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _videoInitialized = {};
  final Map<int, bool> _videoHasError = {};

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  int _currentVideoIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadInitialData();
  }

  @override
  void dispose() {
    // Dispose all video controllers
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _pageController.dispose();
    super.dispose();
  }

  // Load initial data
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentPage = 0;
      _allVideos.clear();
      // Clear existing controllers
      for (var controller in _videoControllers.values) {
        controller.dispose();
      }
      _videoControllers.clear();
      _videoInitialized.clear();
      _videoHasError.clear();
    });

    try {
      final result = await _videoService.getRandomVideos(
        page: 0,
        limit: _pageSize,
      );

      setState(() {
        _allVideos = result.data;
        _hasMore = result.hasMore;
        _isLoading = false;
      });

      // Start preloading videos
      _preloadVideos();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Load more data when approaching the end
  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await _videoService.getRandomVideos(
        page: nextPage,
        limit: _pageSize,
      );

      setState(() {
        _allVideos.addAll(result.data);
        _currentPage = nextPage;
        _hasMore = result.hasMore;
        _isLoading = false;
      });

      // Preload new videos
      _preloadVideos();

      print(
        'Loaded page $nextPage, total videos: ${_allVideos.length}, hasMore: $_hasMore',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      print('Error loading more data: $e');
    }
  }

  // Preload videos within cache range
  void _preloadVideos() {
    final startIndex = (_currentVideoIndex - 1).clamp(0, _allVideos.length - 1);
    final endIndex = (_currentVideoIndex + _cacheRange).clamp(
      0,
      _allVideos.length - 1,
    );

    for (int i = startIndex; i <= endIndex; i++) {
      if (!_videoControllers.containsKey(i) && i < _allVideos.length) {
        _initializeVideoAt(i);
      }
    }

    // Cleanup videos that are out of range to free memory
    _cleanupDistantVideos();
  }

  // Initialize video controller for specific index
  Future<void> _initializeVideoAt(int index) async {
    if (index >= _allVideos.length) return;

    final videoUrl =
        "https://ai-video-media.codepick.in/videos/${_allVideos[index].videoId}/master.m3u8";

    print(
      'Preloading video at index $index, videoId: ${_allVideos[index].videoId}',
    );

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      _videoControllers[index] = controller;
      _videoInitialized[index] = false;
      _videoHasError[index] = false;

      await controller.initialize();

      if (mounted) {
        setState(() {
          _videoInitialized[index] = true;
        });

        controller.setLooping(true);

        // If this is the current video, play it
        if (index == _currentVideoIndex) {
          controller.play();
        } else {
          // Preload by seeking to start but don't play
          controller.seekTo(Duration.zero);
        }
      }
    } catch (e) {
      print('Error initializing video at index $index: $e');
      if (mounted) {
        setState(() {
          _videoHasError[index] = true;
        });
      }
    }
  }

  // Cleanup videos that are far from current position
  void _cleanupDistantVideos() {
    final keepRange = _cacheRange + 2; // Keep a bit more range for safety
    final indicesToRemove = <int>[];

    for (int index in _videoControllers.keys) {
      if ((index < _currentVideoIndex - keepRange) ||
          (index > _currentVideoIndex + keepRange)) {
        indicesToRemove.add(index);
      }
    }

    for (int index in indicesToRemove) {
      print('Cleaning up video controller at index $index');
      _videoControllers[index]?.dispose();
      _videoControllers.remove(index);
      _videoInitialized.remove(index);
      _videoHasError.remove(index);
    }
  }

  // Handle page changes - auto play current video and pause others
  void _onPageChanged(int index) {
    print('Page changed to index: $index, total videos: ${_allVideos.length}');

    // Pause previous video
    if (_videoControllers.containsKey(_currentVideoIndex)) {
      _videoControllers[_currentVideoIndex]?.pause();
    }

    setState(() {
      _currentVideoIndex = index;
    });

    // Play current video if it's ready
    if (_videoControllers.containsKey(index) &&
        _videoInitialized[index] == true &&
        _videoHasError[index] != true) {
      _videoControllers[index]?.play();
    }

    // Preload nearby videos
    _preloadVideos();

    // Load more data when user is near the end (3 items before the end)
    if (index >= _allVideos.length - 3 && !_isLoading && _hasMore) {
      print('Loading more data...');
      _loadMoreData();
    }
  }

  // Pull to refresh functionality
  Future<void> _onRefresh() async {
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    // Show loading indicator for initial load
    if (_isLoading && _allVideos.isEmpty) {
      return Container(
        color: Colors.red,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Show error indicator for initial load
    if (_hasError && _allVideos.isEmpty) {
      return Container(
        color: Colors.red,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Failed to load reels',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show no items indicator
    if (_allVideos.isEmpty) {
      return Container(
        color: Colors.red,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No reels found',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    // Show PageView with reels and pull to refresh
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: _allVideos.length + (_isLoading && _hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the end while loading more
          if (index >= _allVideos.length) {
            return Container(
              color: Colors.red.shade700,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Loading more reels...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          return ReelContainer(
            key: ValueKey(_allVideos[index].videoId),
            video: _allVideos[index],
            index: index,
            totalVideos: _allVideos.length,
            hasMore: _hasMore,
            isCurrentVideo: index == _currentVideoIndex,
            videoController: _videoControllers[index],
            isInitialized: _videoInitialized[index] ?? false,
            hasError: _videoHasError[index] ?? false,
            onRetryVideo: () => _initializeVideoAt(index),
          );
        },
      ),
    );
  }
}

// Individual reel container widget with external video controller
class ReelContainer extends StatefulWidget {
  final Video video;
  final int index;
  final int totalVideos;
  final bool hasMore;
  final bool isCurrentVideo;
  final VideoPlayerController? videoController;
  final bool isInitialized;
  final bool hasError;
  final VoidCallback onRetryVideo;

  const ReelContainer({
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
  State<ReelContainer> createState() => _ReelContainerState();
}

class _ReelContainerState extends State<ReelContainer>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  bool _showPlayPauseButton = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

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
          _videoPlayerController!.pause();
        } else if (visibilityInfo.visibleFraction > 0 && !_videoPlayerController!.value.isPlaying) {
          // Video is visible and not playing, you might want to resume it
          // Or, you can choose to only pause and not automatically play
          _videoPlayerController.play();
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
