#include <Adafruit_NeoPixel.h>
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

// Pebble Nano ESP32 BLE bridge.
// Advertises the Pebble service consumed by the Flutter Bluetooth client.
// Sends JSON fields named battery_number and tds_number.

static const char* DEVICE_NAME = "Pebble TestKit";

// Custom Pebble BLE service and characteristic UUIDs.
// Keep these values in sync with the Flutter Bluetooth client.
static const char* PEBBLE_SERVICE_UUID = "7b7d0001-4f8a-4c28-9f2a-6f0a8f0d1000";
static const char* PEBBLE_PAYLOAD_UUID = "7b7d0002-4f8a-4c28-9f2a-6f0a8f0d1000";

// WS2812B 16-pixel RGB LED ring.
// Wiring: 5V -> 5V, DI -> D5, GND -> GND.
static const int LED_RING_PIN = D5;
static const int LED_RING_COUNT = 16;
static const int LED_RING_BRIGHTNESS = 60;

// TDS water quality levels in ppm. Lower TDS is considered better here.
static const int TDS_EXCELLENT_MAX = 150;
static const int TDS_GOOD_MAX = 300;
static const int TDS_SENSOR_MAX = 1000;
static const uint8_t MIN_STATUS_SATURATION = 80;
static const uint8_t MAX_STATUS_SATURATION = 255;
static const unsigned long BLE_NOTIFY_INTERVAL_MS = 5000;
static const unsigned long FIRST_NOTIFY_DELAY_MS = 700;

BLECharacteristic* pebblePayloadCharacteristic = nullptr;
Adafruit_NeoPixel ledRing(LED_RING_COUNT, LED_RING_PIN, NEO_GRB + NEO_KHZ800);

bool deviceConnected = false;
bool initialNotifyPending = false;
String battery_number = "85";
String tds_number = "0";
unsigned long connectedAt = 0;
unsigned long lastNotifyAt = 0;

String batteryPayload() {
  return "{\"battery_number\":\"" + battery_number + "\",\"tds_number\":\"" + tds_number + "\"}";
}

String batteryOnlyPayload() {
  return "{\"battery_number\":\"" + battery_number + "\"}";
}

void publishBatteryNumber(bool notifyConnected = true);

class PebbleServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* server) override {
    deviceConnected = true;
    initialNotifyPending = true;
    connectedAt = millis();
    lastNotifyAt = 0;
    Serial.println("BLE central connected.");
  }

  void onDisconnect(BLEServer* server) override {
    deviceConnected = false;
    initialNotifyPending = false;
    Serial.println("BLE central disconnected; advertising restarted.");
    BLEDevice::startAdvertising();
  }
};

void publishPayload(const String& payload, bool notifyConnected = true) {
  if (pebblePayloadCharacteristic == nullptr) {
    return;
  }

  pebblePayloadCharacteristic->setValue(payload.c_str());

  if (deviceConnected && notifyConnected) {
    pebblePayloadCharacteristic->notify();
  }

  Serial.print("BLE payload: ");
  Serial.println(payload);
}

void publishBatteryOnlyPayload(bool notifyConnected = true) {
  publishPayload(batteryOnlyPayload(), notifyConnected);
}

void publishBatteryNumber(bool notifyConnected) {
  publishPayload(batteryPayload(), notifyConnected);
}

void updateBatteryNumber(String nextValue) {
  nextValue.trim();
  nextValue.replace("%", "");

  if (nextValue.length() == 0) {
    return;
  }

  battery_number = nextValue;
  publishBatteryOnlyPayload();
}

