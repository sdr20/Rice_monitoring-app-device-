import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(const TemperatureMonitorApp());
}

class TemperatureMonitorApp extends StatelessWidget {
  const TemperatureMonitorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RiceGuard', // Changed from "Rice Storage Monitor" to "RiceGuard"
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        textTheme: ThemeData.dark().textTheme,
        cardTheme: const CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          color: Color(0xFF16213E),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const TemperatureScreen(),
    );
  }
}

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({Key? key}) : super(key: key);

  @override
  TemperatureScreenState createState() => TemperatureScreenState();
}

class TemperatureScreenState extends State<TemperatureScreen> {
  List<double> temperatures = [0.0, 0.0, 0.0, 0.0];
  double soilMoisture = 0.0;
  double gasConcentration = 0.0;
  String serverIP = '192.168.4.1';
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    startSensorPolling();
  }

  void startSensorPolling() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchSensorData();
    });
  }

  Future<void> fetchSensorData() async {
    setState(() => isRefreshing = true);
    try {
      final response = await http.get(Uri.parse('http://$serverIP/sensors'));
      if (response.statusCode == 200) {
        List<String> sensorData = response.body.split(',');
        setState(() {
          temperatures = sensorData.sublist(0, 4).map((temp) => double.parse(temp)).toList();
          soilMoisture = double.parse(sensorData[4]);
          gasConcentration = double.parse(sensorData[5]);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fetch Error: $e')),
      );
    }
    setState(() => isRefreshing = false);
  }

  Widget buildThermometer(double temperature, String label, double screenHeight, double screenWidth) {
    double heightFactor = (temperature - 20) / 30;
    heightFactor = heightFactor.clamp(0, 1);
    Color color = temperature > 35
        ? Colors.redAccent
        : temperature > 30
            ? Colors.orangeAccent
            : Colors.tealAccent;

    // Responsive sizes
    double thermometerHeight = screenHeight * 0.25;
    double thermometerWidth = screenWidth * 0.2;
    double fontSizeLabel = screenWidth * 0.035;
    double fontSizeValue = screenWidth * 0.03;
    double spacing = screenHeight * 0.01;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: fontSizeLabel, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: spacing),
        Container(
          width: thermometerWidth,
          height: thermometerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3460), Color(0xFF1A1A2E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                width: thermometerWidth * 0.5,
                height: thermometerHeight * heightFactor,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.7), color],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Positioned(
                bottom: spacing,
                child: Text(
                  '${temperature.toStringAsFixed(1)}°C',
                  style: TextStyle(fontSize: fontSizeValue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSoilMoistureGauge(double moisture, double screenHeight, double screenWidth) {
    Color color = moisture < 30
        ? Colors.redAccent
        : moisture < 50
            ? Colors.orangeAccent
            : Colors.greenAccent;

    // Responsive sizes
    double gaugeSize = screenHeight * 0.18;
    double fontSizeLabel = screenWidth * 0.035;
    double fontSizeValue = screenWidth * 0.05;
    double spacing = screenHeight * 0.015;

    return Column(
      children: [
        Text(
          'Soil Moisture',
          style: TextStyle(fontSize: fontSizeLabel, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: spacing),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: gaugeSize,
              height: gaugeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3460), Color(0xFF1A1A2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
              ),
            ),
            SizedBox(
              width: gaugeSize * 0.85,
              height: gaugeSize * 0.85,
              child: CircularProgressIndicator(
                value: moisture / 100,
                strokeWidth: gaugeSize * 0.1,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                backgroundColor: Colors.white12,
              ),
            ),
            Text(
              '${moisture.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: fontSizeValue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildGasGauge(double gasValue, double screenHeight, double screenWidth) {
    double widthFactor = (gasValue / 1000).clamp(0, 1);
    Color color = gasValue > 200
        ? Colors.redAccent
        : gasValue > 100
            ? Colors.orangeAccent
            : Colors.yellowAccent;

    // Responsive sizes
    double gaugeWidth = screenWidth * 0.55;
    double gaugeHeight = screenHeight * 0.06;
    double fontSizeLabel = screenWidth * 0.035;
    double fontSizeValue = screenWidth * 0.03;
    double spacing = screenHeight * 0.015;

    return Column(
      children: [
        Text(
          'MQ-7 Gas (CO)',
          style: TextStyle(fontSize: fontSizeLabel, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: spacing),
        Container(
          width: gaugeWidth,
          height: gaugeHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3460), Color(0xFF1A1A2E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                width: gaugeWidth * widthFactor,
                height: gaugeHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.7), color],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing),
                child: Text(
                  '${gasValue.toStringAsFixed(1)} ppm',
                  style: TextStyle(fontSize: fontSizeValue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double aspectRatio = (screenWidth / screenHeight) * 1.2;
    aspectRatio = aspectRatio.clamp(0.5, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RiceGuard', style: TextStyle(fontWeight: FontWeight.w700)), // Changed here as well
        centerTitle: true,
        backgroundColor: const Color(0xFF16213E),
        elevation: 4,
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isRefreshing
                  ? const Icon(Icons.refresh, key: ValueKey('refreshing'), color: Colors.white)
                  : const Icon(Icons.refresh, key: ValueKey('idle')),
            ),
            onPressed: fetchSensorData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    children: [
                      // Temperature Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: screenHeight * 0.02,
                        crossAxisSpacing: screenWidth * 0.04,
                        childAspectRatio: aspectRatio,
                        children: [
                          buildThermometer(temperatures[0], 'Sensor 1', screenHeight, screenWidth),
                          buildThermometer(temperatures[1], 'Sensor 2', screenHeight, screenWidth),
                          buildThermometer(temperatures[2], 'Sensor 3', screenHeight, screenWidth),
                          buildThermometer(temperatures[3], 'Sensor 4', screenHeight, screenWidth),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      // MQ-7 Gas Gauge
                      buildGasGauge(gasConcentration, screenHeight, screenWidth),
                      SizedBox(height: screenHeight * 0.03),
                      // Soil Moisture Gauge
                      buildSoilMoistureGauge(soilMoisture, screenHeight, screenWidth),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                '© Roman',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}