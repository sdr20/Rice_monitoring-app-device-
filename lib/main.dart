import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(TemperatureMonitorApp());
}

class TemperatureMonitorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rice Storage Temperature Monitor',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: TemperatureScreen(),
    );
  }
}

class TemperatureScreen extends StatefulWidget {
  @override
  _TemperatureScreenState createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  List<double> temperatures = [0.0, 0.0, 0.0, 0.0];
  String _serverIP = '192.168.4.1';

  @override
  void initState() {
    super.initState();
    _startTemperaturePolling();
  }

  void _startTemperaturePolling() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchTemperatures();
    });
  }

  Future<void> _fetchTemperatures() async {
    try {
      final response = await http.get(Uri.parse('http://$_serverIP/temperatures'));
      if (response.statusCode == 200) {
        List<String> tempStrings = response.body.split(',');
        setState(() {
          temperatures = tempStrings.map((temp) => double.parse(temp)).toList();
        });
      } else {
        print('Error: Server responded with status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching temperatures: $e');
    }
  }

  Widget _buildThermometer(double temperature, String label) {
    double heightFactor = (temperature - 20) / 30;
    heightFactor = heightFactor < 0 ? 0 : heightFactor > 1 ? 1 : heightFactor;
    Color color = temperature > 35 ? Colors.red : Colors.blue;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 10),
        Container(
          width: 100,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[800],
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                width: 60,
                height: 200 * heightFactor,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Positioned(
                bottom: 10,
                child: Text(
                  '${temperature.toStringAsFixed(1)}°C',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Rice Storage Temperature'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildThermometer(temperatures[3], 'Sensor 4'),
                    SizedBox(height: 20),
                    _buildThermometer(temperatures[2], 'Sensor 3'),
                    SizedBox(height: 20),
                    _buildThermometer(temperatures[1], 'Sensor 2'),
                    SizedBox(height: 20),
                    _buildThermometer(temperatures[0], 'Sensor 1'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '© Roman',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}