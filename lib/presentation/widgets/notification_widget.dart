import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/kupon_provider.dart';

const double _kLowStockThreshold = 3000.0;

List<_BbmAlert> _buildAlerts(KuponProvider provider) {
  final allKupons = provider.allKuponsForDropdown;

  final stokPertamax = allKupons
      .where((k) => k.jenisBbmId == 1 && k.isDeleted == 0)
      .fold(0.0, (sum, k) => sum + k.kuotaSisa);
  final stokDex = allKupons
      .where((k) => k.jenisBbmId == 2 && k.isDeleted == 0)
      .fold(0.0, (sum, k) => sum + k.kuotaSisa);

  final alerts = <_BbmAlert>[];
  if (stokPertamax < _kLowStockThreshold) {
    alerts.add(_BbmAlert(
      bbmName: 'Pertamax',
      stok: stokPertamax,
      timestamp: DateTime.now(),
    ));
  }
  if (stokDex < _kLowStockThreshold) {
    alerts.add(_BbmAlert(
      bbmName: 'Pertamina Dex',
      stok: stokDex,
      timestamp: DateTime.now(),
    ));
  }
  return alerts;
}

class _BbmAlert {
  final String bbmName;
  final double stok;
  final DateTime timestamp;
  const _BbmAlert({
    required this.bbmName,
    required this.stok,
    required this.timestamp,
  });
}

class NotificationBellButton extends StatefulWidget {
  final VoidCallback onNavigateToStokOpname;

  const NotificationBellButton({
    super.key,
    required this.onNavigateToStokOpname,
  });

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  bool _hasUnread = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<KuponProvider>(
      builder: (context, provider, _) {
        final alerts = _buildAlerts(provider);
        final hasAlerts = alerts.isNotEmpty;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E3A5F),
            shape: BoxShape.circle,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white, size: 20),
                onPressed: () {
                  setState(() => _hasUnread = false);
                  _showNotificationPanel(context, alerts);
                },
              ),
              if (hasAlerts && _hasUnread)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationPanel(BuildContext context, List<_BbmAlert> alerts) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (ctx) {
        return Stack(
          children: [
            Positioned(
              top: offset.dy + size.height + 8,
              right: MediaQuery.of(context).size.width - offset.dx - size.width,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: _NotificationPanel(
                  alerts: alerts,
                  onNavigateToStokOpname: () {
                    Navigator.of(ctx).pop();
                    widget.onNavigateToStokOpname();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  final List<_BbmAlert> alerts;
  final VoidCallback onNavigateToStokOpname;

  const _NotificationPanel({
    required this.alerts,
    required this.onNavigateToStokOpname,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 480),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Text(
                  'Notification',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                if (alerts.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${alerts.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          // Alert cards
          if (alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'Tidak ada notifikasi.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: alerts.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (_, i) => _AlertCard(
                  alert: alerts[i],
                  onInputStok: onNavigateToStokOpname,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final _BbmAlert alert;
  final VoidCallback onInputStok;

  const _AlertCard({required this.alert, required this.onInputStok});

  @override
  Widget build(BuildContext context) {
    final formattedStok = NumberFormat('#,##0', 'id_ID').format(alert.stok.toInt());
    final formattedTime =
        DateFormat('d MMM yyyy HH:mm', 'id_ID').format(alert.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning icon
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade600, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stok ${alert.bbmName} di bawah ambang batas',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Stok ${alert.bbmName} saat ini $formattedStok Liter',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedTime,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                        onPressed: onInputStok,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A5F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          textStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Input Stok BBM'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
