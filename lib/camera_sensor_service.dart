import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';

class CameraSensorService {
  final MobileScannerController controller;
  
  // Buffer para validación multilínea (votación)
  final List<String> _scanResults = [];
  static const int _validationThreshold = 3; // Mínimo de escaneos idénticos

  CameraSensorService({required this.controller});

  // Toggle flash
  Future<void> toggleFlash() async {
    await controller.toggleTorch();
  }

  // Ajuste de Zoom (0.0 = min, 1.0 = max)
  Future<void> setZoom(double zoom) async {
    // Asegurarse de que el valor esté en el rango 0.0 - 1.0
    await controller.setZoomScale(zoom.clamp(0.0, 1.0));
  }

  // --- NUEVOS CONTROLES ---

  // Ajuste manual de enfoque
  Future<void> setFocusMode(bool manual) async {
    // mobile_scanner no expone enfoque manual preciso fácilmente
  }

  Future<void> setFocusPoint(double x, double y) async {
    await controller.setFocusPoint(Offset(x, y));
  }

  // Nota: mobile_scanner no soporta exposición manual directamente
  Future<void> setExposureOffset(double offset) async {
    debugPrint("Exposición no soportada por mobile_scanner");
  }

  // Control de duplicados con retardo
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  static const Duration _duplicateDelay = Duration(seconds: 10);

  // Lógica de votación de código de barras
  String? validateBarcode(Barcode barcode) {
    final String? rawValue = barcode.rawValue;
    if (rawValue == null) return null;

    // Lógica de duplicados inteligentes:
    // Si es el mismo código que el anterior y no han pasado 10 segundos, lo ignoramos.
    if (_lastScannedCode == rawValue && _lastScanTime != null) {
      final difference = DateTime.now().difference(_lastScanTime!);
      if (difference < _duplicateDelay) {
        return null; // Ignorado por duplicado reciente
      }
    }

    _scanResults.add(rawValue);
    if (_scanResults.length > 10) _scanResults.removeAt(0);

    // Contar ocurrencias
    final Map<String, int> counts = {};
    for (var result in _scanResults) {
      counts[result] = (counts[result] ?? 0) + 1;
    }

    for (var entry in counts.entries) {
      if (entry.value >= _validationThreshold) {
        _scanResults.clear(); // Limpiar tras confirmación
        
        // Guardar el estado para el control de duplicados
        _lastScannedCode = entry.key;
        _lastScanTime = DateTime.now();
        
        return entry.key;
      }
    }
    return null;
  }
}
