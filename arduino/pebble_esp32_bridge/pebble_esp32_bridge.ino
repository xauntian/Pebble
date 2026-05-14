#include <Adafruit_NeoPixel.h>
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

// Pebble Nano ESP32 BLE bridge.
// Advertises the Pebble service consumed by the Flutter Bluetooth client.
// Sends battery_number heartbeats, charging state, and one-shot tds_number readings.
// The TDS input is treated as charging/idle while floating, and testing once
// a stable sensor value appears or changes.

static const char* DEVICE_NAME = "Pebble TestKit";

// Custom Pebble BLE service and characteristic UUIDs.
// Keep these values in sync with the Flutter Bluetooth client.
static const char* PEBBLE_SERVICE_UUID = "7b7d0001-4f8a-4c28-9f2a-6f0a8f0d1000";
static const char* PEBBLE_PAYLOAD_UUID = "7b7d0002-4f8a-4c28-9f2a-6f0a8f0d1000";

// TDS sensor analog output pin.
// GPIO34 is input-only and works well for ESP32 ADC sensor input.
static const int TDS_SENSOR_PIN = 34;
static const float ADC_REFERENCE_VOLTAGE = 3.3;
static const int ADC_RESOLUTION = 4095;
static const float WATER_TEMPERATURE_C = 25.0;
static const int TDS_SAMPLE_COUNT = 20;
static const int TDS_FLOATING_ADC_MAX = 80;
static const int TDS_VALID_ADC_MIN = 120;
static const int TDS_WINDOW_MAX_SAMPLES = 20;
static const unsigned long TDS_IDLE_READ_INTERVAL_MS = 250;
static const unsigned long TDS_WINDOW_SAMPLE_INTERVAL_MS = 250;
static const unsigned long TDS_SAMPLE_WINDOW_MS = 3000;
static const unsigned long LED_BLINK_INTERVAL_MS = 500;

// WS2812B 16-pixel RGB LED ring.
// Wiring: 5V -> 5V, DI -> GPIO6, GND -> GND.
static const int LED_RING_PIN = 6;
static const int LED_RING_COUNT = 16;
static const int LED_RING_BRIGHTNESS = 128; // 50% of 255.

// TDS water quality levels in ppm. Lower TDS is considered better here.
static const int TDS_EXCELLENT_MAX = 150;
static const int TDS_GOOD_MAX = 300;
static const int TDS_SENSOR_MAX = 1000;
static const uint8_t MIN_STATUS_SATURATION = 80;
static const uint8_t MAX_STATUS_SATURATION = 255;
static const unsigned long BLE_NOTIFY_INTERVAL_MS = 5000;
static const unsigned long FIRST_NOTIFY_DELAY_MS = 700;
static const unsigned long TDS_PAYLOAD_HOLD_MS = 1000;

BLECharacteristic* pebblePayloadCharacteristic = nullptr;
Adafruit_NeoPixel ledRing(LED_RING_COUNT, LED_RING_PIN, NEO_GRB + NEO_KHZ800);

enum DeviceState {
  DEVICE_CHARGING,
  DEVICE_SAMPLING,
  DEVICE_RESULT_HELD
};

DeviceState deviceState = DEVICE_CHARGING;
bool deviceConnected = false;
bool initialNotifyPending = false;
bool clearTdsPayloadPending = false;
bool charging = true;
String battery_number = "85";
String tds_number = "0";
unsigned long connectedAt = 0;
unsigned long lastNotifyAt = 0;
unsigned long lastTdsReadAt = 0;
unsigned long samplingStartedAt = 0;
unsigned long lastWindowSampleAt = 0;
unsigned long lastLedBlinkAt = 0;
unsigned long tdsPayloadPublishedAt = 0;
int lastPublishedTds = -1;
int tdsWindowSamples[TDS_WINDOW_MAX_SAMPLES];
int tdsWindowSampleCount = 0;
bool ledBlinkOn = true;

void enterChargingState(bool notifyConnected);
void resetTdsWindow();
void showChargingOnLedRing();
void showWaterQualityOnLedRing(int tdsValue);

String tdsPayload() {
  return "{\"battery_number\":\"" + battery_number
      + "\",\"charging\":" + String(charging ? "true" : "false")
      + ",\"tds_number\":\"" + tds_number + "\"}";
}

