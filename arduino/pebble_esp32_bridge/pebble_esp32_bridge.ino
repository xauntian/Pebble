#include <Adafruit_NeoPixel.h>
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <WebServer.h>
#include <WiFi.h>

// Pebble Nano ESP32 WiFi-to-BLE bridge.
// A computer joins this board's WiFi AP, submits a TDS value over HTTP, and the
// board forwards the value to the Flutter app over the existing BLE payload.

static const char* DEVICE_NAME = "Pebble TestKit";

// Custom Pebble BLE service and characteristic UUIDs.
// Keep these values in sync with the Flutter Bluetooth client.
static const char* PEBBLE_SERVICE_UUID = "7b7d0001-4f8a-4c28-9f2a-6f0a8f0d1000";
static const char* PEBBLE_PAYLOAD_UUID = "7b7d0002-4f8a-4c28-9f2a-6f0a8f0d1000";

// WiFi AP shown to the audience-control computer.
static const char* WIFI_AP_SSID = "Pebble-TDS";
static const char* WIFI_AP_PASSWORD = "pebbletds";
IPAddress wifiApIp(192, 168, 4, 1);
IPAddress wifiApGateway(192, 168, 4, 1);
IPAddress wifiApSubnet(255, 255, 255, 0);

// WS2812B 16-bit RGB LED ring.
// Known-good data pin from arduino/testled/testled.ino:
// Arduino Nano ESP32 physical A1 is ESP32 GPIO2. Use the raw GPIO number here
// because Adafruit_NeoPixel's ESP32 RMT driver does not follow Nano ESP32
// Arduino-pin remapping when sending data.
static const int LED_RING_PIN = 2;
static const int LED_RING_COUNT = 16;
static const int LED_RING_BRIGHTNESS = 80;
static const unsigned long LED_YELLOW_BLINK_DURATION_MS = 2000;
static const unsigned long LED_RESULT_DURATION_MS = 4000;
static const unsigned long LED_BLINK_INTERVAL_MS = 180;
static const uint8_t BLE_TDS_NOTIFY_REPEAT_COUNT = 5;
static const unsigned long BLE_TDS_NOTIFY_REPEAT_INTERVAL_MS = 300;
static const unsigned long BLE_TDS_RETAIN_DURATION_MS = 2000;

// TDS water quality levels in ppm. Lower TDS is considered better here.
static const int TDS_EXCELLENT_MAX = 150;
static const int TDS_GOOD_MAX = 300;
static const int TDS_SENSOR_MAX = 1000;
static const int TDS_INPUT_MAX = 2000;
static const uint8_t MIN_STATUS_SATURATION = 80;
static const uint8_t MAX_STATUS_SATURATION = 255;

BLECharacteristic* pebblePayloadCharacteristic = nullptr;
Adafruit_NeoPixel* ledRing = nullptr;
WebServer webServer(80);
bool deviceConnected = false;
String battery_number = "85";
String tds_number = "0";
String tds_timestamp = "0";

enum LedSequencePhase {
  LED_SEQUENCE_IDLE,
  LED_SEQUENCE_YELLOW_BLINK,
  LED_SEQUENCE_RESULT
};

LedSequencePhase ledSequencePhase = LED_SEQUENCE_IDLE;
unsigned long ledPhaseStartedAt = 0;
unsigned long ledSequenceEndsAt = 0;
unsigned long ledLastBlinkAt = 0;
bool ledBlinkIsOn = false;
int ledResultTdsValue = 0;
bool shouldRestoreBatteryOnlyPayload = false;
unsigned long restoreBatteryOnlyPayloadAt = 0;
unsigned long lastPublishedTdsTimestampSeconds = 0;
bool hasPublishedTdsTimestamp = false;
String pendingTdsNotifyPayload = "";
uint8_t pendingTdsNotifyRepeats = 0;
unsigned long nextTdsNotifyRepeatAt = 0;

