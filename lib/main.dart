import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'camera_sensor_service.dart';
import 'advanced_settings_panel.dart';
import 'scan_batch_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late InAppWebViewController _webViewController;
  late final MobileScannerController _scannerController;
  static const platform = MethodChannel('com.softwareoficial.bridge/command');

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(autoStart: false);
    _requestPermissions();
    _setupMethodChannel();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _setupMethodChannel() {
    platform.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'executeCommand') {
        final Map<String, dynamic> args = Map<String, dynamic>.from(call.arguments);
        final String command = args['cmd'] ?? '';
        
        if (command == 'openScanner') {
          final mode = args['mode'] ?? 'general';
          await _openScanner(context, mode);
        } else if (command == 'simulatedScan') {
          final String code = args['code'] ?? '123456789';
          final jsCode = """
            window.dispatchEvent(new MessageEvent('message', {
              data: {
                type: 'BARCODE_SCANNED',
                code: '${code.replaceAll("'", "'")}'
              }
            }));
          """;
          _webViewController.evaluateJavascript(source: jsCode);
        } else if (command == 'showNotification') {
          final String title = args['title'] ?? 'Notificación';
          final String body = args['body'] ?? '';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title: $body")),
          );
        }
      }
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  Future<String?> _openScanner(BuildContext context, String mode) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _ScannerOverlay(
        controller: _scannerController,
        webViewController: _webViewController,
        onScanCompleted: (code) {
          Navigator.of(context).pop();
        },
      ),
    );

    return result;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri("https://www.softwareoficial.com")),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            supportZoom: false,
            builtInZoomControls: false,
            displayZoomControls: false,
            disableContextMenu: true,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
          },
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openScanner(context, 'general'),
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}

// Nuevo StatefulWidget para encapsular la lógica del escáner y su ciclo de vida
class _ScannerOverlay extends StatefulWidget {
  final MobileScannerController controller;
  final InAppWebViewController webViewController;
  final Function(String?) onScanCompleted;

  const _ScannerOverlay({
    required this.controller,
    required this.webViewController,
    required this.onScanCompleted,
  });

  @override
  State<_ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<_ScannerOverlay> {
  late final CameraSensorService _sensorService;
  late final ScanBatchManager _batchManager;

  @override
  void initState() {
    super.initState();
    _sensorService = CameraSensorService(controller: widget.controller);
    _batchManager = ScanBatchManager();
    widget.controller.start();
  }

  @override
  void dispose() {
    widget.controller.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // Cierre al tocar el fondo
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.1),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Cámara rectangular arriba
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Container(
                      height: 250, // Altura rectangular
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: MobileScanner(
                          controller: widget.controller,
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              final String? code = _sensorService.validateBarcode(barcode);
                              if (code != null) {
                                HapticFeedback.lightImpact();
                                final jsCode = """
                                  window.dispatchEvent(new MessageEvent('message', {
                                    data: {
                                      type: 'BARCODE_SCANNED',
                                      code: '${code.replaceAll("'", "\\'")}'
                                    }
                                  }));
                                """;
                                widget.webViewController.evaluateJavascript(source: jsCode);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Enviado: $code"), 
                                    duration: Duration(milliseconds: 500),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                break;
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    // Controles pegados debajo, integrados al borde
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                      ),
                      child: AdvancedSettingsPanel(cameraSensorService: _sensorService),
                    ),
                  ],
                ),
              ),
              const Spacer(), // Espacio libre transparente debajo
            ],
          ),
        ),
      ),
    );
  }
}
