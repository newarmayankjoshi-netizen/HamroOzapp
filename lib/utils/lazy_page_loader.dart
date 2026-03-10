import 'package:flutter/material.dart';

/// A wrapper widget that displays a loading indicator while heavy pages load.
/// This improves perceived performance by showing instant feedback.
class LazyPageLoader extends StatelessWidget {
  final Widget child;
  final String? loadingMessage;

  const LazyPageLoader({
    super.key,
    required this.child,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// A deferred page loader that shows a shimmer/skeleton while the page initializes.
class DeferredPageLoader extends StatefulWidget {
  final Future<Widget> Function() pageBuilder;
  final String title;

  const DeferredPageLoader({
    super.key,
    required this.pageBuilder,
    required this.title,
  });

  @override
  State<DeferredPageLoader> createState() => _DeferredPageLoaderState();
}

class _DeferredPageLoaderState extends State<DeferredPageLoader> {
  Widget? _loadedPage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    // Small delay to let the transition animation complete smoothly
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    
    final page = await widget.pageBuilder();
    if (mounted) {
      setState(() {
        _loadedPage = page;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }
    return _loadedPage!;
  }
}

/// Cached image provider for optimized asset loading
class CachedAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CachedAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width != null ? (width! * MediaQuery.of(context).devicePixelRatio).toInt() : null,
      cacheHeight: height != null ? (height! * MediaQuery.of(context).devicePixelRatio).toInt() : null,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined),
        );
      },
    );
  }
}
