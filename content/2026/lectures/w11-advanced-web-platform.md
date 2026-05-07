---
slug: lecture-w11-advanced-web-platform
week: 11
youtube_id: null
companion_sheets:
  - cheatsheet-advanced-web-platform
reflection_assignment: reflection-w11
vernacular_tags:
  - "WebRTC: peer connection, data channel"
  - "Web USB: device, endpoint"
  - "Web Bluetooth: GATT service, characteristic"
  - "MediaStream: getUserMedia"
  - "Permissions API"
  - "Perfect Framework: Application > Platform Support"
---

# Week 11 — Advanced Web Platform: WebRTC · USB · Bluetooth · Camera

## What you'll know after this

You'll be able to (a) describe the WebRTC peer-connection lifecycle and what a data channel actually carries; (b) connect to a USB or Bluetooth device from a browser tab; (c) capture camera/microphone with `getUserMedia` and reason about the permissions UX; (d) pick the right capability API for your Sprint 3 capstone's required "advanced platform tech."

## Outline

1. **The "browser as platform" reality** *(5 min)*
   The 2026 browser is a sealed OS. WebRTC, WebUSB, Web Bluetooth, MediaStream, Geolocation, Sensor APIs — each lets you talk to physical hardware from JavaScript. Each requires explicit permission. Each has subtle gotchas the docs don't fully advertise.

2. **WebRTC** *(15 min)*
   - Peer connection: three-step dance (offer, answer, ICE candidates) over a signaling channel YOU provide.
   - Media tracks: audio/video streams between peers.
   - Data channels: arbitrary byte streams (faster than WebSocket for peer-to-peer; slightly less reliable depending on configuration).
   - Use cases: video calls, multiplayer game state sync (data channels), peer-to-peer file transfer.

3. **WebUSB** *(8 min)*
   Devices, configurations, interfaces, endpoints. Permission required (user gesture). Devices that don't expose `MISC` device class (most consumer devices) need a vendor declaration. Trinkets, microcontrollers, FTDI bridges = all addressable. Standard mass-storage / HID / serial profiles can fight you because the OS already claimed them.

4. **Web Bluetooth** *(8 min)*
   GATT services and characteristics. Read/write/notify. Heart-rate monitors, BLE beacons, custom firmware. Permission gate is per-service. Nightmare modes: backgrounding, OS-level disconnects, phone vendor BLE quirks (looking at you, Samsung).

5. **MediaStream + Camera** *(7 min)*
   `getUserMedia({video: true, audio: true})`. Constraints (resolution, facingMode). The first time, the browser asks; the user clicks ALLOW or DENY. After that, it's remembered. Pinning the rear-facing camera, dealing with mute states, knowing when to release the stream.

6. **The Permissions API — the meta-API** *(5 min)*
   Query whether you have permission BEFORE asking; respect "denied" persistently; never spam the prompt. The Permissions API gives you the state without triggering the ask. Use it.

7. **Pick yours for the capstone** *(2 min)*
   Sprint 3 rubric requires ONE advanced platform tech. WebRTC for collaborative real-time work; WebUSB/Bluetooth for IoT-flavored capstones; Camera for OCR or visual-input apps.

## Discuss in class

- **WebRTC vs. WebSocket — which for what?** Sketch a project where each is right.
- **The permission UX problem.** "Allow camera access" is a hostile prompt for most users. How does your capstone *earn the right* to ask?
- **Hardware testing.** Half of you will pick something you don't have hardware for. Plan for this NOW.

## Further reading

- **`cheatsheet-advanced-web-platform`** — quick reference for all four APIs.
- **MDN: WebRTC API** — the canonical docs.
- **Caniuse.com** — check browser support for whatever you pick. Some APIs are still chromium-only.
- **whatwg.org** — the spec source of truth.

## What's next

Week 12 covers PKI, OWASP top 10, and a full security review. Your capstone should have first working version by then; W12-W13 are stabilize-and-harden. The W11 quiz drops with this lecture.
