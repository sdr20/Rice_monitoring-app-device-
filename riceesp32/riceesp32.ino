#include <WiFi.h>
#include <WebServer.h>
#include <OneWire.h>
#include <DallasTemperature.h>

const char* ssid = "Rice Monitoring";
const char* password = "12345678";

#define ONE_WIRE_BUS_1 13
#define ONE_WIRE_BUS_2 14
#define ONE_WIRE_BUS_3 16
#define ONE_WIRE_BUS_4 17

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

  // Initialize sensors
  sensors1.begin();
  sensors2.begin();
  sensors3.begin();
  sensors4.begin();

  // Check if sensors are connected
  Serial.print("Sensor 1 found: ");
  Serial.println(sensors1.getDeviceCount());
  Serial.print("Sensor 2 found: ");
  Serial.println(sensors2.getDeviceCount());
  Serial.print("Sensor 3 found: ");
  Serial.println(sensors3.getDeviceCount());
  Serial.print("Sensor 4 found: ");
  Serial.println(sensors4.getDeviceCount());

  // Setup web server route
  server.on("/temperatures", HTTP_GET, []() {
    sensors1.requestTemperatures();
    sensors2.requestTemperatures();
    sensors3.requestTemperatures();
    sensors4.requestTemperatures();

    float temperature1 = sensors1.getTempCByIndex(0);
    float temperature2 = sensors2.getTempCByIndex(0);
    float temperature3 = sensors3.getTempCByIndex(0);
    float temperature4 = sensors4.getTempCByIndex(0);

    String response = String(temperature1) + "," +
                      String(temperature2) + "," +
                      String(temperature3) + "," +
                      String(temperature4);

    server.send(200, "text/plain", response);
  });
  server.begin();
}

void loop() {
  server.handleClient();

  // Continuously read and print temperatures
  static unsigned long lastTempRead = 0;
  if (millis() - lastTempRead > 2000) { // Read every 2 seconds
    lastTempRead = millis();

    sensors1.requestTemperatures();
    sensors2.requestTemperatures();
    sensors3.requestTemperatures();
    sensors4.requestTemperatures();

    float temperature1 = sensors1.getTempCByIndex(0);
    float temperature2 = sensors2.getTempCByIndex(0);
    float temperature3 = sensors3.getTempCByIndex(0);
    float temperature4 = sensors4.getTempCByIndex(0);

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

    Serial.println("--------------------");
  }
}