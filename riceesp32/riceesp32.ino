#include <WiFi.h>
#include <WebServer.h>
#include <OneWire.h>
#include <DallasTemperature.h>

const char* ssid = "Rice Monitoring";
const char* password = "12345678";

// Pin definitions for temperature sensors
#define ONE_WIRE_BUS_1 13
#define ONE_WIRE_BUS_2 14
#define ONE_WIRE_BUS_3 16
#define ONE_WIRE_BUS_4 17

// Pin definitions for soil moisture sensor
#define SOIL_MOISTURE_ANALOG_PIN 36  // A0 on ESP32 (ADC1_CHANNEL_0, GPIO 36)
#define SOIL_MOISTURE_DIGITAL_PIN 3  // Digital pin 3

// Pin definition for MQ-7 gas sensor
#define MQ7_ANALOG_PIN 34  // ADC1_CHANNEL_6, GPIO 34

OneWire oneWire1(ONE_WIRE_BUS_1);
OneWire oneWire2(ONE_WIRE_BUS_2);
OneWire oneWire3(ONE_WIRE_BUS_3);
OneWire oneWire4(ONE_WIRE_BUS_4);

DallasTemperature sensors1(&oneWire1);
DallasTemperature sensors2(&oneWire2);
DallasTemperature sensors3(&oneWire3);
DallasTemperature sensors4(&oneWire4);

WebServer server(80);

void setup() {
  Serial.begin(115200);

  // Setup WiFi Access Point
  WiFi.softAP(ssid, password);
  Serial.println("Access Point Started");
  Serial.print("IP Address: ");
  Serial.println(WiFi.softAPIP());

  // Initialize temperature sensors
  sensors1.begin();
  sensors2.begin();
  sensors3.begin();
  sensors4.begin();

  // Check if temperature sensors are connected
  Serial.print("Sensor 1 found: ");
  Serial.println(sensors1.getDeviceCount());
  Serial.print("Sensor 2 found: ");
  Serial.println(sensors2.getDeviceCount());
  Serial.print("Sensor 3 found: ");
  Serial.println(sensors3.getDeviceCount());
  Serial.print("Sensor 4 found: ");
  Serial.println(sensors4.getDeviceCount());

  // Setup pins for soil moisture sensor
  pinMode(SOIL_MOISTURE_DIGITAL_PIN, INPUT);

  // Setup web server route
  server.on("/sensors", HTTP_GET, []() {
    // Read temperature sensors
    sensors1.requestTemperatures();
    sensors2.requestTemperatures();
    sensors3.requestTemperatures();
    sensors4.requestTemperatures();

    float temperature1 = sensors1.getTempCByIndex(0);
    float temperature2 = sensors2.getTempCByIndex(0);
    float temperature3 = sensors3.getTempCByIndex(0);
    float temperature4 = sensors4.getTempCByIndex(0);

    // Read soil moisture sensor
    int soilMoistureAnalog = analogRead(SOIL_MOISTURE_ANALOG_PIN);
    int soilMoistureDigital = digitalRead(SOIL_MOISTURE_DIGITAL_PIN);

    // Map soil moisture analog value to a percentage (0-100)
    // Assuming 0 (dry) to 4095 (wet) for ESP32's 12-bit ADC
    float soilMoisturePercent = map(soilMoistureAnalog, 4095, 0, 0, 100);

    // Read MQ-7 gas sensor
    int mq7Value = analogRead(MQ7_ANALOG_PIN);
    // Map MQ-7 value to a range (e.g., 0-1000 ppm for CO concentration)
    // This is a simplified mapping; you may need to calibrate based on your sensor
    float mq7Concentration = map(mq7Value, 0, 4095, 0, 1000);

    // Create response string
    String response = String(temperature1) + "," +
                     String(temperature2) + "," +
                     String(temperature3) + "," +
                     String(temperature4) + "," +
                     String(soilMoisturePercent) + "," +
                     String(mq7Concentration);

    server.send(200, "text/plain", response);
  });
  server.begin();
}

void loop() {
  server.handleClient();

  // Continuously read and print sensor data
  static unsigned long lastRead = 0;
  if (millis() - lastRead > 2000) { // Read every 2 seconds
    lastRead = millis();

    // Read temperature sensors
    sensors1.requestTemperatures();
    sensors2.requestTemperatures();
    sensors3.requestTemperatures();
    sensors4.requestTemperatures();

    float temperature1 = sensors1.getTempCByIndex(0);
    float temperature2 = sensors2.getTempCByIndex(0);
    float temperature3 = sensors3.getTempCByIndex(0);
    float temperature4 = sensors4.getTempCByIndex(0);

    // Read soil moisture sensor
    int soilMoistureAnalog = analogRead(SOIL_MOISTURE_ANALOG_PIN);
    int soilMoistureDigital = digitalRead(SOIL_MOISTURE_DIGITAL_PIN);
    float soilMoisturePercent = map(soilMoistureAnalog, 4095, 0, 0, 100);

    // Read MQ-7 gas sensor
    int mq7Value = analogRead(MQ7_ANALOG_PIN);
    float mq7Concentration = map(mq7Value, 0, 4095, 0, 1000);

    // Print temperature readings
    Serial.println("Current Temperatures:");
    Serial.print("Sensor 1: ");
    if (temperature1 != DEVICE_DISCONNECTED_C) {
      Serial.print(temperature1);
      Serial.println(" °C");
    } else {
      Serial.println("Error");
    }

    Serial.print("Sensor 2: ");
    if (temperature2 != DEVICE_DISCONNECTED_C) {
      Serial.print(temperature2);
      Serial.println(" °C");
    } else {
      Serial.println("Error");
    }

    Serial.print("Sensor 3: ");
    if (temperature3 != DEVICE_DISCONNECTED_C) {
      Serial.print(temperature3);
      Serial.println(" °C");
    } else {
      Serial.println("Error");
    }

    Serial.print("Sensor 4: ");
    if (temperature4 != DEVICE_DISCONNECTED_C) {
      Serial.print(temperature4);
      Serial.println(" °C");
    } else {
      Serial.println("Error");
    }

    // Print soil moisture readings
    Serial.print("Soil Moisture Analog: ");
    Serial.print(soilMoistureAnalog);
    Serial.print("  Digital: ");
    Serial.print(soilMoistureDigital);
    Serial.print("  Percent: ");
    Serial.print(soilMoisturePercent);
    Serial.println("%");

    // Print MQ-7 gas readings
    Serial.print("MQ-7 Gas (CO): ");
    Serial.print(mq7Value);
    Serial.print("  Concentration: ");
    Serial.print(mq7Concentration);
    Serial.println(" ppm");

    Serial.println("--------------------");
  }
}