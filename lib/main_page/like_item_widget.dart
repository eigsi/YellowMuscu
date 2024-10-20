// like_item_widget.dart

import 'package:flutter/material.dart';

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
  _LikeItemState createState() => _LikeItemState();
}

class _LikeItemState extends State<LikeItem>
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
