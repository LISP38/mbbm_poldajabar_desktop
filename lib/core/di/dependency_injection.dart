import 'package:get_it/get_it.dart';
import 'package:kupon_bbm_app/data/database/daos/dashboard_dao.dart';

import 'package:kupon_bbm_app/data/datasources/excel_datasource.dart';
import 'package:kupon_bbm_app/data/validators/kupon_validator.dart';
import 'package:kupon_bbm_app/data/services/enhanced_import_service.dart';
import 'package:kupon_bbm_app/domain/repositories/kendaraan_repository.dart';
import 'package:kupon_bbm_app/domain/repositories/kendaraan_repository_impl.dart';
import 'package:kupon_bbm_app/domain/repositories/kupon_repository.dart';
import 'package:kupon_bbm_app/domain/repositories/kupon_repository_impl.dart';
import 'package:kupon_bbm_app/domain/repositories/master_data_repository.dart';
import 'package:kupon_bbm_app/domain/repositories/master_data_repository_impl.dart';
import 'package:kupon_bbm_app/domain/repositories/transaksi_repository_impl.dart';
import 'package:kupon_bbm_app/presentation/providers/enhanced_import_provider.dart';
import 'package:kupon_bbm_app/domain/repositories/alokasi_repository.dart';
import 'package:kupon_bbm_app/domain/repositories/alokasi_repository_impl.dart';
import 'package:kupon_bbm_app/domain/repositories/jenis_bbm_repository.dart';
import 'package:kupon_bbm_app/domain/repositories/jenis_bbm_repository_impl.dart';
import 'package:kupon_bbm_app/domain/repositories/laporan_repository.dart';
import 'package:kupon_bbm_app/domain/repositories/laporan_repository_impl.dart';
import 'package:kupon_bbm_app/domain/repositories/dashboard_repository_impl.dart';
import 'package:kupon_bbm_app/presentation/providers/dashboard_controller.dart';
import 'package:kupon_bbm_app/data/database/app_database.dart';
import 'package:kupon_bbm_app/core/di/drift_sqflite_adapter.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // Drift Database & DAOs
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  getIt.registerLazySingleton(() => getIt<AppDatabase>().masterDao);
  getIt.registerLazySingleton(() => getIt<AppDatabase>().kuponDao);
  getIt.registerLazySingleton(() => getIt<AppDatabase>().transaksiDao);
  getIt.registerLazySingleton(() => getIt<AppDatabase>().reportingDao);
  getIt.registerLazySingleton(() => getIt<AppDatabase>().alokasiDao);

  // Drift Sqflite Adapter
  getIt.registerLazySingleton<DriftSqfliteAdapter>(
    () => DriftSqfliteAdapter(getIt<AppDatabase>()),
  );

  // Repositories
  getIt.registerLazySingleton<TransaksiRepositoryImpl>(
    () => TransaksiRepositoryImpl(getIt<AppDatabase>()), 
  );

  getIt.registerLazySingleton<KendaraanRepository>(
    () => KendaraanRepositoryImpl(getIt<AppDatabase>()), 
  );

  getIt.registerLazySingleton<KuponRepository>(
    () => KuponRepositoryImpl(getIt<AppDatabase>()), 
  );

  getIt.registerLazySingleton<MasterDataRepository>(
    () => MasterDataRepositoryImpl(getIt<AppDatabase>()), 
  );

  getIt.registerLazySingleton<AlokasiRepository>(
    () => AlokasiRepositoryImpl(getIt<AppDatabase>()), 
  );

  getIt.registerLazySingleton<JenisBbmRepository>(
    () => JenisBbmRepositoryImpl(getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<LaporanRepository>(
    () => LaporanRepositoryImpl(getIt<AppDatabase>()),
  );

  // Validators
  getIt.registerLazySingleton<KuponValidator>(() => KuponValidator());

  // Excel datasource
  getIt.registerLazySingleton<ExcelDatasource>(
    () => ExcelDatasource(getIt<KuponValidator>(), getIt<AppDatabase>()),
  );

  // Enhanced Import Service
  getIt.registerLazySingleton<EnhancedImportService>(
    () => EnhancedImportService(
      excelDatasource: getIt<ExcelDatasource>(),
      kuponRepository: getIt<KuponRepository>(),
      db: getIt<AppDatabase>(),
    ),
  );

  // Enhanced Import Provider
  getIt.registerFactory<EnhancedImportProvider>(
    () => EnhancedImportProvider(getIt<EnhancedImportService>()),
  );

  getIt.registerLazySingleton<DashboardRepositoryImpl>(
    () => DashboardRepositoryImpl(
      getIt<DashboardDao>(),
    ),
  );

  getIt.registerFactory<DashboardController>(
    () => DashboardController(
      getIt<DashboardRepositoryImpl>(),
    ),
  );

  getIt.registerLazySingleton<DashboardDao>(
    () => getIt<AppDatabase>().dashboardDao,
  );

}
