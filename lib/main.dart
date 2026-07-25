import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
        onScanCompleted: (code) {
          if (code != null) {
            final jsCode = """
              window.dispatchEvent(new MessageEvent('message', {
                data: {
                  type: 'BARCODE_SCANNED',
                  code: '${code.replaceAll("'", "\\'")}',
                  mode: '$mode'
                }
              }));
            """;
            _webViewController.evaluateJavascript(source: jsCode);
          }
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
  final Function(String?) onScanCompleted;

  const _ScannerOverlay({
    required this.controller,
    required this.onScanCompleted,
  });

  @override
  State<_ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<_ScannerOverlay> {
  @override
  void initState() {
    super.initState();
    // Asegurar que la cámara inicie cuando el widget esté montado
    widget.controller.start();
  }

  @override
  void dispose() {
    // Detener la cámara al desmontar el widget
    widget.controller.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // Cierre al tocar fuera
      child: Scaffold(
        backgroundColor: Colors.black54,
        body: Center(
          child: GestureDetector(
            onTap: () {}, // No cerrar si tocamos dentro
            child: Container(
              width: 320,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: MobileScanner(
                      controller: widget.controller,
                      onDetect: (capture) async {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          final String? code = barcode.rawValue;
                          if (code != null) {
                            // Detener la cámara antes de cerrar
                            await widget.controller.stop();
                            // Pequeño retardo para dar feedback visual
                            await Future.delayed(const Duration(milliseconds: 200));
                            widget.onScanCompleted(code);
                            break;
                          }
                        }
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 4),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
