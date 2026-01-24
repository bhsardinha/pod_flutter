

0 - CONSIDER THAT I REMOVED THE ESSENTIAL FILES AND NEED YOU TO REWRITE EVERYTHING AGAIN, FROM SCRATCH: midi_service, ble_midi_service, patch_storage_service, pod_controller and sysex.dart


1 - CREATE 1:1 function ports RUST > DART/FLUTTER, reading the originals at /pod-ui-master folder, under core, usb, mod-xt subfolders

2 - REDO THE API WITH THE NEW FILES AND FUNCTIONS (obbey the following structure)

┌────────────────────┐
│   PodController    │
│────────────────────│
│ Business logic     │
│ Patch management   │
│ UI coordination    │
│                    │
│ ❌ NO HANDSHAKE     │
└─────────▲──────────┘
          │
┌─────────┴──────────┐
│   MidiService API  │
│────────────────────│
│ Abstract contract  │
│ CC / PC / Sysex    │
│                    │
│ ❌ NO UDI METHODS   │
└─────────▲──────────┘
          │
┌─────────┴──────────┐
│  BleMidiService    │
│────────────────────│
│ Transport          │
│ Framing            │
│ Handshake (UDI)    │
│ Packet assembly    │
│                    │
│ ✅ UDI LIVES HERE   │
└─────────▲──────────┘
          │
┌─────────┴──────────┐
│     sysex.dart     │
│────────────────────│
│ Line6 protocol     │
│ Encoding/decoding  │
│                    │
│ Stateless helpers  │
└────────────────────┘


3 - REWIRE THE FLUTTER UI TO USE THE NEW FUNCTIONS. the app must behave just like the pod-ui and line 6 edit. im making a POD XT PRO EXCLUSIVE, but with the exact same funcitons, just more beautiful and in another framework.