import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyatet_pesse/features/security/presentation/providers/security_provider.dart';
import 'package:nyatet_pesse/features/settings/domain/services/backup_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(secureStorageProvider));
});
