import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/transaksi_entity.dart';
import '../../providers/master_data_provider.dart';

class ShowDetailTransaksiDialog extends StatelessWidget {
  final TransaksiEntity transaksi;
  const ShowDetailTransaksiDialog({super.key, required this.transaksi});

  @override
  Widget build(BuildContext context) {
    final masterDataProvider = context.read<MasterDataProvider>();
    final jenisBbmName = _getJenisBbmName(
      transaksi.jenisBbmId,
      masterDataProvider.jenisBBMList,
    );
    return AlertDialog(
      title: const Text('Detail Transaksi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Tanggal', transaksi.tanggalTransaksi),
          _buildDetailRow('Nomor Kupon', transaksi.nomorKupon),
          _buildDetailRow('Satker', transaksi.namaSatker),
          _buildDetailRow('Jenis BBM', jenisBbmName),
          // 'Jenis Kupon' not available in TransaksiEntity, use placeholder or omit
          // _buildDetailRow('Jenis Kupon', transaksi.jenisKuponId.toString()),
          _buildDetailRow('Jumlah (L)', transaksi.jumlahLiter.toString()),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  String _getJenisBbmName(
    int jenisBbmId,
    List<Map<String, dynamic>> jenisBbmList,
  ) {
    try {
      final bbm = jenisBbmList.firstWhere(
        (item) => item['jenis_bbm_id'] == jenisBbmId,
        orElse: () => {'nama_jenis_bbm': 'Unknown'},
      );
      return bbm['nama_jenis_bbm'] as String? ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