String normalizedTdsInput(String input) {
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

void updateTdsNumber(String nextValue) {
  const String normalizedValue = normalizedTdsInput(nextValue);
  if (!isNumericTdsValue(normalizedValue)) {
    Serial.println("{\"error\":\"Use a number, tds=123, tds_number=123, or battery_number=85.\"}");
    return;
  }

  const int tdsValue = normalizedValue.toInt();
  tds_number = String(tdsValue);
  showWaterQualityOnLedRing(tdsValue);
  publishBatteryNumber();
}

uint8_t statusSaturation(int tdsValue, int rangeMin, int rangeMax) {
  tdsValue = constrain(tdsValue, rangeMin, rangeMax);
  const int range = max(1, rangeMax - rangeMin);
  const int qualityPosition = rangeMax - tdsValue;

  return map(
    qualityPosition,
    0,
    range,
    MIN_STATUS_SATURATION,
    MAX_STATUS_SATURATION
  );
}

uint32_t waterQualityColor(int tdsValue) {
  uint16_t hue = 0;
  uint8_t saturation = MAX_STATUS_SATURATION;

  if (tdsValue <= TDS_EXCELLENT_MAX) {
    hue = 21845; // Green.
    saturation = statusSaturation(tdsValue, 0, TDS_EXCELLENT_MAX);
  } else if (tdsValue <= TDS_GOOD_MAX) {
    hue = 10923; // Yellow.
    saturation = statusSaturation(tdsValue, TDS_EXCELLENT_MAX + 1, TDS_GOOD_MAX);
  } else {
    hue = 0; // Red.
    saturation = statusSaturation(tdsValue, TDS_GOOD_MAX + 1, TDS_SENSOR_MAX);
  }

  return ledRing.ColorHSV(hue, saturation, 255);
}

void showWaterQualityOnLedRing(int tdsValue) {
  const uint32_t color = ledRing.gamma32(waterQualityColor(tdsValue));

  for (int i = 0; i < LED_RING_COUNT; i++) {
    ledRing.setPixelColor(i, color);
  }

  ledRing.show();
}

void readSerialCommand() {
  if (!Serial.available()) {
    return;
  }

  String input = Serial.readStringUntil('\n');
  input.trim();
  if (input.length() == 0) {
    return;
  }

  String command = input;
  command.toLowerCase();

  const String batteryPrefix = "battery_number=";
  if (command.startsWith(batteryPrefix)) {
    updateBatteryNumber(input.substring(batteryPrefix.length()));
    return;
  }

  const String tdsPrefix = "tds_number=";
  if (command.startsWith(tdsPrefix)) {
    updateTdsNumber(input.substring(tdsPrefix.length()));
    return;
  }

  const String shortTdsPrefix = "tds=";
  if (command.startsWith(shortTdsPrefix)) {
    updateTdsNumber(input.substring(shortTdsPrefix.length()));
    return;
  }

  if (isNumericTdsValue(normalizedTdsInput(input))) {
    updateTdsNumber(input);
    return;
  }

  Serial.println("{\"error\":\"Use a number, tds=123, tds_number=123, or battery_number=85.\"}");
}

void setupLedRing() {
  ledRing.begin();
  ledRing.setBrightness(LED_RING_BRIGHTNESS);
  ledRing.clear();
  showWaterQualityOnLedRing(0);
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
  publishBatteryOnlyPayload(false);

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
  Serial.println();
  Serial.println("Booting Pebble Nano ESP32 BLE bridge...");

  setupLedRing();
  setupBle();

  Serial.println("Pebble Nano ESP32 BLE bridge started.");
  Serial.print("BLE is advertising as ");
  Serial.println(DEVICE_NAME);
  Serial.print("Pebble service UUID: ");
  Serial.println(PEBBLE_SERVICE_UUID);
  Serial.print("Payload characteristic UUID: ");
  Serial.println(PEBBLE_PAYLOAD_UUID);
  Serial.println("No PIN, password, or Android Bluetooth settings pairing is required.");
  Serial.println("Connect from the Pebble app or a BLE scanner such as nRF Connect.");
  Serial.println("Send manual TDS through Serial, for example:");
  Serial.println("123");
  Serial.println("tds=123");
  Serial.println("tds_number=123");
  Serial.println("Send battery through Serial, for example:");
  Serial.println("battery_number=85");
  Serial.println("TDS is sent only when you type a value in Serial Monitor.");
  Serial.println("WS2812B LED ring reads DI from D5.");
}

void loop() {
  readSerialCommand();

  const unsigned long now = millis();
  if (initialNotifyPending && now - connectedAt >= FIRST_NOTIFY_DELAY_MS) {
    initialNotifyPending = false;
    publishBatteryOnlyPayload();
  }

  if (deviceConnected && now - lastNotifyAt >= BLE_NOTIFY_INTERVAL_MS) {
    lastNotifyAt = now;
    publishBatteryOnlyPayload();
  }
}
