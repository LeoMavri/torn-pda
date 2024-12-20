import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppwidgetExplanationDialog extends StatefulWidget {
  const AppwidgetExplanationDialog({super.key});

  @override
  State<AppwidgetExplanationDialog> createState() => _AppwidgetExplanationDialogState();
}

class _AppwidgetExplanationDialogState extends State<AppwidgetExplanationDialog> with WidgetsBindingObserver {
  static const platform = MethodChannel('tornpda.channel');
  Future<bool?>? _batteryOptimizationFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _batteryOptimizationFuture = _checkBatteryOptimization();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _batteryOptimizationFuture = _checkBatteryOptimization();
      });
    }
  }

  Future<bool?> _checkBatteryOptimization() async {
    try {
      final bool isRestricted = await platform.invokeMethod('checkBatteryOptimization');
      return isRestricted;
    } catch (e) {
      print("Error checking battery optimization: $e");
      return null; // Return null if there's an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Home Widget"),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "You have installed your first home screen widget!\n\n"
              "Please be aware that you can change several options (such as the theme) in the Settings menu "
              "here in the main app.\n\n"
              "Also, don't forget to visit the Tips section as there are a few hints and recommendations "
              "regarding battery consumption, refresh timer restrictions and others.",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            FutureBuilder<bool?>(
              future: _batteryOptimizationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || snapshot.data == null) {
                  return const SizedBox();
                } else {
                  final isRestricted = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isRestricted ? Icons.warning : Icons.check_circle,
                            color: isRestricted ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isRestricted
                                  ? "Background batery restrictions in place:\n\n"
                                      "It's recommended to change the background batery restrictions for Torn PDA "
                                      "to 'unrestricted' for optimal home widget performance"
                                  : "Battery optimization is properly configured",
                              style: TextStyle(
                                fontSize: 13,
                                color: isRestricted ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isRestricted)
                        ElevatedButton(
                          onPressed: () {
                            try {
                              platform.invokeMethod('openBatterySettings');
                            } catch (e) {
                              print("Error opening battery settings: $e");
                            }
                          },
                          child: const Text("Battery Settings"),
                        ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: const Text("Awesome!"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }
}
