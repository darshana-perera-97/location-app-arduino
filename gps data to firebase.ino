#include <Arduino.h>
#if defined(ESP32)
#include <WiFi.h>
#elif defined(ESP8266)
#include <ESP8266WiFi.h>
#endif
#include <Firebase_ESP_Client.h>
#include <SoftwareSerial.h>

// Wi-Fi credentials
#define WIFI_SSID "Xiomi"
#define WIFI_PASSWORD "12345678"

// Firebase project info
#define API_KEY "AIzaSyAmwY_FWsjFpvBbJgOdZyR4IowURyeXvY0"
#define DATABASE_URL "https://location-app-764dd-default-rtdb.firebaseio.com/"

// Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long prevMillis = 0;

SoftwareSerial gpsSerial(D5, D6);  // RX, TX
const int LED_PIN = D4;            // Built-in LED on NodeMCU

String gpsLine = "";

// Helper function: convert NMEA format to decimal degrees
float convertNMEAToDecimal(String nmea, String dir) {
  float val = nmea.toFloat();
  int deg = (dir == "N" || dir == "S") ? int(val / 100) : int(val / 100); // latitude: 2 digits, longitude: 3 digits
  float min = val - (deg * 100);
  float decimal = deg + min / 60.0;
  if (dir == "S" || dir == "W") decimal = -decimal;
  return decimal;
}

void setup() {
  Serial.begin(115200);
  gpsSerial.begin(9600);

  // Connect Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.println("Connected to Wi-Fi: " + WiFi.localIP().toString());

  // Firebase setup
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Signup (anonymous)
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase signup OK");
  } else {
    Serial.println(String("Firebase signup failed: ") + config.signer.signupError.message.c_str());
  }

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, HIGH);  // LED off (active LOW)
  Serial.println("Reading raw NMEA data...");
}

void loop() {
  while (gpsSerial.available()) {
    char c = gpsSerial.read();
    if (c == '\n') {
      gpsLine.trim();
      Serial.println(gpsLine);

      // --- GPGGA: Latitude, Longitude, Fix Quality, Satellites, Altitude ---
      if (gpsLine.startsWith("$GPGGA")) {
        String parts[15];
        int index = 0, lastIndex = 0;
        for (int i = 0; i < gpsLine.length(); i++) {
          if (gpsLine[i] == ',' || i == gpsLine.length() - 1) {
            parts[index++] = gpsLine.substring(lastIndex, i);
            lastIndex = i + 1;
          }
        }

        String latStr = parts[2];
        String latDir = parts[3];
        String lonStr = parts[4];
        String lonDir = parts[5];
        String fixQualityStr = parts[6];
        String numSatStr = parts[7];
        String altitudeStr = parts[9];
        String utcTime = parts[1];

        if (latStr.length() > 0 && lonStr.length() > 0) {
          float lat = convertNMEAToDecimal(latStr, latDir);
          float lon = convertNMEAToDecimal(lonStr, lonDir);

          digitalWrite(LED_PIN, LOW);  // LED ON

          Firebase.RTDB.setFloat(&fbdo, "/Latitude", lat);
          Firebase.RTDB.setFloat(&fbdo, "/Longitude", lon);
          Firebase.RTDB.setInt(&fbdo, "/FixQuality", fixQualityStr.toInt());
          Firebase.RTDB.setInt(&fbdo, "/NumSatellites", numSatStr.toInt());
          Firebase.RTDB.setFloat(&fbdo, "/Altitude", altitudeStr.toFloat());
          Firebase.RTDB.setString(&fbdo, "/UTCTime", utcTime);
        } else {
          digitalWrite(LED_PIN, HIGH); // LED OFF
        }
      }

      // --- GPRMC: Speed, Course, Date ---
      if (gpsLine.startsWith("$GPRMC")) {
        String parts[13];
        int index = 0, lastIndex = 0;
        for (int i = 0; i < gpsLine.length(); i++) {
          if (gpsLine[i] == ',' || i == gpsLine.length() - 1) {
            parts[index++] = gpsLine.substring(lastIndex, i);
            lastIndex = i + 1;
          }
        }

        String speedStr = parts[7];  // Speed in knots
        String courseStr = parts[8]; // Course over ground
        String dateStr = parts[9];   // Date DDMMYY

        Firebase.RTDB.setFloat(&fbdo, "/Speed", speedStr.toFloat());
        Firebase.RTDB.setFloat(&fbdo, "/Course", courseStr.toFloat());
        Firebase.RTDB.setString(&fbdo, "/Date", dateStr);
      }

      gpsLine = ""; // Clear line buffer
    } else {
      gpsLine += c;
    }
  }

  // Optional: send a random number every 5 seconds
  if (Firebase.ready() && millis() - prevMillis > 5000) {
    prevMillis = millis();
    int randomNumber = random(0, 100);
    Firebase.RTDB.setInt(&fbdo, "/RandomNumber", randomNumber);
  }
}
