#include <Adafruit_NeoPixel.h>
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

// Pebble ESP32 BLE bridge.
// Advertises the Pebble service consumed by the Flutter Bluetooth client.
// Sends JSON fields named battery_number and tds_number.

static const char* DEVICE_NAME = "Pebble TestKit";

// Custom Pebble BLE service and characteristic UUIDs.
// Keep these values in sync with the Flutter Bluetooth client.
static const char* PEBBLE_SERVICE_UUID = "7b7d0001-4f8a-4c28-9f2a-6f0a8f0d1000";
static const char* PEBBLE_PAYLOAD_UUID = "7b7d0002-4f8a-4c28-9f2a-6f0a8f0d1000";

// TDS sensor analog output pin.
// ESP32 ADC input-only pins like GPIO34 are a good default for analog sensors.
static const int TDS_SENSOR_PIN = 34;
static const float ADC_REFERENCE_VOLTAGE = 3.3;
static const int ADC_RESOLUTION = 4095;
static const float WATER_TEMPERATURE_C = 25.0;
static const int TDS_SAMPLE_COUNT = 20;
static const unsigned long TDS_READ_INTERVAL_MS = 1000;

// WS2812B 16-bit RGB LED ring.
// Wiring from the LED ring description:
// 5V -> 5V, DI -> pin 6, GND -> GND.
// Note: On some ESP32 boards GPIO6 is reserved for flash. If the board cannot
// boot or the LED ring does not respond, move DI to a safe GPIO and update this.
static const int LED_RING_PIN = 6;
static const int LED_RING_COUNT = 16;
static const int LED_RING_BRIGHTNESS = 90;

// TDS water quality levels in ppm. Lower TDS is considered better here.
static const int TDS_EXCELLENT_MAX = 150;
static const int TDS_GOOD_MAX = 300;
static const int TDS_SENSOR_MAX = 1000;
static const uint8_t MIN_STATUS_SATURATION = 80;
static const uint8_t MAX_STATUS_SATURATION = 255;

BLECharacteristic* pebblePayloadCharacteristic = nullptr;
Adafruit_NeoPixel ledRing(LED_RING_COUNT, LED_RING_PIN, NEO_GRB + NEO_KHZ800);
bool deviceConnected = false;
String battery_number = "85";
String tds_number = "0";
unsigned long lastNotifyAt = 0;
unsigned long lastTdsReadAt = 0;

void publishBatteryOnlyPayload();

class PebbleServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* server) override {
    deviceConnected = true;
    publishBatteryOnlyPayload();
  }

  void onDisconnect(BLEServer* server) override {
    deviceConnected = false;
    BLEDevice::startAdvertising();
  }
};

void setupOpenBleConnection() {
  // Open BLE connection mode:
  // - Advertises immediately.
  // - Does not require a PIN/password.
  // - Does not require bonding.
  // If Android shows a connection prompt, tap confirm to continue.
  BLESecurity* security = new BLESecurity();
  security->setAuthenticationMode(ESP_LE_AUTH_NO_BOND);
  security->setCapability(ESP_IO_CAP_NONE);
  security->setInitEncryptionKey(ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK);
}

String batteryPayload() {
  return "{\"battery_number\":\"" + battery_number + "\",\"tds_number\":\"" + tds_number + "\"}";
}

String batteryOnlyPayload() {
  return "{\"battery_number\":\"" + battery_number + "\"}";
}

void publishPayload(String payload) {
  if (pebblePayloadCharacteristic == nullptr) {
    return;
  }

  pebblePayloadCharacteristic->setValue(payload.c_str());

  if (deviceConnected) {
    pebblePayloadCharacteristic->notify();
  }
}

void publishBatteryOnlyPayload() {
  publishPayload(batteryOnlyPayload());
  Serial.print("Sent battery log to app: ");
  Serial.println(batteryOnlyPayload());
}

void publishBatteryNumber() {
  publishPayload(batteryPayload());
}

