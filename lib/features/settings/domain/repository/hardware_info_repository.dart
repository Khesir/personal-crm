import '../model/hardware_info.dart';

abstract class HardwareInfoRepository {
  /// Detects the local machine's hardware. Never throws — detection
  /// failures fall back to "no dedicated GPU" / zeroed RAM rather than
  /// surfacing an error to the user.
  Future<HardwareInfo> detect();
}
