import 'package:local_auth/local_auth.dart';

class PasswordService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isFingerprintAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    final biometrics = await _auth.getAvailableBiometrics();

    print('Biometrias disponíveis: $biometrics');
    return canCheck &&
            isSupported &&
            biometrics.contains(BiometricType.fingerprint) ||
        biometrics.contains(BiometricType.strong);
  }

  Future<bool> authenticateWithFingerprint() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Toque o sensor para autenticar com sua digital',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      print('Erro na autenticação: $e');
      return false;
    }
  }
}