String batteryOnlyPayload() {
  return "{\"battery_number\":\"" + battery_number
      + "\",\"charging\":" + String(charging ? "true" : "false") + "}";
}

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
  clearTdsPayloadPending = false;
  publishPayload(batteryOnlyPayload(), notifyConnected);
}

void publishTdsPayload(bool notifyConnected = true) {
  publishPayload(tdsPayload(), notifyConnected);
  clearTdsPayloadPending = true;
  tdsPayloadPublishedAt = millis();
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
  deviceState = DEVICE_RESULT_HELD;
  tds_number = String(tdsValue);
  charging = false;
  lastPublishedTds = tdsValue;
  resetTdsWindow();
  showWaterQualityOnLedRing(tdsValue);
  publishTdsPayload();
}

void clearTdsNumber() {
  enterChargingState(true);
}

void showLedRingColor(uint32_t color) {
  const uint32_t correctedColor = ledRing.gamma32(color);

  for (int i = 0; i < LED_RING_COUNT; i++) {
    ledRing.setPixelColor(i, correctedColor);
  }

  ledRing.show();
}

void showLedRingOff() {
  ledRing.clear();
  ledRing.show();
}

void showChargingOnLedRing() {
  showLedRingColor(ledRing.Color(255, 255, 255));
}

void showSamplingOnLedRing() {
  showLedRingColor(ledRing.Color(255, 190, 0));
}

void showWaterQualityOnLedRing(int tdsValue) {
  if (tdsValue <= TDS_GOOD_MAX) {
    showLedRingColor(ledRing.Color(0, 255, 0));
  } else {
    showLedRingColor(ledRing.Color(255, 0, 0));
  }
}

void updateLedBlink(unsigned long now) {
  if (deviceState != DEVICE_CHARGING && deviceState != DEVICE_SAMPLING) {
    return;
  }

  if (now - lastLedBlinkAt < LED_BLINK_INTERVAL_MS) {
    return;
  }

  lastLedBlinkAt = now;
  ledBlinkOn = !ledBlinkOn;

  if (!ledBlinkOn) {
    showLedRingOff();
    return;
  }

  if (deviceState == DEVICE_CHARGING) {
    showChargingOnLedRing();
  } else {
    showSamplingOnLedRing();
  }
}

int readTdsRaw() {
  long total = 0;

  for (int i = 0; i < TDS_SAMPLE_COUNT; i++) {
    total += analogRead(TDS_SENSOR_PIN);
    delay(5);
  }

  return total / TDS_SAMPLE_COUNT;
}

float calculateTdsPpmFromRaw(int rawAdc) {
  const float voltage = rawAdc * ADC_REFERENCE_VOLTAGE / ADC_RESOLUTION;
  const float compensationCoefficient = 1.0 + 0.02 * (WATER_TEMPERATURE_C - 25.0);
  const float compensatedVoltage = voltage / compensationCoefficient;

  float tdsValue = (133.42 * compensatedVoltage * compensatedVoltage * compensatedVoltage
      - 255.86 * compensatedVoltage * compensatedVoltage
      + 857.39 * compensatedVoltage) * 0.5;

  if (tdsValue < 0) {
    tdsValue = 0;
  }

  return tdsValue;
}

bool isTdsFloating(int rawAdc) {
  return rawAdc <= TDS_FLOATING_ADC_MAX;
}

bool isTdsValid(int rawAdc) {
  return rawAdc >= TDS_VALID_ADC_MIN;
}

void resetTdsWindow() {
  tdsWindowSampleCount = 0;
}

void addTdsWindowSample(int rawAdc) {
  if (tdsWindowSampleCount >= TDS_WINDOW_MAX_SAMPLES) {
    return;
  }

  tdsWindowSamples[tdsWindowSampleCount] =
      (int)(calculateTdsPpmFromRaw(rawAdc) + 0.5);
  tdsWindowSampleCount++;
}

int trustedTdsWindowValue() {
  if (tdsWindowSampleCount == 0) {
    return 0;
  }

  long total = 0;
  int lowest = tdsWindowSamples[0];
  int highest = tdsWindowSamples[0];

  for (int i = 0; i < tdsWindowSampleCount; i++) {
    const int value = tdsWindowSamples[i];
    total += value;
    lowest = min(lowest, value);
    highest = max(highest, value);
  }

  if (tdsWindowSampleCount > 2) {
    total -= lowest;
    total -= highest;
    return (int)((total + (tdsWindowSampleCount - 2) / 2) / (tdsWindowSampleCount - 2));
  }

  return (int)((total + tdsWindowSampleCount / 2) / tdsWindowSampleCount);
}

