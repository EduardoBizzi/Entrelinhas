import 'package:geolocator/geolocator.dart';
import '../utils/error_message.dart';

class LocationService {
  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AppException(
        'O GPS está desligado. Ative a localização do dispositivo e tente novamente.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const AppException(
        'Permissão negada. Você pode salvar o registro sem localização.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AppException(
        'Permissão bloqueada. Abra as configurações do aplicativo para permitir a localização.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 25),
      ),
    );
  }
}
