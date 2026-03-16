import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final Rx<bool> isOnline = true.obs;
  late Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
  }

  void _initConnectivity() {
    _connectivityStream = _connectivity.onConnectivityChanged;

    // Listen to connectivity changes
    _connectivityStream.listen((results) {
      _updateConnectionStatus(results);
    });

    // Check initial connectivity
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Error checking connectivity: $e');
      isOnline.value = true; // Assume online on error
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Check if any connection is available (not none)
    bool hasConnection =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    // If the list is empty or only contains none, we're offline
    if (results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none)) {
      hasConnection = false;
    }

    // Add some delay to prevent fluttering
    Future.delayed(Duration(milliseconds: 500), () {
      isOnline.value = hasConnection;
    });
  }

  Future<bool> hasConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (e) {
      print('Error checking connection: $e');
      return true; // Assume online on error
    }
  }

  String getOnlineStatus() {
    return isOnline.value ? 'Online' : 'Offline';
  }

  Stream<bool> get onConnectivityChanged {
    return _connectivityStream.map(
      (results) =>
          results.isNotEmpty && !results.contains(ConnectivityResult.none),
    );
  }

  void startMonitoring() {
    _initConnectivity();
  }

  void stopMonitoring() {
    // Connectivity is automatically monitored through the stream
  }

}
