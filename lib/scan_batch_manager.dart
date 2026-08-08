class ScanBatchManager {
  final Set<String> _scannedCodes = {};

  List<String> get scannedCodes => _scannedCodes.toList();

  bool addCode(String code) {
    return _scannedCodes.add(code);
  }

  void removeCode(String code) {
    _scannedCodes.remove(code);
  }

  void clear() {
    _scannedCodes.clear();
  }
}
