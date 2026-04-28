import 'package:flutter/material.dart';

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  // A variable to remember which vehicle is currently selected.
  String? selectedVehicle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Background this black
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Heading 
              const Text(
                "Select Your Vehicle",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Sub Heading 
              Text(
                "Choose your vehicle type to optimize\nfatigue detection",
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Cards for 3 vehicles (here we call the function we created below)
              _buildVehicleCard("Bike", "Optimized for motorcycle riders with enhanced wind resistance detection", Icons.motorcycle),
              _buildVehicleCard("Car", "Standard detection for sedans and personal vehicles with AC environment", Icons.directions_car),
              _buildVehicleCard("Three Wheel", "Calibrated for tuk-tuk drivers with open-air exposure considerations", Icons.airport_shuttle), // ත්‍රීවීල් අයිකන් එකට ආසන්න එකක්

              const Spacer(), // This will push the Continue button all the way down. Continue button එක යටටම තල්ලු කරනවා

              // Continue Button 
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // If you choose a vehicle, it will be green or gray.
                    backgroundColor: selectedVehicle != null ? Colors.greenAccent[400] : const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  // The button cannot be pressed if a vehicle is not selected (null)
                  onPressed: selectedVehicle != null ? () {
                   // Here you can write the code to go to the next page
                    print("$selectedVehicle තෝරාගෙන ඇත!");
                  } : null,
                  child: Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
//If a vehicle is selected, the text is black or gray.                      color: selectedVehicle != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  "Please select a vehicle to continue",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // The small function that creates the card (this helps to stop you from writing code over and over again)
  Widget _buildVehicleCard(String title, String description, IconData icon) {
    bool isSelected = selectedVehicle == title; 
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedVehicle = title; // When clicked, this will be set as selected.
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          // If selected, a green border will appear.
          border: Border.all(
            color: isSelected ? Colors.greenAccent[400]! : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // The box with the icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.greenAccent[400] : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.black : Colors.grey[400],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text 
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      height: 1.4, 
                    ),
                  ),
                ],
              ),
            ),
            
            
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.greenAccent[400],
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