const char INDEX_HTML[] PROGMEM = R"rawliteral(
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pebble TDS Control</title>
  <style>
    :root {
      color-scheme: light;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #f5fbef;
      color: #132525;
    }
    * {
      box-sizing: border-box;
    }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      padding: 24px;
      background:
        linear-gradient(135deg, rgba(104, 218, 31, 0.22), rgba(255, 255, 255, 0.42) 42%, rgba(174, 202, 105, 0.24)),
        #f5fbef;
    }
    main {
      width: min(560px, 100%);
      background: rgba(255, 255, 255, 0.58);
      border: 1px solid rgba(255, 255, 255, 0.66);
      border-radius: 20px;
      box-shadow: 0 18px 52px rgba(76, 124, 9, 0.16);
      backdrop-filter: blur(18px);
      -webkit-backdrop-filter: blur(18px);
      padding: 28px;
    }
    h1 {
      margin: 0 0 8px;
      font-size: 30px;
      line-height: 1.15;
      letter-spacing: 0;
    }
    p {
      margin: 0 0 22px;
      color: #355051;
      font-size: 15px;
      line-height: 1.45;
    }
    form {
      display: grid;
      gap: 14px;
    }
    label {
      display: grid;
      gap: 8px;
      font-size: 14px;
      font-weight: 700;
      color: #355051;
    }
    input {
      width: 100%;
      min-height: 56px;
      border: 1px solid rgba(76, 124, 9, 0.18);
      border-radius: 16px;
      padding: 0 14px;
      font-size: 24px;
      color: #132525;
      background: rgba(255, 255, 255, 0.72);
      outline: none;
    }
    input:focus {
      border-color: rgba(76, 124, 9, 0.44);
      box-shadow: 0 0 0 4px rgba(104, 218, 31, 0.16);
    }
    button {
      min-height: 52px;
      border: 0;
      border-radius: 999px;
      font-size: 17px;
      font-weight: 800;
      color: #ffffff;
      background: #4c7c09;
      box-shadow: 0 10px 22px rgba(76, 124, 9, 0.22);
      cursor: pointer;
    }
    button:disabled {
      cursor: progress;
      opacity: 0.7;
    }
    .chips {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 8px;
      margin-top: 10px;
    }
    .chips button {
      min-height: 42px;
      color: #132525;
      background: rgba(255, 255, 255, 0.68);
      border: 1px solid rgba(76, 124, 9, 0.12);
      box-shadow: none;
      font-size: 15px;
    }
    output {
      display: block;
      min-height: 26px;
      margin-top: 18px;
      font-size: 15px;
      color: #355051;
    }
    .ok {
      color: #4c7c09;
      font-weight: 800;
    }
    .error {
      color: #b3261e;
      font-weight: 800;
    }
  </style>
