import 'package:flutter/material.dart';
import 'camera_sensor_service.dart';

class AdvancedSettingsPanel extends StatefulWidget {
  final CameraSensorService cameraSensorService;

  const AdvancedSettingsPanel({super.key, required this.cameraSensorService});

  @override
  State<AdvancedSettingsPanel> createState() => _AdvancedSettingsPanelState();
}

class _AdvancedSettingsPanelState extends State<AdvancedSettingsPanel> {
  double _currentZoom = 0.0;
  bool _isFlashOn = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Flash", style: TextStyle(color: Colors.white)),
              Switch(
                value: _isFlashOn,
                onChanged: (value) async {
                  await widget.cameraSensorService.toggleFlash();
                  setState(() => _isFlashOn = value);
                },
              ),
              const SizedBox(width: 30),
              const Text("Zoom", style: TextStyle(color: Colors.white)),
              Expanded(
                child: Slider(
                  value: _currentZoom,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() => _currentZoom = value);
                    widget.cameraSensorService.setZoom(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
