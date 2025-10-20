#include <Arduino.h>
#if defined(ESP32)
#include <WiFi.h>
#elif defined(ESP8266)
#include <ESP8266WiFi.h>
#endif
#include <Firebase_ESP_Client.h>

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

void setup() {
    Serial.begin(115200);

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
}

void loop() {
    // Send a random number every 5 seconds
    if (Firebase.ready() && millis() - prevMillis > 5000) {
        prevMillis = millis();

        int randomNumber = random(0, 100);

        if (Firebase.RTDB.setInt(&fbdo, "randomNumber", randomNumber)) {
            Serial.println("Random number sent: " + String(randomNumber));
        } else {
            Serial.println("FAILED to send data");
            Serial.println(String("Reason: ") + String(fbdo.errorReason()));
        }
    }
}