</head>
<body>
  <main>
    <h1>Pebble TDS Control</h1>
    <p>Send one TDS result to the paired phone.</p>
    <form id="tds-form">
      <label for="tds">TDS value, ppm
        <input id="tds" name="tds" type="number" inputmode="numeric" min="0" max="2000" step="1" placeholder="123" required>
      </label>
      <button id="submit" type="submit">Send report to phone</button>
    </form>
    <div class="chips" aria-label="Quick values">
      <button type="button" data-value="75">75</button>
      <button type="button" data-value="150">150</button>
      <button type="button" data-value="300">300</button>
      <button type="button" data-value="600">600</button>
    </div>
    <output id="status">Connect this computer to WiFi Pebble-TDS, then submit a value.</output>
  </main>
  <script>
    const endpoint = location.protocol === "file:" ? "http://192.168.4.1/tds" : "/tds";
    const form = document.getElementById("tds-form");
    const input = document.getElementById("tds");
    const submit = document.getElementById("submit");
    const status = document.getElementById("status");
    let isSubmitting = false;

    document.querySelectorAll("[data-value]").forEach((button) => {
      button.addEventListener("click", () => {
        input.value = button.dataset.value;
        input.focus();
      });
    });

    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      if (isSubmitting) return;

      const value = input.value.trim();
      isSubmitting = true;
      submit.disabled = true;
      status.className = "";
      status.textContent = "Sending...";

      try {
        const response = await fetch(endpoint, {
          method: "POST",
          headers: {"Content-Type": "application/x-www-form-urlencoded"},
          body: new URLSearchParams({
            tds: value,
            tds_timestamp: Math.floor(Date.now() / 1000).toString()
          })
        });
        const result = await response.json();
        if (!response.ok || !result.ok) {
          throw new Error(result.error || "Send failed");
        }
        status.className = "ok";
        status.textContent = `Sent ${result.tds_number} ppm. Phone connected: ${result.ble_connected ? "yes" : "no"}.`;
      } catch (error) {
        status.className = "error";
        status.textContent = `${error.message}. Check WiFi Pebble-TDS and open http://192.168.4.1/.`;
      } finally {
        isSubmitting = false;
        submit.disabled = false;
      }
    });
  </script>
</body>
</html>
)rawliteral";

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

String payload() {
  return "{\"battery_number\":\"" + battery_number
      + "\",\"tds_number\":\"" + tds_number
      + "\",\"tds_timestamp\":\"" + tds_timestamp + "\"}";
}

String batteryOnlyPayload() {
  return "{\"battery_number\":\"" + battery_number + "\"}";
}

String stateJson() {
  return "{\"ok\":true,\"battery_number\":\"" + battery_number
      + "\",\"tds_number\":\"" + tds_number
      + "\",\"tds_timestamp\":\"" + tds_timestamp
      + "\",\"ble_connected\":" + String(deviceConnected ? "true" : "false")
      + ",\"wifi_ssid\":\"" + WIFI_AP_SSID
      + "\",\"wifi_ip\":\"" + WiFi.softAPIP().toString()
      + "\",\"wifi_clients\":" + String(WiFi.softAPgetStationNum()) + "}";
}

void publishPayloadText(const String& nextPayload) {
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
  pendingTdsNotifyPayload = payload();
  publishPayloadText(pendingTdsNotifyPayload);
  pendingTdsNotifyRepeats = BLE_TDS_NOTIFY_REPEAT_COUNT > 0
      ? BLE_TDS_NOTIFY_REPEAT_COUNT - 1
      : 0;
  nextTdsNotifyRepeatAt = millis() + BLE_TDS_NOTIFY_REPEAT_INTERVAL_MS;

  // Retry the same timestamped payload briefly so the phone can tolerate a
  // missed BLE notify packet, then restore a battery-only readable value.
  shouldRestoreBatteryOnlyPayload = true;
  restoreBatteryOnlyPayloadAt = millis() + BLE_TDS_RETAIN_DURATION_MS;
}

void repeatTdsPayloadIfNeeded() {
  if (pendingTdsNotifyRepeats == 0 ||
      pendingTdsNotifyPayload.length() == 0 ||
      pebblePayloadCharacteristic == nullptr) {
    return;
  }

  if ((long)(millis() - nextTdsNotifyRepeatAt) < 0) {
    return;
  }

  publishPayloadText(pendingTdsNotifyPayload);
  pendingTdsNotifyRepeats--;
  nextTdsNotifyRepeatAt = millis() + BLE_TDS_NOTIFY_REPEAT_INTERVAL_MS;
}

void publishBatteryOnlyPayload() {
  if (pebblePayloadCharacteristic == nullptr) {
    return;
  }

  const String retainedPayload = batteryOnlyPayload();
  pebblePayloadCharacteristic->setValue(retainedPayload.c_str());

  Serial.print("Set app-readable payload: ");
  Serial.println(retainedPayload);
}

