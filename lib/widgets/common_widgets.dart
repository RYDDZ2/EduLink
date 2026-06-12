import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme.dart';

class AvatarWidget extends StatelessWidget {
  final String initials;
  final String bgColorHex;
  final double size;
  final String? imageUrl;

  const AvatarWidget({
    super.key,
    required this.initials,
    required this.bgColorHex,
    this.size = 40,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = imageUrl != null && imageUrl!.isNotEmpty;

    if (hasPhoto) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppTheme.hexToColor(bgColorHex),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.avatarTextColor(bgColorHex),
                  ),
                ),
              ),
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppTheme.hexToColor(bgColorHex),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.hexToColor(bgColorHex),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w600,
            color: AppTheme.avatarTextColor(bgColorHex),
          ),
        ),
      ),
    );
  }
}

/// Avatar that resolves a user's real profile photo from Firestore by
/// [userId], falling back to the [initials]/[bgColorHex] placeholder while
/// loading or when the account has no uploaded photo.
class UserAvatar extends StatefulWidget {
  final String userId;
  final String initials;
  final String bgColorHex;
  final double size;

  const UserAvatar({
    super.key,
    required this.userId,
    required this.initials,
    required this.bgColorHex,
    this.size = 40,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  static final Map<String, String> _imageUrlCache = {};

  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _imageUrl = null;
      _resolveImage();
    }
  }

  void _resolveImage() {
    if (widget.userId.isEmpty) return;

    final cached = _imageUrlCache[widget.userId];
    if (cached != null) {
      _imageUrl = cached;
      return;
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get()
        .then((doc) {
      final url = doc.data()?['profileImageUrl'] as String? ?? '';
      _imageUrlCache[widget.userId] = url;
      if (mounted && url.isNotEmpty) {
        setState(() => _imageUrl = url);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AvatarWidget(
      initials: widget.initials,
      bgColorHex: widget.bgColorHex,
      size: widget.size,
      imageUrl: _imageUrl,
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.statusBg(status),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        AppTheme.statusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.statusText(status),
        ),
      ),
    );
  }
}

class KpBadge extends StatelessWidget {
  final String label;
  final double fontSize;

  const KpBadge({super.key, required this.label, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.kpBg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.toll_rounded, size: fontSize + 2, color: AppTheme.kpText),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.kpText,
            ),
          ),
        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String label;

  const TagChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class EduButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDanger;

  const EduButton({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary
        ? Colors.black87
        : isDanger
            ? const Color(0xFFFFEBEB)
            : Colors.white;
    final fg = isPrimary
        ? Colors.white
        : isDanger
            ? const Color(0xFF791F1F)
            : Colors.black87;
    final border = isPrimary
        ? Colors.transparent
        : isDanger
            ? const Color(0xFFF09595)
            : Colors.grey.shade300;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
