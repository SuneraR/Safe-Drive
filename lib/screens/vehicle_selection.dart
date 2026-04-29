import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added for Provider
import 'theme_provider.dart'; // Ensure the path to your theme_provider is correct

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  // Logic: Track which vehicle is selected by ID
  String? selectedId;

  // Data for the vehicles
  final List<Map<String, dynamic>> vehicleTypes = [
    {
      "id": "bike",
      "title": "Bike",
      "desc": "Optimized for motorcycle riders with enhanced wind resistance detection",
      "icon": Icons.motorcycle_outlined,
    },
    {
      "id": "car",
      "title": "Car",
      "desc": "Standard detection for sedans and personal vehicles with AC environment",
      "icon": Icons.directions_car_outlined,
    },
    {
      "id": "tuk",
      "title": "Three Wheel",
      "desc": "Calibrated for tuk-tuk drivers with open-air exposure considerations",
      "icon": Icons.electric_rickshaw_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    // OPTIONAL: Pre-select the currently saved vehicle from Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentVehicle = Provider.of<ThemeNotifier>(context, listen: false).selectedVehicle;
      final found = vehicleTypes.firstWhere(
        (v) => v['title'] == currentVehicle,
        orElse: () => {},
      );
      if (found.isNotEmpty) {
        setState(() => selectedId = found['id']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware colors
    final Color accentGreen = theme.colorScheme.primary;
    final Color cardColor = theme.cardColor;
    final Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final Color subTextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // --- HEADER ---
              Text(
                "Select Your Vehicle",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Choose your vehicle type to optimize fatigue detection",
                style: TextStyle(fontSize: 14, color: subTextColor),
              ),

              const SizedBox(height: 32),

              // --- VEHICLE LIST ---
              Expanded(
                child: ListView.builder(
                  itemCount: vehicleTypes.length,
                  itemBuilder: (context, index) {
                    final item = vehicleTypes[index];
                    final bool isSelected = selectedId == item['id'];

                    return GestureDetector(
                      onTap: () => setState(() => selectedId = item['id']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? accentGreen : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentGreen
                                    : theme.colorScheme.surface.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item['icon'],
                                color: isSelected ? Colors.black : textColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Text Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['desc'],
                                    style: TextStyle(fontSize: 12, color: subTextColor),
                                  ),
                                ],
                              ),
                            ),

                            // Checkmark
                            if (isSelected)
                              Icon(Icons.check_circle, color: accentGreen, size: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- BOTTOM SECTION ---
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedId == null
                      ? null // Disables button if nothing is selected
                      : () {
                          // 1. Get the name of the selected vehicle
                          final selectedVehicleName = vehicleTypes.firstWhere((v) => v['id'] == selectedId)['title'];

                          // 2. Save it to the Provider (ThemeNotifier)
                          Provider.of<ThemeNotifier>(context, listen: false).updateVehicle(selectedVehicleName);

                          // 3. Navigation Logic
                          if (Navigator.canPop(context)) {
                            // If we came from Settings, go back to Settings
                            Navigator.pop(context);
                          } else {
                            // If we came from Signup, go to Dashboard
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selectedId == null ? Colors.white30 : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  selectedId == null
                      ? "Please select a vehicle to continue"
                      : "Vehicle selected",
                  style: TextStyle(fontSize: 12, color: subTextColor),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}