void restoreBatteryOnlyPayloadIfNeeded() {
  if (!shouldRestoreBatteryOnlyPayload || pebblePayloadCharacteristic == nullptr) {
    return;
  }

  if ((long)(millis() - restoreBatteryOnlyPayloadAt) < 0) {
    return;
  }

  shouldRestoreBatteryOnlyPayload = false;
  pendingTdsNotifyRepeats = 0;
  pendingTdsNotifyPayload = "";
  const String retainedPayload = batteryOnlyPayload();
  pebblePayloadCharacteristic->setValue(retainedPayload.c_str());
}

void addCorsHeaders() {
  webServer.sendHeader("Access-Control-Allow-Origin", "*");
  webServer.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  webServer.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

void sendJson(int statusCode, const String& body) {
  addCorsHeaders();
  webServer.send(statusCode, "application/json", body);
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

bool firstIntegerFromText(const String& text, String& output) {
  output = "";

  for (int i = 0; i < text.length(); i++) {
    if (!isDigit(text.charAt(i))) {
      continue;
    }

    while (i < text.length() && isDigit(text.charAt(i))) {
      output += text.charAt(i);
      i++;
    }

    return output.length() > 0;
  }

  return false;
}

String normalizeTdsInput(String input) {
  input.trim();
  input.replace("ppm", "");
  input.replace("PPM", "");
  input.trim();

  const String tdsNumberPrefix = "tds_number=";
  if (input.startsWith(tdsNumberPrefix)) {
    input = input.substring(tdsNumberPrefix.length());
  }

  const String tdsPrefix = "tds=";
  if (input.startsWith(tdsPrefix)) {
    input = input.substring(tdsPrefix.length());
  }

  const String valuePrefix = "value=";
  if (input.startsWith(valuePrefix)) {
    input = input.substring(valuePrefix.length());
  }

  input.trim();

  if (isNumericTdsValue(input)) {
    return input;
  }

  String extractedValue;
  if (firstIntegerFromText(input, extractedValue)) {
    return extractedValue;
  }

  return "";
}

bool parseTdsValue(String input, int& tdsValue) {
  const String normalized = normalizeTdsInput(input);

  if (!isNumericTdsValue(normalized)) {
    return false;
  }

  const long parsed = normalized.toInt();
  if (parsed < 0 || parsed > TDS_INPUT_MAX) {
    return false;
  }

  tdsValue = (int)parsed;
  return true;
}

bool tdsValueFromRequest(int& tdsValue) {
  if (webServer.hasArg("tds") && parseTdsValue(webServer.arg("tds"), tdsValue)) {
    return true;
  }

  if (webServer.hasArg("tds_number") && parseTdsValue(webServer.arg("tds_number"), tdsValue)) {
    return true;
  }

  if (webServer.hasArg("value") && parseTdsValue(webServer.arg("value"), tdsValue)) {
    return true;
  }

  if (webServer.hasArg("plain") && parseTdsValue(webServer.arg("plain"), tdsValue)) {
    return true;
  }

  return false;
}

unsigned long timestampFromRequest() {
  String value = "";
  if (webServer.hasArg("tds_timestamp")) {
    value = webServer.arg("tds_timestamp");
  } else if (webServer.hasArg("timestamp")) {
    value = webServer.arg("timestamp");
  } else if (webServer.hasArg("ts")) {
    value = webServer.arg("ts");
  }

  value.trim();
  if (value.length() > 0 && isNumericTdsValue(value)) {
    return strtoul(value.c_str(), nullptr, 10);
  }

  return millis() / 1000;
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

  if (ledRing == nullptr) {
    return 0;
  }

  return ledRing->ColorHSV(hue, saturation, 255);
}

void showLedRingColor(uint32_t color) {
  if (ledRing == nullptr) {
    return;
  }

  for (int i = 0; i < LED_RING_COUNT; i++) {
    ledRing->setPixelColor(i, color);
  }

  ledRing->show();
}

void showWaterQualityOnLedRing(int tdsValue) {
  if (ledRing == nullptr) {
    return;
  }

  showLedRingColor(ledRing->gamma32(waterQualityColor(tdsValue)));
}

void showYellowBlinkOnLedRing() {
  if (ledRing == nullptr) {
    return;
  }

  showLedRingColor(ledRing->gamma32(ledRing->Color(255, 190, 0)));
}

void clearLedRing() {
  if (ledRing == nullptr) {
    return;
  }

  ledRing->clear();
  ledRing->show();
}

void startLedTestSequence(int tdsValue) {
  ledResultTdsValue = tdsValue;
  ledSequencePhase = LED_SEQUENCE_YELLOW_BLINK;
  ledPhaseStartedAt = millis();
  ledSequenceEndsAt = ledPhaseStartedAt + LED_YELLOW_BLINK_DURATION_MS + LED_RESULT_DURATION_MS;
  ledLastBlinkAt = 0;
  ledBlinkIsOn = false;
  clearLedRing();
}

void updateLedTestSequence() {
  if (ledSequencePhase == LED_SEQUENCE_IDLE) {
    return;
  }

  const unsigned long now = millis();

  if ((long)(now - ledSequenceEndsAt) >= 0) {
    ledSequencePhase = LED_SEQUENCE_IDLE;
    clearLedRing();
    return;
  }

  if (ledSequencePhase == LED_SEQUENCE_YELLOW_BLINK) {
    if (now - ledPhaseStartedAt >= LED_YELLOW_BLINK_DURATION_MS) {
      ledSequencePhase = LED_SEQUENCE_RESULT;
      ledPhaseStartedAt = now;
      showWaterQualityOnLedRing(ledResultTdsValue);
      return;
    }

    if (ledLastBlinkAt == 0 || now - ledLastBlinkAt >= LED_BLINK_INTERVAL_MS) {
      ledLastBlinkAt = now;
      ledBlinkIsOn = !ledBlinkIsOn;
      if (ledBlinkIsOn) {
        showYellowBlinkOnLedRing();
      } else {
        clearLedRing();
      }
    }

    return;
  }

  if (ledSequencePhase == LED_SEQUENCE_RESULT &&
      now - ledPhaseStartedAt >= LED_RESULT_DURATION_MS) {
    ledSequencePhase = LED_SEQUENCE_IDLE;
    clearLedRing();
  }
}

bool updateTdsNumber(int nextTds, unsigned long timestampSeconds, const char* source) {
  if (hasPublishedTdsTimestamp &&
      lastPublishedTdsTimestampSeconds == timestampSeconds) {
    Serial.print("Ignored duplicate TDS report in second ");
    Serial.println(timestampSeconds);
    return false;
  }

  hasPublishedTdsTimestamp = true;
  lastPublishedTdsTimestampSeconds = timestampSeconds;
  tds_timestamp = String(timestampSeconds);
  tds_number = String(nextTds);
  startLedTestSequence(nextTds);
  publishPayload();

  Serial.print("TDS report from ");
  Serial.print(source);
  Serial.print(": ");
  Serial.print(tds_number);
  Serial.print(" ppm, timestamp: ");
  Serial.print(tds_timestamp);
  Serial.print(", BLE connected: ");
  Serial.println(deviceConnected ? "yes" : "no");
  return true;
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

void handleRoot() {
  addCorsHeaders();
  webServer.send_P(200, "text/html", INDEX_HTML);
}

void handleStatus() {
  sendJson(200, stateJson());
}

void handleTdsOptions() {
  addCorsHeaders();
  webServer.send(204);
}

void handleTdsGet() {
  sendJson(405, "{\"ok\":false,\"error\":\"Send TDS values with POST only.\"}");
}

void handleTdsSubmit() {
  int nextTds = 0;
  if (!tdsValueFromRequest(nextTds)) {
    sendJson(400, "{\"ok\":false,\"error\":\"Use a whole-number TDS value from 0 to 2000.\"}");
    return;
  }

  if (!updateTdsNumber(nextTds, timestampFromRequest(), "wifi")) {
    sendJson(429, "{\"ok\":false,\"error\":\"Only one TDS report can be generated per second.\"}");
    return;
  }

  sendJson(200, stateJson());
}

void handleNotFound() {
  if (webServer.method() == HTTP_OPTIONS) {
    handleTdsOptions();
    return;
  }

  sendJson(404, "{\"ok\":false,\"error\":\"Not found.\"}");
}

void readCommandFromSerial() {
  if (!Serial.available()) {
    return;
  }

  String input = Serial.readStringUntil('\n');
  input.trim();

  const String batteryPrefix = "battery_number=";
  if (input.startsWith(batteryPrefix)) {
    updateBatteryNumber(input.substring(batteryPrefix.length()));
    return;
  }

  int nextTds = 0;
  if (!parseTdsValue(input, nextTds)) {
    Serial.print("Ignored invalid input: ");
    Serial.println(input);
    Serial.println("Use a number, tds=123, tds_number=123, or battery_number=85.");
    return;
  }

  updateTdsNumber(nextTds, millis() / 1000, "serial");
}

void setupBle() {
  BLEDevice::init(DEVICE_NAME);

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

  publishBatteryOnlyPayload();
}

void setupWifiAp() {
  WiFi.persistent(false);
  WiFi.mode(WIFI_AP);
  WiFi.setSleep(false);
  WiFi.softAPConfig(wifiApIp, wifiApGateway, wifiApSubnet);
  const bool started = WiFi.softAP(WIFI_AP_SSID, WIFI_AP_PASSWORD);

  Serial.print("WiFi AP ");
  Serial.print(WIFI_AP_SSID);
  Serial.println(started ? " started." : " failed to start.");
  Serial.print("WiFi password: ");
  Serial.println(WIFI_AP_PASSWORD);
  Serial.print("Open page: http://");
  Serial.println(WiFi.softAPIP());
}

void setupWebServer() {
  webServer.on("/", HTTP_GET, handleRoot);
  webServer.on("/status", HTTP_GET, handleStatus);
  webServer.on("/tds", HTTP_OPTIONS, handleTdsOptions);
  webServer.on("/tds", HTTP_GET, handleTdsGet);
  webServer.on("/tds", HTTP_POST, handleTdsSubmit);
  webServer.onNotFound(handleNotFound);
  webServer.begin();
}

void setup() {
  Serial.begin(115200);
  Serial.setTimeout(50);
  Serial.println();
  Serial.println("Pebble Nano ESP32 booting.");

  setupWifiAp();
  setupWebServer();

  ledRing = new Adafruit_NeoPixel(LED_RING_COUNT, LED_RING_PIN, NEO_GRB + NEO_KHZ800);
  ledRing->begin();
  ledRing->setBrightness(LED_RING_BRIGHTNESS);
  clearLedRing();

  setupBle();

  Serial.println("Pebble Nano ESP32 WiFi-to-BLE bridge started.");
  Serial.print("BLE is advertising as ");
  Serial.println(DEVICE_NAME);
  Serial.print("Pebble service UUID: ");
  Serial.println(PEBBLE_SERVICE_UUID);
  Serial.print("Payload characteristic UUID: ");
  Serial.println(PEBBLE_PAYLOAD_UUID);
  Serial.println("Submit TDS from the web page, or type a number in Serial Monitor.");
  Serial.println("WS2812B LED ring DI uses the known-good Nano A1 / ESP32 GPIO2 pin.");
}

void loop() {
  webServer.handleClient();
  readCommandFromSerial();
  updateLedTestSequence();
  repeatTdsPayloadIfNeeded();
  restoreBatteryOnlyPayloadIfNeeded();
}
