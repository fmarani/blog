---
title: "HomeAssistant can control text in LCD screens"
date: "2024-06-09T13:28:41+02:00"
tags: ["hass"]
---

I have a little LCD screen wired up to a ESP32 on my desk. It tells me the temperature/humidity inside and outside the house. It is relatively useful but I wanted to do a bit more with it. 

The text is controlled on the device itself. I wanted the ability to override the message remotely somehow.

![My little temperature indicator](/attachments/esp8266-lcd.png)

HASS has the ability to create Helpers, which are like virtual devices, of many kinds. They can be created in the "Devices and services" section in the Settings.

There is a Text component helper, which can contain a string in its state, that I added to control the LCD remotely. That is how it looks when it is visible on the main HASS dashboard.

![Helpers in Dashboard](/attachments/hass-text-helper.png)

The ESP32 is running ESPHome, which is quite an amazing little utility. ESPHome has done all the heavy-lifting already when it comes to write microcontroller code, and it integrates with HASS already. You just need to add a bit of YAML to represent your program and push it to the device.

I have added the text_sensor piece, connected to the helper, and an extra if statement in the lambda function to conditionally display it.

```yaml
esphome:
  name: esp32-1
  platform: ESP32
  board: esp-wrover-kit

# Enable Home Assistant API
api:

wifi:
  ssid: "yourwifi"
  password: "yourpassword"

sensor:
  - platform: homeassistant
    id: outside_temp
    entity_id: weather.home
    attribute: temperature
  - platform: homeassistant
    id: outside_humidity
    entity_id: weather.home
    attribute: humidity
  - platform: dht
    pin: GPIO26
    temperature:
      name: "Room Temperature"
      id: inside_temp
    humidity:
      name: "Room Humidity"
      id: inside_humidity
    update_interval: 60s

text_sensor:
  - platform: homeassistant
    id: lcd_display_computer
    entity_id: input_text.lcd_display_desktop

i2c:
  sda: 21
  scl: 22

display:
  - platform: lcd_pcf8574
    dimensions: 16x2
    address: 0x27
    lambda: |-
      if (strcmp(id(lcd_display_computer).state.c_str(), "")) {
        it.printf(0, 0, "%s", id(lcd_display_computer).state.c_str());
      } else {
        it.printf(0, 0, "Out: %.1f / %g", id(outside_temp).state, id(outside_humidity).state);
        it.printf(0, 1, "In : %.1f / %g", id(inside_temp).state, id(inside_humidity).state);
      }
```

Here's how it looks with a string:

![String override](/attachments/esp8266-lcd-2.png)
