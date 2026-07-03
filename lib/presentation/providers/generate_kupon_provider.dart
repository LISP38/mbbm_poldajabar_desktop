import 'package:flutter/material.dart';
import 'package:kupon_bbm_app/domain/entities/kupon_entity.dart';
import 'package:kupon_bbm_app/domain/repositories/generate_kupon_repository.dart';
import 'package:open_file/open_file.dart';

/// Controller untuk fitur **Generate Kupon** dan **Adjust Stok Sistem**.
///
/// Dipisahkan dari [KuponController] sesuai prinsip Single Responsibility:
/// - [KuponController]: tampilan dan filter data kupon
/// - [GenerateKuponController]: generate file kupon + penyesuaian stok sistem
///
/// Dependency: [GenerateKuponRepository] (interface, bukan implementasi)
class GenerateKuponController extends ChangeNotifier {
  final GenerateKuponRepository _repo;

  GenerateKuponController(this._repo);

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _generatedFilePath;
  String? get generatedFilePath => _generatedFilePath;

  double _currentStokSistemPx = 0;
  double get currentStokSistemPx => _currentStokSistemPx;

  double _currentStokSistemDex = 0;
  double get currentStokSistemDex => _currentStokSistemDex;

  // ── Load Stok Sistem ───────────────────────────────────────────────────────

  /// Memuat nilai stok sistem Pertamax dan Dex dari kupon aktif.
  Future<void> loadCurrentStokSistem() async {
    try {
      _currentStokSistemPx = await _repo.getCurrentStokSistemPertamax();
      _currentStokSistemDex = await _repo.getCurrentStokSistemDex();
      notifyListeners();
    } catch (e) {
      debugPrint('[GenerateKuponController] loadCurrentStokSistem error: $e');
    }
  }

  // ── Generate File Kupon ────────────────────────────────────────────────────

  /// Membuat dan membuka file kupon dari daftar kupon yang diberikan.
  ///
  /// [kupons]: daftar [KuponEntity] yang akan dicetak.
  /// [templatePath]: path ke file template Word/PDF.
  ///
  /// Mengembalikan `null` jika berhasil, atau pesan error jika gagal.
  Future<String?> generateKuponFile({
    required List<KuponEntity> kupons,
    required String templatePath,
  }) async {
    if (kupons.isEmpty) {
      return 'Pilih setidaknya satu kupon untuk di-generate';
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String generatedPath = await _repo.generateKuponFile(
        kupons: kupons,
        templatePath: templatePath,
      );

      _generatedFilePath = generatedPath;

      // Buka file yang dihasilkan
      final openResult = await OpenFile.open(generatedPath);
      if (openResult.type != ResultType.done) {
        _isLoading = false;
        notifyListeners();
        return 'Gagal membuka file: ${openResult.message}';
      }

      _isLoading = false;
      notifyListeners();
      return null; // sukses
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return 'Error generate kupon: $e';
    }
  }

  // ── Adjust Stok Sistem ─────────────────────────────────────────────────────

  /// Menyesuaikan stok sistem kupon agar sesuai dengan stok fisik opname.
  ///
  /// Dipanggil oleh [StokOpnameController] setelah input stok opname,
  /// agar stok sistem (dari kupon) = stok fisik (hasil penghitungan fisik).
  Future<void> adjustStokSistemToFisik({
    required double targetFisikPx,
    required double targetFisikDex,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.adjustKuotaToFisik(
        targetFisikPx: targetFisikPx,
        targetFisikDex: targetFisikDex,
      );
      // Refresh nilai stok sistem setelah adjustment
      await loadCurrentStokSistem();
      debugPrint(
        '[GenerateKuponController] adjustStokSistemToFisik selesai: '
        'Px=${_currentStokSistemPx.toStringAsFixed(0)}, '
        'Dex=${_currentStokSistemDex.toStringAsFixed(0)}',
      );
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[GenerateKuponController] adjustStokSistemToFisik error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menambahkan penerimaan BBM ke stok sistem (via kuota_awal kupon aktif).
  ///
  /// Dipanggil setelah [StokOpnameController.simpanPenerimaanBbm] berhasil.
  Future<void> tambahStokSistemDariPenerimaan({
    required double penerimaanPx,
    required double penerimaanDex,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.tambahStokSistemDariPenerimaan(
        penerimaanPx: penerimaanPx,
        penerimaanDex: penerimaanDex,
      );
      await loadCurrentStokSistem();
      debugPrint(
        '[GenerateKuponController] tambahStokSistem selesai: '
        '+Px=$penerimaanPx, +Dex=$penerimaanDex',
      );
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[GenerateKuponController] tambahStokSistem error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
