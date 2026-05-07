#include <FastLED.h>
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

FASTLED_USING_NAMESPACE

// Pebble serial-to-BLE TDS result test.
// Type a TDS value in Serial Monitor to print a result and notify the app.

static const char* DEVICE_NAME = "Pebble TestKit";
static const char* PEBBLE_SERVICE_UUID = "7b7d0001-4f8a-4c28-9f2a-6f0a8f0d1000";
static const char* PEBBLE_PAYLOAD_UUID = "7b7d0002-4f8a-4c28-9f2a-6f0a8f0d1000";

#define DATA_PIN D5
#define LED_TYPE WS2812
#define COLOR_ORDER GRB
#define NUM_LEDS 16
#define BRIGHTNESS 60

static const unsigned long FIRST_NOTIFY_DELAY_MS = 700;

BLECharacteristic* pebblePayloadCharacteristic = nullptr;
CRGB leds[NUM_LEDS];

bool deviceConnected = false;
bool initialNotifyPending = false;
String battery_number = "85";
String tds_number = "0";
unsigned long connectedAt = 0;

struct TdsResult {
  const char* result;
  const char* message;
  int score;
  CRGB color;
};

TdsResult resultForTds(int tds) {
  if (tds <= 150) {
    return {
      "excellent",
      "Low dissolved solids. Water quality looks good from TDS alone.",
      map(constrain(tds, 0, 150), 0, 150, 100, 90),
      CRGB::Green
    };
  }

  if (tds <= 300) {
    return {
      "good",
      "Moderate dissolved solids. Water is usually acceptable from TDS alone.",
      map(constrain(tds, 151, 300), 151, 300, 89, 75),
      CRGB::Yellow
    };
  }

  if (tds <= 500) {
    return {
      "caution",
      "High dissolved solids. Consider filtering or testing more indicators.",
      map(constrain(tds, 301, 500), 301, 500, 74, 55),
      CRGB::Orange
    };
  }

  return {
    "poor",
    "Very high dissolved solids. Do not rely on this water without treatment.",
    map(constrain(tds, 501, 1000), 501, 1000, 54, 20),
    CRGB::Red
  };
}

String payload() {
  return "{\"battery_number\":\"" + battery_number + "\",\"tds_number\":\"" + tds_number + "\"}";
}

String batteryOnlyPayload() {
  return "{\"battery_number\":\"" + battery_number + "\"}";
}

void showResultColor(const CRGB& color) {
  fill_solid(leds, NUM_LEDS, color);
  FastLED.show();
}

void publishPayloadText(const String& nextPayload, bool notifyConnected = true) {
  if (pebblePayloadCharacteristic == nullptr) {
    return;
  }

  pebblePayloadCharacteristic->setValue(nextPayload.c_str());

  if (deviceConnected && notifyConnected) {
    pebblePayloadCharacteristic->notify();
  }

  Serial.print("Sent to app: ");
  Serial.println(nextPayload);
}

void publishPayload(bool notifyConnected = true) {
  publishPayloadText(payload(), notifyConnected);
}

void publishBatteryOnlyPayload(bool notifyConnected = true) {
  publishPayloadText(batteryOnlyPayload(), notifyConnected);
}

String normalizedInput(String input) {
  input.trim();
  input.toLowerCase();
  input.replace("tds_number=", "");
  input.replace("tds=", "");
  input.replace("ppm", "");
  input.trim();
  return input;
}

bool isNumericTdsValue(const String& value) {
  if (value.length() == 0) {
    return false;
  }

  for (int i = 0; i < value.length(); i++) {
    if (!isDigit(value.charAt(i))) {
      return false;
    }
  }

  return true;
}

void printResultJson(int tds, const TdsResult& result) {
  Serial.print("{\"tds_number\":");
  Serial.print(tds);
  Serial.print(",\"result\":\"");
  Serial.print(result.result);
  Serial.print("\",\"score\":");
  Serial.print(result.score);
  Serial.print(",\"message\":\"");
  Serial.print(result.message);
  Serial.println("\"}");
}

void handleTdsInput(String input) {
  const String nextTds = normalizedInput(input);

  if (!isNumericTdsValue(nextTds)) {
    Serial.println("{\"error\":\"Use a number, tds=123, or tds_number=123.\"}");
    return;
  }

  const int tds = nextTds.toInt();
  const TdsResult result = resultForTds(tds);

  tds_number = nextTds;
  showResultColor(result.color);
  printResultJson(tds, result);
  publishPayload();
}

class PebbleServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* server) override {
    deviceConnected = true;
    initialNotifyPending = true;
    connectedAt = millis();
    Serial.println("BLE central connected.");
  }

  void onDisconnect(BLEServer* server) override {
    deviceConnected = false;
    initialNotifyPending = false;
    Serial.println("BLE central disconnected; advertising restarted.");
    BLEDevice::startAdvertising();
  }
};

void setupLedRing() {
  FastLED.addLeds<LED_TYPE, DATA_PIN, COLOR_ORDER>(leds, NUM_LEDS)
      .setCorrection(TypicalLEDStrip);
  FastLED.setBrightness(BRIGHTNESS);
  showResultColor(CRGB::White);
}

void setupBle() {
  BLEDevice::init(DEVICE_NAME);
  BLEDevice::setPower(ESP_PWR_LVL_P9);

  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new PebbleServerCallbacks());

  BLEService* pebbleService = server->createService(PEBBLE_SERVICE_UUID);

  pebblePayloadCharacteristic = pebbleService->createCharacteristic(
    PEBBLE_PAYLOAD_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pebblePayloadCharacteristic->addDescriptor(new BLE2902());
  publishPayload(false);

  pebbleService->start();

  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(PEBBLE_SERVICE_UUID);
  advertising->setScanResponse(true);
  advertising->setAppearance(0x00);
  advertising->setMinPreferred(0x06);
  advertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
}

void setup() {
  Serial.begin(115200);
  Serial.setTimeout(50);
  setupLedRing();
  setupBle();

  Serial.println("Pebble BLE TDS result test started.");
  Serial.print("BLE is advertising as ");
  Serial.println(DEVICE_NAME);
  Serial.println("Type a TDS value like 144, tds=144, or tds_number=144.");
}

void loop() {
  if (initialNotifyPending && millis() - connectedAt >= FIRST_NOTIFY_DELAY_MS) {
    initialNotifyPending = false;
    publishBatteryOnlyPayload();
  }

  if (!Serial.available()) {
    return;
  }

  handleTdsInput(Serial.readStringUntil('\n'));
}
