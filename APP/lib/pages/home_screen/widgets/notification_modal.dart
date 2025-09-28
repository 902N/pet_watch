// lib/pages/home_screen/widgets/notification_modal.dart
import 'package:flutter/material.dart';
import 'package:APP/const/colors.dart';
import 'package:APP/pages/home_screen/model/alert.dart';
import 'package:APP/pages/home_screen/services/alert_api.dart';

class NotificationModal extends StatefulWidget {
  final int petId;
  final String accessToken;
  final String? baseUrl;

  const NotificationModal({
    super.key,
    required this.petId,
    required this.accessToken,
    this.baseUrl,
  });

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal> {
  List<Alert> _allAlerts = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasNext = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final response = await AlertApi.getAlerts(
        petId: widget.petId,
        accessToken: widget.accessToken,
        baseUrl: widget.baseUrl,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _allAlerts.addAll(response.alerts);
          } else {
            _allAlerts = response.alerts;
          }
          _hasNext = response.hasNext;
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  String _enableBreakForLongTokens(String s) {
    return s
        .replaceAll('/', '/\u200B')
        .replaceAll('-', '-\u200B')
        .replaceAll('_', '_\u200B')
        .replaceAll('.', '.\u200B')
        .replaceAll(':', ':\u200B')
        .replaceAll('?', '?\u200B')
        .replaceAll('&', '&\u200B')
        .replaceAll('=', '=\u200B');
  }

  String _noMidWordBreak(String s) {
    final out = StringBuffer();
    final runes = s.runes.toList();
    bool joinable(int r) =>
        (r >= 0xAC00 && r <= 0xD7A3) ||
            (r >= 0x0030 && r <= 0x0039) ||
            (r >= 0x0041 && r <= 0x005A) ||
            (r >= 0x0061 && r <= 0x007A);
    for (int i = 0; i < runes.length; i++) {
      final cur = runes[i];
      out.writeCharCode(cur);
      if (i + 1 < runes.length) {
        final next = runes[i + 1];
        if (joinable(cur) && joinable(next)) out.write('\u2060');
      }
    }
    return out.toString();
  }

  String _fmt(String s) => _enableBreakForLongTokens(_noMidWordBreak(s));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildAlertList(_allAlerts)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '알림',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertList(List<Alert> alerts) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  color: AppColors.primaryAccent,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '알림을 불러오는 중...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.primaryAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _fmt(_errorMessage!),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadAlerts(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '다시 시도',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none,
                  size: 48,
                  color: AppColors.primaryAccent,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '알림이 없습니다',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '새로운 알림이 있으면 여기에 표시됩니다',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadAlerts(),
      color: AppColors.primaryAccent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length + (_hasNext ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == alerts.length) {
            return _buildLoadMoreButton();
          }
          final alert = alerts[index];
          return _buildAlertCard(alert);
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: TextButton(
          onPressed: _hasNext ? () => _loadAlerts(loadMore: true) : null,
          child: Text(
            _hasNext ? '더 보기' : '모든 알림을 불러왔습니다',
            style: TextStyle(
              color: _hasNext ? AppColors.primaryAccent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final timeAgo = _getTimeAgo(alert.detectedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRecordTypeColor(alert.recordType),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _fmt(alert.recordType),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    softWrap: true,
                    maxLines: null,
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _fmt(alert.anomalyMessage),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              softWrap: true,
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRecordTypeColor(String recordType) {
    switch (recordType) {
      case '산책':
        return AppColors.markerWalk;
      case '식사':
        return AppColors.markerMeal;
      case '병원':
        return AppColors.markerHospital;
      case '미용':
        return AppColors.markerGrooming;
      default:
        return AppColors.primaryAccent;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
