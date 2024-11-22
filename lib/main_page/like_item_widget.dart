// like_item_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum StatisticsMenu { amis, personnel }

class ActivityFeedPage extends StatefulWidget {
  const ActivityFeedPage({super.key});

  @override
  ActivityFeedPageState createState() => ActivityFeedPageState();
}

class ActivityFeedPageState extends State<ActivityFeedPage> {
  StatisticsMenu _selectedMenu = StatisticsMenu.amis;

  // Exemple de données pour les activités des amis
  final List<Map<String, dynamic>> friendsActivities = [
    {
      'profileImage': 'https://example.com/friend1.jpg',
      'description': 'Votre ami a terminé un entraînement',
      'isLiked': false,
      'onLike': () {},
    },
    // Ajoutez d'autres activités
  ];

  // Exemple de données pour vos propres activités
  final List<Map<String, dynamic>> personalActivities = [
    {
      'profileImage': 'https://example.com/your_profile.jpg',
      'description': 'Vous avez terminé un entraînement',
      'likesCount': 10,
      'isLiked': false,
      'onLike': () {},
    },
    // Ajoutez d'autres activités
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activités'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          CupertinoSegmentedControl<StatisticsMenu>(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            groupValue: _selectedMenu,
            children: const {
              StatisticsMenu.amis: Text('Activités de vos amis'),
              StatisticsMenu.personnel: Text('Vos activités'),
            },
            onValueChanged: (StatisticsMenu value) {
              setState(() {
                _selectedMenu = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedMenu == StatisticsMenu.amis
                ? ListView.builder(
                    itemCount: friendsActivities.length,
                    itemBuilder: (context, index) {
                      final activity = friendsActivities[index];
                      return LikeItem(
                        profileImage: activity['profileImage'],
                        description: activity['description'],
                        isLiked: activity['isLiked'],
                        onLike: activity['onLike'],
                      );
                    },
                  )
                : ListView.builder(
                    itemCount: personalActivities.length,
                    itemBuilder: (context, index) {
                      final activity = personalActivities[index];
                      return PersonalActivityItem(
                        profileImage: activity['profileImage'],
                        description: activity['description'],
                        likesCount: activity['likesCount'],
                        isLiked: activity['isLiked'],
                        onLike: activity['onLike'],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Widget pour les activités personnelles avec le nombre de likes
class PersonalActivityItem extends StatefulWidget {
  final String profileImage;
  final String description;
  final int likesCount;
  final VoidCallback onLike;
  final bool isLiked;

  const PersonalActivityItem({
    super.key,
    required this.profileImage,
    required this.description,
    required this.likesCount,
    required this.onLike,
    required this.isLiked,
  });

  @override
  PersonalActivityItemState createState() => PersonalActivityItemState();
}

class PersonalActivityItemState extends State<PersonalActivityItem>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likesCount;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likesCount = widget.likesCount;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (_isLiked) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant PersonalActivityItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      setState(() {
        _isLiked = widget.isLiked;
        if (_isLiked) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLike() {
    setState(() {
      if (!_isLiked) {
        _isLiked = true;
        _likesCount++;
        _controller.forward();
        widget.onLike();
      } else {
        _isLiked = false;
        _likesCount--;
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(widget.profileImage),
      ),
      title: Text(widget.description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _handleLike,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.grey,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$_likesCount'),
        ],
      ),
    );
  }
}

// Widget existant pour les activités des amis
class LikeItem extends StatefulWidget {
  final String profileImage;
  final String description;
  final VoidCallback onLike;
  final bool isLiked;

  const LikeItem({
    super.key,
    required this.profileImage,
    required this.description,
    required this.onLike,
    required this.isLiked,
  });

  @override
  LikeItemState createState() => LikeItemState();
}

class LikeItemState extends State<LikeItem>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (_isLiked) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant LikeItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      setState(() {
        _isLiked = widget.isLiked;
        if (_isLiked) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLike() {
    if (!_isLiked) {
      widget.onLike();
      setState(() {
        _isLiked = true;
        _controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(widget.profileImage),
      ),
      title: Text(widget.description),
      trailing: GestureDetector(
        onTap: _handleLike,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.grey,
            size: 24, // Taille réduite de l'icône
          ),
        ),
      ),
    );
  }
}
