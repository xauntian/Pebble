#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

// Pebble serial-to-BLE test sketch.
// Type a TDS value in Serial Monitor to notify the Flutter app.

static const char* DEVICE_NAME = "Pebble TestKit";
static const char* PEBBLE_SERVICE_UUID = "7b7d0001-4f8a-4c28-9f2a-6f0a8f0d1000";
static const char* PEBBLE_PAYLOAD_UUID = "7b7d0002-4f8a-4c28-9f2a-6f0a8f0d1000";

BLECharacteristic* pebblePayloadCharacteristic = nullptr;
bool deviceConnected = false;
String battery_number = "85";
String tds_number = "0";

void publishPayload();
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
  BLESecurity* security = new BLESecurity();
  security->setAuthenticationMode(ESP_LE_AUTH_NO_BOND);
  security->setCapability(ESP_IO_CAP_NONE);
  security->setInitEncryptionKey(ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK);
}

String payload() {
  return "{\"battery_number\":\"" + battery_number + "\",\"tds_number\":\"" + tds_number + "\"}";
}

String batteryOnlyPayload() {
  return "{\"battery_number\":\"" + battery_number + "\"}";
}

void publishPayloadText(String nextPayload) {
  if (pebblePayloadCharacteristic == nullptr) {
    return;
  }

  pebblePayloadCharacteristic->setValue(nextPayload.c_str());

  if (deviceConnected) {
    pebblePayloadCharacteristic->notify();
  }

  Serial.print("Sent to app: ");
  Serial.println(nextPayload);
}

void publishPayload() {
  publishPayloadText(payload());
}

void publishBatteryOnlyPayload() {
  publishPayloadText(batteryOnlyPayload());
}

String tdsValueFromSerialInput(String input) {
  input.trim();

  const String tdsNumberPrefix = "tds_number=";
  if (input.startsWith(tdsNumberPrefix)) {
    input = input.substring(tdsNumberPrefix.length());
  }

  const String tdsPrefix = "tds=";
  if (input.startsWith(tdsPrefix)) {
    input = input.substring(tdsPrefix.length());
  }

  input.trim();
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

void readTdsFromSerial() {
  if (!Serial.available()) {
    return;
  }

  String input = Serial.readStringUntil('\n');
  String nextTds = tdsValueFromSerialInput(input);

  if (!isNumericTdsValue(nextTds)) {
    Serial.print("Ignored invalid TDS input: ");
    Serial.println(input);
    Serial.println("Use a number, tds=123, or tds_number=123.");
    return;
  }

  tds_number = nextTds;
  publishPayload();
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

  publishPayload();
}

void setup() {
  Serial.begin(115200);
  Serial.setTimeout(50);
  setupBle();

  Serial.println("Pebble BLE serial TDS test started.");
  Serial.print("BLE is advertising as ");
  Serial.println(DEVICE_NAME);
  Serial.println("Type a TDS number and press Enter.");
  Serial.println("Examples: 123, tds=123, tds_number=123");
}

void loop() {
  readTdsFromSerial();
}
