import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:toonplay/supabase/video_service.dart';

class ShortsScreen extends StatefulWidget {
  final String categorySlug;
  final String categoryName;
  final String? initialVideoId;

  const ShortsScreen({
    super.key,
    required this.categorySlug,
    required this.categoryName,
    this.initialVideoId,
  });

  @override
  State<ShortsScreen> createState() {
    return _ShortsScreenState();
  }
}

class _ShortsScreenState extends State<ShortsScreen> {
  static const _pageSize = 10;
  static const _cacheRange = 2; // Cache 2 videos ahead and 1 behind

  late PageController _pageController;
  final VideoService _videoService = VideoService();
  List<Video> _categoryVideos = [];
  Video? _initialVideo; // Store the fetched initial video
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

  // Load initial data for the specific category
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentPage = 0;
      _categoryVideos.clear();
      _initialVideo = null;
      // Clear existing controllers
      for (var controller in _videoControllers.values) {
        controller.dispose();
      }
      _videoControllers.clear();
      _videoInitialized.clear();
      _videoHasError.clear();
    });

    try {
      // First, fetch the initial video if provided
      if (widget.initialVideoId != null) {
        try {
          _initialVideo = await _videoService.getVideoById(
            widget.initialVideoId!,
          );
          print('Initial video fetched: ${_initialVideo?.title}');
        } catch (e) {
          print('Error fetching initial video: $e');
          // Continue without initial video if it fails
        }
      }

      // Then fetch category videos
      final result = await _videoService.getVideosByCategory(
        categorySlug: widget.categorySlug,
        page: 0,
        limit: _pageSize,
      );

      List<Video> videos = result.data;

      // If we have an initial video, prioritize it at the beginning
      if (_initialVideo != null) {
        // Remove the initial video from its current position if it exists in category
        videos = videos.where((v) => v.id != _initialVideo!.id).toList();
        // Insert it at the beginning
        videos.insert(0, _initialVideo!);
      }

      setState(() {
        _categoryVideos = videos;
        _hasMore = result.hasMore;
        _isLoading = false;
        _currentVideoIndex =
            0; // Start with the first video (initial video if provided)
      });

      // Start preloading videos
      _preloadVideos();

      // Jump to the first video immediately after loading
      if (_categoryVideos.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
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
      final result = await _videoService.getVideosByCategory(
        categorySlug: widget.categorySlug,
        page: nextPage,
        limit: _pageSize,
      );

      setState(() {
        _categoryVideos.addAll(result.data);
        _currentPage = nextPage;
        _hasMore = result.hasMore;
        _isLoading = false;
      });

      // Preload new videos
      _preloadVideos();

      print(
        'Loaded page $nextPage, total videos: ${_categoryVideos.length}, hasMore: $_hasMore',
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
    final startIndex = (_currentVideoIndex - 1).clamp(
      0,
      _categoryVideos.length - 1,
    );
    final endIndex = (_currentVideoIndex + _cacheRange).clamp(
      0,
      _categoryVideos.length - 1,
    );

    for (int i = startIndex; i <= endIndex; i++) {
      if (!_videoControllers.containsKey(i) && i < _categoryVideos.length) {
        _initializeVideoAt(i);
      }
    }

    // Cleanup videos that are out of range to free memory
    _cleanupDistantVideos();
  }

  // Initialize video controller for specific index
  Future<void> _initializeVideoAt(int index) async {
    if (index >= _categoryVideos.length) return;

    final videoUrl =
        "https://ai-video-media.codepick.in/videos/${_categoryVideos[index].videoId}/master.m3u8";

    print(
      'Preloading video at index $index, videoId: ${_categoryVideos[index].videoId}',
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
    print(
      'Page changed to index: $index, total videos: ${_categoryVideos.length}',
    );

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
    if (index >= _categoryVideos.length - 3 && !_isLoading && _hasMore) {
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              widget.categoryName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_initialVideo != null &&
                _categoryVideos.isNotEmpty &&
                _currentVideoIndex == 0)
              const Text(
                'Started from selected video',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_categoryVideos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentVideoIndex + 1}/${_categoryVideos.length}${_hasMore ? '+' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    // Show loading indicator for initial load
    if (_isLoading && _categoryVideos.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading category videos...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Show error indicator for initial load
    if (_hasError && _categoryVideos.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load ${widget.categoryName} videos',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
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
    if (_categoryVideos.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.video_library_outlined,
                color: Colors.white70,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'No videos found in ${widget.categoryName}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
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

    // Show PageView with category videos and pull to refresh
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: _categoryVideos.length + (_isLoading && _hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the end while loading more
          if (index >= _categoryVideos.length) {
            return Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Loading more videos...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          return ShortContainer(
            key: ValueKey(_categoryVideos[index].videoId),
            video: _categoryVideos[index],
            index: index,
            totalVideos: _categoryVideos.length,
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
