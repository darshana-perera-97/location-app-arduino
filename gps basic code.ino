#include <SoftwareSerial.h>

SoftwareSerial gpsSerial(D5, D6); // RX, TX
const int LED_PIN = D4; // Built-in LED on NodeMCU

String gpsLine = "";

void setup() {
  Serial.begin(115200);
  gpsSerial.begin(9600);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, HIGH); // LED off (active LOW)
  Serial.println("Reading raw NMEA data...");
}

void loop() {
  while (gpsSerial.available()) {
    char c = gpsSerial.read();
    if (c == '\n') { // End of NMEA sentence
      gpsLine.trim();
      Serial.println(gpsLine); // print raw data

      // Check for GPGGA sentence (contains lat/lon)
      if (gpsLine.startsWith("$GPGGA")) {
        // Split the line by commas
        int firstComma = gpsLine.indexOf(',');
        int secondComma = gpsLine.indexOf(',', firstComma + 1);
        int thirdComma = gpsLine.indexOf(',', secondComma + 1);
        int fourthComma = gpsLine.indexOf(',', thirdComma + 1);
        int fifthComma = gpsLine.indexOf(',', fourthComma + 1);

        String lat = gpsLine.substring(firstComma + 1, secondComma);
        String lon = gpsLine.substring(thirdComma + 1, fourthComma);

        // Blink LED if lat and lon are not empty
        if (lat.length() > 0 && lon.length() > 0) {
          blinkLED();
        }
      }

      gpsLine = ""; // clear line buffer
    } else {
      gpsLine += c;
    }
  }
}

void blinkLED() {
  digitalWrite(LED_PIN, LOW);  // LED on
  delay(200);
  digitalWrite(LED_PIN, HIGH); // LED off
}
