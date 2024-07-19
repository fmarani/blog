---
title: "How to build a sensor for when I am at the computer"
date: "2024-07-19T22:52:44+02:00"
tags: ["hass"]
---

I started using this little utility called [HACompanion](https://github.com/tobias-kuendig/hacompanion) that can be configured with a [custom script](https://github.com/tobias-kuendig/hacompanion/discussions/28#discussion-5440242) that reads whether your monitor screen is locked or is not. 

I normally always force lock my screen when I leave my computer, so it is a good indicator for "when I am at the computer".

At the moment I am using this sensor to turn on a small lamp behind my monitor. I do that with an HA automation:

```
alias: Orange lamp on when computer unlocked
description: ""
trigger:
  - type: turned_off
    platform: device
    device_id: <computer_id>
    entity_id: <sensor_custom_script_id>
    domain: binary_sensor
condition:
  - condition: time
    after: "22:00:00"
    before: "02:00:00"
action:
  - type: turn_on
    device_id: <shelly_plug_id>
    entity_id: <turn_on_action_id>
    domain: switch
mode: single
```

I have another similar automation to turn it off. I have not managed yet to find an easy way to map both state transitions (on and off) with only one automation.