void updateBatteryNumber(String nextValue) {
  nextValue.trim();
  nextValue.replace("%", "");

  if (nextValue.length() == 0) {
    return;
  }

  battery_number = nextValue;
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

float readTdsVoltage() {
  long total = 0;

  for (int i = 0; i < TDS_SAMPLE_COUNT; i++) {
    total += analogRead(TDS_SENSOR_PIN);
    delay(10);
  }

  const float averageAdc = total / (float)TDS_SAMPLE_COUNT;
  return averageAdc * ADC_REFERENCE_VOLTAGE / ADC_RESOLUTION;
}

float calculateTdsPpm(float voltage, float temperatureC) {
  const float compensationCoefficient = 1.0 + 0.02 * (temperatureC - 25.0);
  const float compensatedVoltage = voltage / compensationCoefficient;

  // Common DFRobot-compatible TDS conversion curve for analog TDS modules.
  float tdsValue = (133.42 * compensatedVoltage * compensatedVoltage * compensatedVoltage
      - 255.86 * compensatedVoltage * compensatedVoltage
      + 857.39 * compensatedVoltage) * 0.5;

  if (tdsValue < 0) {
    tdsValue = 0;
  }

  return tdsValue;
}

void readAndPublishTdsNumber() {
  const float voltage = readTdsVoltage();
  const float tdsPpm = calculateTdsPpm(voltage, WATER_TEMPERATURE_C);

  tds_number = String((int)(tdsPpm + 0.5));
  showWaterQualityOnLedRing(tds_number.toInt());
  publishBatteryNumber();
}

void readBatteryNumberFromSerial() {
  if (!Serial.available()) {
    return;
  }

  String input = Serial.readStringUntil('\n');
  input.trim();

  const String prefix = "battery_number=";
  if (input.startsWith(prefix)) {
    updateBatteryNumber(input.substring(prefix.length()));
    return;
  }

  const String tdsPrefix = "tds_number=";
  if (input.startsWith(tdsPrefix)) {
    tds_number = input.substring(tdsPrefix.length());
    tds_number.trim();
    showWaterQualityOnLedRing(tds_number.toInt());
    publishBatteryNumber();
    return;
  }

  updateBatteryNumber(input);
}

void setupBle() {
  BLEDevice::init(DEVICE_NAME);
  setupOpenBleConnection();

  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new PebbleServerCallbacks());

  BLEService* pebbleService = server->createService(PEBBLE_SERVICE_UUID);

  pebblePayloadCharacteristic = pebbleService->createCharacteristic(
    PEBBLE_PAYLOAD_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pebblePayloadCharacteristic->addDescriptor(new BLE2902());

  pebbleService->start();

  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(PEBBLE_SERVICE_UUID);
  advertising->setScanResponse(true);
  advertising->setAppearance(0x00);
  advertising->setMinPreferred(0x06);
  advertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  publishBatteryNumber();
}

void setup() {
  Serial.begin(115200);
  Serial.setTimeout(50);
  analogReadResolution(12);
  pinMode(TDS_SENSOR_PIN, INPUT);
  ledRing.begin();
  ledRing.setBrightness(LED_RING_BRIGHTNESS);
  ledRing.clear();
  ledRing.show();
  setupBle();
  showWaterQualityOnLedRing(tds_number.toInt());

  Serial.println("Pebble ESP32 BLE bridge started.");
  Serial.print("BLE is advertising as ");
  Serial.println(DEVICE_NAME);
  Serial.print("Pebble service UUID: ");
  Serial.println(PEBBLE_SERVICE_UUID);
  Serial.print("Payload characteristic UUID: ");
  Serial.println(PEBBLE_PAYLOAD_UUID);
  Serial.println("No PIN or password is required. Confirm the connection prompt if Android shows one.");
  Serial.println("Send a battery value through Serial, for example:");
  Serial.println("battery_number=85");
  Serial.println("TDS is read from GPIO34 and sent as tds_number in ppm.");
  Serial.println("WS2812B LED ring reads DI from pin 6.");
  Serial.println("TDS <= 150: green/excellent, <= 300: yellow/good, > 300: red/poor.");
}

void loop() {
  readBatteryNumberFromSerial();

  const unsigned long now = millis();
  if (now - lastTdsReadAt >= TDS_READ_INTERVAL_MS) {
    lastTdsReadAt = now;
    readAndPublishTdsNumber();
  }

  if (deviceConnected && now - lastNotifyAt >= 5000) {
    lastNotifyAt = now;
    publishBatteryNumber();
  }
}