void enterChargingState(bool notifyConnected = true) {
  deviceState = DEVICE_CHARGING;
  charging = true;
  tds_number = "0";
  lastPublishedTds = -1;
  resetTdsWindow();
  clearTdsPayloadPending = false;
  ledBlinkOn = true;
  lastLedBlinkAt = millis();
  showChargingOnLedRing();

  if (notifyConnected) {
    publishBatteryOnlyPayload();
  }
}

void enterSamplingState(int rawAdc, unsigned long now) {
  deviceState = DEVICE_SAMPLING;
  charging = false;
  clearTdsPayloadPending = false;
  samplingStartedAt = now;
  lastWindowSampleAt = now;
  ledBlinkOn = true;
  lastLedBlinkAt = now;
  resetTdsWindow();
  addTdsWindowSample(rawAdc);
  showSamplingOnLedRing();
  publishBatteryOnlyPayload();

  Serial.print("TDS sampling started, raw ADC: ");
  Serial.println(rawAdc);
}

void finishTdsSampling() {
  const int tdsValue = trustedTdsWindowValue();

  deviceState = DEVICE_RESULT_HELD;
  charging = false;
  tds_number = String(tdsValue);
  lastPublishedTds = tdsValue;
  showWaterQualityOnLedRing(tdsValue);
  publishTdsPayload();

  Serial.print("TDS sampling complete, samples: ");
  Serial.print(tdsWindowSampleCount);
  Serial.print(", trusted ppm: ");
  Serial.println(tdsValue);
}

void updateTdsSensor(unsigned long now) {
  if (now - lastTdsReadAt < TDS_IDLE_READ_INTERVAL_MS) {
    return;
  }

  lastTdsReadAt = now;
  const int rawAdc = readTdsRaw();

  if (isTdsFloating(rawAdc)) {
    if (deviceState != DEVICE_CHARGING) {
      enterChargingState();
    }
    return;
  }

  if (deviceState == DEVICE_CHARGING) {
    if (isTdsValid(rawAdc)) {
      enterSamplingState(rawAdc, now);
    }
    return;
  }

  if (deviceState == DEVICE_SAMPLING) {
    if (now - lastWindowSampleAt >= TDS_WINDOW_SAMPLE_INTERVAL_MS) {
      lastWindowSampleAt = now;
      addTdsWindowSample(rawAdc);
    }

    if (now - samplingStartedAt >= TDS_SAMPLE_WINDOW_MS) {
      finishTdsSampling();
    }
  }
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

  if (command == "clear_tds" || command == "clear_tds_number") {
    clearTdsNumber();
    return;
  }

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
  showChargingOnLedRing();
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
  analogReadResolution(12);
  pinMode(TDS_SENSOR_PIN, INPUT);
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
  Serial.println("TDS is read from GPIO34.");
  Serial.println("Floating or low TDS ADC reads as charging/idle.");
  Serial.println("A valid TDS ADC value starts one sampling window, then publishes one tds_number.");
  Serial.println("The next test waits until TDS returns to charging/idle first.");
  Serial.println("You can still send manual TDS through Serial, for example:");
  Serial.println("123");
  Serial.println("tds=123");
  Serial.println("tds_number=123");
  Serial.println("Send battery through Serial, for example:");
  Serial.println("battery_number=85");
  Serial.println("Manual TDS is sent only once when you type a value in Serial Monitor.");
  Serial.println("Type clear_tds to clear a stale manual TDS value.");
  Serial.println("WS2812B LED ring reads DI from GPIO6.");
  Serial.println("LED: charging white blink, testing yellow blink, normal green, abnormal red.");
}

void loop() {
  readSerialCommand();

  const unsigned long now = millis();
  updateTdsSensor(now);
  updateLedBlink(now);

  if (initialNotifyPending && now - connectedAt >= FIRST_NOTIFY_DELAY_MS) {
    initialNotifyPending = false;
    publishBatteryOnlyPayload();
  }

  if (clearTdsPayloadPending && now - tdsPayloadPublishedAt >= TDS_PAYLOAD_HOLD_MS) {
    publishBatteryOnlyPayload(false);
  }

  if (deviceConnected && now - lastNotifyAt >= BLE_NOTIFY_INTERVAL_MS) {
    lastNotifyAt = now;
    publishBatteryOnlyPayload();
  }
}
