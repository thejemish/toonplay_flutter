import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:toonplay/supabase/video_service.dart';

// Import your video service - adjust the path as needed
// import 'path/to/your/video_service.dart';

class ReelsScreen extends StatefulWidget {
  @override
  _ReelsScreenState createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  static const _pageSize = 10;
  late PageController _pageController;
  final VideoService _videoService = VideoService();
  List<Video> _allVideos = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  int _currentVideoIndex = 0;

  // Video controllers management
  Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Dispose all video controllers
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });
    _videoControllers.clear();
    super.dispose();
  }

  // Load initial data
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentPage = 0;
      _allVideos.clear();
    });

    // Dispose existing controllers
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });
    _videoControllers.clear();

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

      // Initialize first video controller
      if (_allVideos.isNotEmpty) {
        _initializeVideoController(0);
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Initialize video controller for specific index
  Future<void> _initializeVideoController(int index) async {
    if (index < 0 || index >= _allVideos.length) return;

    final video = _allVideos[index];
    final videoId = video.videoId;
    final videoUrl =
        "https://ai-video-media.codepick.in/videos/$videoId/master.m3u8";

    print(
      'Initializing video controller for index $index, videoId: $videoId, url: $videoUrl',
    );

    if (_videoControllers.containsKey(index)) return;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );
      _videoControllers[index] = controller;

      await controller.initialize();

      // Set looping and start playing if it's the current video
      controller.setLooping(true);
      if (index == _currentVideoIndex) {
        controller.play();
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing video controller for index $index: $e');
      print('VideoId: $videoId, URL: $videoUrl');
      // Remove failed controller from map
      _videoControllers.remove(index);
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

  // Handle page changes
  void _onPageChanged(int index) {
    print('Page changed to index: $index, total videos: ${_allVideos.length}');

    // Pause previous video
    if (_videoControllers.containsKey(_currentVideoIndex)) {
      _videoControllers[_currentVideoIndex]?.pause();
    }

    _currentVideoIndex = index;

    // Initialize current video controller if not exists
    if (!_videoControllers.containsKey(index)) {
      _initializeVideoController(index);
    }

    // Initialize next video controller for smooth experience
    if (index + 1 < _allVideos.length &&
        !_videoControllers.containsKey(index + 1)) {
      _initializeVideoController(index + 1);
    }

    // Initialize previous video controller for smooth experience
    if (index - 1 >= 0 && !_videoControllers.containsKey(index - 1)) {
      _initializeVideoController(index - 1);
    }

    // Play current video after a small delay to ensure initialization
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_videoControllers.containsKey(index) &&
          _videoControllers[index]?.value.isInitialized == true) {
        _videoControllers[index]?.play();
      }
    });

    // Clean up controllers that are too far away (keep only 3 videos in memory)
    final controllersToRemove = <int>[];
    _videoControllers.forEach((controllerIndex, controller) {
      if ((controllerIndex - index).abs() > 2) {
        controllersToRemove.add(controllerIndex);
      }
    });

    for (final indexToRemove in controllersToRemove) {
      _videoControllers[indexToRemove]?.dispose();
      _videoControllers.remove(indexToRemove);
    }

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
            video: _allVideos[index],
            index: index,
            totalVideos: _allVideos.length,
            hasMore: _hasMore,
            videoController: _videoControllers[index],
          );
        },
      ),
    );
  }
}

// Individual reel container widget
class ReelContainer extends StatefulWidget {
  final Video video;
  final int index;
  final int totalVideos;
  final bool hasMore;
  final VideoPlayerController? videoController;

  const ReelContainer({
    Key? key,
    required this.video,
    required this.index,
    required this.totalVideos,
    required this.hasMore,
    this.videoController,
  }) : super(key: key);

  @override
  State<ReelContainer> createState() => _ReelContainerState();
}

class _ReelContainerState extends State<ReelContainer> {
  bool _showControls = false;

  @override
  Widget build(BuildContext context) {
    // Create different shades of red based on video ID hash
    final colorSeed = widget.video.videoId.hashCode.abs();
    final redShade = 150 + (colorSeed % 105); // Creates shades from 150 to 255

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });

        // Hide controls after 3 seconds
        if (_showControls) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showControls = false;
              });
            }
          });
        }
      },
      onDoubleTap: () {
        // Handle double tap to play/pause
        if (widget.videoController != null &&
            widget.videoController!.value.isInitialized) {
          if (widget.videoController!.value.isPlaying) {
            widget.videoController!.pause();
          } else {
            widget.videoController!.play();
          }
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.black,
        child: Stack(
          children: [
            // Place video here
            if (widget.videoController != null &&
                widget.videoController!.value.isInitialized)
              Positioned.fill(
                child: AspectRatio(
                  aspectRatio: widget.videoController!.value.aspectRatio,
                  child: VideoPlayer(widget.videoController!),
                ),
              )
            else
              // Loading state with colored background
              Container(
                color: Color.fromARGB(255, redShade, 0, 0),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Loading video...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

            // Video progress indicator (always visible at bottom)
            if (widget.videoController != null &&
                widget.videoController!.value.isInitialized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  widget.videoController!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white30,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
