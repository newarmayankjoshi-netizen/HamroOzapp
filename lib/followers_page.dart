import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/follow_service.dart';
import 'auth_page.dart';
import 'profile_page.dart';

/// Page to display followers and following lists.
class FollowersPage extends StatefulWidget {
  final String userId;
  final String userName;
  final bool showFollowers; // true = show followers, false = show following

  const FollowersPage({
    super.key,
    required this.userId,
    required this.userName,
    this.showFollowers = true,
  });

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? _currentUserId = AuthState.currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.showFollowers ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Followers tab
          _UserListView(
            stream: FollowService.streamFollowers(widget.userId),
            userIdField: 'followerId',
            emptyMessage: 'No followers yet',
            currentUserId: _currentUserId,
          ),
          // Following tab
          _UserListView(
            stream: FollowService.streamFollowing(widget.userId),
            userIdField: 'followedId',
            emptyMessage: 'Not following anyone yet',
            currentUserId: _currentUserId,
          ),
        ],
      ),
    );
  }
}

class _UserListView extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String userIdField;
  final String emptyMessage;
  final String? currentUserId;

  const _UserListView({
    required this.stream,
    required this.userIdField,
    required this.emptyMessage,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('FollowersPage error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Could not load data',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Force rebuild by navigating back and forth
                    Navigator.pop(context);
                  },
                  child: const Text('Go back'),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final userId = data[userIdField] as String?;

            if (userId == null) return const SizedBox.shrink();

            return _UserListTile(
              userId: userId,
              currentUserId: currentUserId,
            );
          },
        );
      },
    );
  }
}

class _UserListTile extends StatefulWidget {
  final String userId;
  final String? currentUserId;

  const _UserListTile({
    required this.userId,
    this.currentUserId,
  });

  @override
  State<_UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<_UserListTile> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        setState(() {
          _userData = doc.data();
          _isLoading = false;
        });

        // Check if current user is following this user
        if (widget.currentUserId != null &&
            widget.currentUserId != widget.userId) {
          final isFollowing = await FollowService.isFollowing(
            widget.currentUserId!,
            widget.userId,
          );
          if (mounted) {
            setState(() => _isFollowing = isFollowing);
          }
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.currentUserId == null || _isToggling) return;

    setState(() => _isToggling = true);

    final success = await FollowService.toggleFollow(
      widget.currentUserId!,
      widget.userId,
    );

    if (mounted && success) {
      setState(() {
        _isFollowing = !_isFollowing;
        _isToggling = false;
      });
    } else if (mounted) {
      setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        title: SizedBox(
          height: 16,
          child: LinearProgressIndicator(),
        ),
      );
    }

    if (_userData == null) {
      return const SizedBox.shrink();
    }

    final name = _userData!['name'] as String? ?? 'Unknown';
    final profilePicture = _userData!['profilePicture'] as String?;
    final location = _userData!['location'] as String? ??
        _userData!['state'] as String? ??
        '';
    final badges = List<String>.from(_userData!['badges'] ?? []);
    final isVerified =
        badges.contains('verified') || badges.contains('trusted');

    final isSelf = widget.currentUserId == widget.userId;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
                profilePicture != null ? NetworkImage(profilePicture) : null,
            child: profilePicture == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (isVerified)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified,
                  size: 14,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      subtitle: location.isNotEmpty
          ? Text(
              location,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            )
          : null,
      trailing: isSelf
          ? null
          : widget.currentUserId != null
              ? SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: _isToggling ? null : _toggleFollow,
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          _isFollowing ? Colors.transparent : Colors.blue,
                      foregroundColor:
                          _isFollowing ? Colors.grey.shade700 : Colors.white,
                      side: BorderSide(
                        color: _isFollowing
                            ? Colors.grey.shade400
                            : Colors.blue,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: _isToggling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(fontSize: 13),
                          ),
                  ),
                )
              : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(profileUserId: widget.userId),
          ),
        );
      },
    );
  }
}
