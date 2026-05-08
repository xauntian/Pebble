#include <Adafruit_NeoPixel.h>

// Arduino Nano ESP32 physical A1 is ESP32 GPIO2.
// Use the raw GPIO number here because Adafruit_NeoPixel's ESP32 RMT driver
// does not follow the Nano ESP32 Arduino-pin remap when sending data.
static const int LED_PIN = 2;

// Update this if your WS2812 strip/ring has a different number of LEDs.
static const int LED_COUNT = 16;
static const int LED_BRIGHTNESS = 80;

Adafruit_NeoPixel pixels(LED_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800);

void fillPixels(uint32_t color) {
  for (int i = 0; i < LED_COUNT; i++) {
    pixels.setPixelColor(i, color);
  }

  pixels.show();
}

void showColor(uint32_t color, unsigned long holdMs) {
  fillPixels(color);
  delay(holdMs);
}

void breathe(uint32_t color) {
  for (int brightness = 5; brightness <= LED_BRIGHTNESS; brightness += 5) {
    pixels.setBrightness(brightness);
    fillPixels(color);
    delay(25);
  }

  for (int brightness = LED_BRIGHTNESS; brightness >= 5; brightness -= 5) {
    pixels.setBrightness(brightness);
    fillPixels(color);
    delay(25);
  }
}

void setup() {
  pixels.begin();
  pixels.setBrightness(LED_BRIGHTNESS);
  pixels.clear();
  pixels.show();

  // Quick power/data check: all LEDs should turn white after upload.
  showColor(pixels.Color(255, 255, 255), 1000);
}

void loop() {
  pixels.setBrightness(LED_BRIGHTNESS);
  showColor(pixels.Color(255, 0, 0), 700);
  showColor(pixels.Color(0, 255, 0), 700);
  showColor(pixels.Color(0, 0, 255), 700);
  breathe(pixels.Color(0, 180, 255));
}
