---
marp: true
theme: default
class: invert
paginate: true
size: 16:9
style: |
  section { font-size: 28px; }
  h1 { font-size: 56px; color: #fcd34d; }
  h2 { font-size: 42px; color: #60a5fa; }
  code { background: #1f2937; padding: 2px 6px; border-radius: 4px; }
---

# Week 11 — Advanced Web Platform
## WebRTC · USB · Bluetooth · Camera

---

# What you'll know after this

1. **WebRTC** peer-connection lifecycle + what data channels carry
2. Connect to **USB / Bluetooth** device from a browser tab
3. Capture camera/mic with `getUserMedia`, reason about permission UX
4. Pick the right capability API for **your capstone's advanced platform tech**

---

# The browser as platform

The 2026 browser is a **sealed OS**.

WebRTC · WebUSB · Web Bluetooth · MediaStream · Geolocation · Sensor APIs

Each:
- Lets you talk to physical hardware from JS
- Requires explicit permission
- Has subtle gotchas the docs don't fully advertise

---

# WebRTC — peer connection

The three-step dance over a signaling channel **YOU** provide:

1. **Offer** (peer A) → SDP describing what they want
2. **Answer** (peer B) → SDP describing what they'll do
3. **ICE candidates** → routes (STUN/TURN-discovered)

When direct route fails → **TURN** server relays.

---

# WebRTC — what's carried

**Media tracks** — audio/video streams between peers

**Data channels** — arbitrary byte streams<br>
→ faster than WebSocket for peer-to-peer<br>
→ slightly less reliable depending on config

**Use cases:** video calls · multiplayer game state · peer-to-peer file transfer

---

# WebUSB

```js
const dev = await navigator.usb.requestDevice({
  filters: [{ vendorId: 0x2341 }]   // Arduino
});
```

- Devices · configurations · interfaces · **endpoints**
- Permission required (**user gesture**)
- Standard mass-storage / HID / serial fight you (OS already claimed them)
- Trinkets · microcontrollers · FTDI bridges = all addressable

---

# Web Bluetooth

```js
const dev = await navigator.bluetooth.requestDevice({
  filters: [{ services: ['heart_rate'] }]
});
```

- **GATT services** + **characteristics**
- Read · write · notify
- Permission gate is **per-service**

**Nightmare modes:** backgrounding, OS-level disconnects, vendor BLE quirks (looking at you, Samsung)

---

# MediaStream + Camera

```js
const stream = await navigator.mediaDevices.getUserMedia({
  video: { facingMode: 'environment' },  // rear camera
  audio: true,
});
```

- **First time**: browser asks ALLOW or DENY
- **After**: remembered
- Pinning rear-facing, mute states, **release the stream**

---

# Permissions API — the meta-API

```js
const status = await navigator.permissions.query({ name: 'camera' });
// status.state: 'granted' | 'denied' | 'prompt'
status.addEventListener('change', () => { ... });
```

- Query state **before** asking
- Respect **denied** persistently
- Never spam the prompt

---

# Pick yours for the capstone

Sprint 3 rubric requires **ONE** advanced platform tech.

| If your capstone is... | Pick |
|---|---|
| Collaborative real-time work | **WebRTC** |
| IoT-flavored / hardware | **WebUSB / Bluetooth** |
| OCR / visual input | **Camera + getUserMedia** |
| Location-based | **Geolocation + Sensors** |

---

# Discuss in class

1. **WebRTC vs. WebSocket** — sketch a project where each is right.
2. **Permission UX** — "Allow camera" is a hostile prompt. How does your capstone *earn the right* to ask?
3. **Hardware testing** — half of you will pick something you don't have hardware for. **Plan for this NOW.**

---

# What's next

**Week 12** — PKI · OWASP top 10 · full security review

By W12: capstone should have **first working version**

W12-W13 = stabilize-and-harden

**W11 quiz** drops with this lecture.
