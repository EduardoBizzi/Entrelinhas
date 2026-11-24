import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  bool _available(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
  Future<bool> check() async =>
      _available(await _connectivity.checkConnectivity());
  Stream<bool> get changes =>
      _connectivity.onConnectivityChanged.map(_available).distinct();
}
