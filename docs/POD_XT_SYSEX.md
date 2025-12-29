# POD XT Pro Sysex Protocol

Reference: [pod-ui](https://github.com/arteme/pod-ui)

## Key Difference from POD 2.0

POD XT uses **raw data** (NOT nibble-encoded) in sysex dumps. This differs from POD 2.0 which uses nibble encoding.

## Program Size

```
Program Size: 160 bytes (72*2 + 16)
- 144 bytes: main patch data
- 16 bytes: patch name (at offset 0)
```

## Sysex Message Format

All messages start with Line6 manufacturer ID: `[0xF0, 0x00, 0x01, 0x0C, ...]`

### Commands (POD XT specific - 0x03 prefix)

| Command | Bytes | Description |
|---------|-------|-------------|
| Installed Packs | `0x03, 0x0E` | Request/response expansion packs |
| Edit Buffer Request | `0x03, 0x75` | Request current edit buffer |
| Edit Buffer Response | `0x03, 0x74` | Edit buffer dump response |
| Patch Request | `0x03, 0x73` | Request specific patch |
| Patch Response | `0x03, 0x71` | Patch dump response |
| Patch Dump End | `0x03, 0x72` | All patches sent |
| Store Success | `0x03, 0x50` | Patch stored successfully |
| Store Failure | `0x03, 0x51` | Patch store failed |
| Tuner Data | `0x03, 0x56` | Tuner frequency data |
| Program State | `0x03, 0x57` | Program state notification |

## Edit Buffer Dump Response

```
[0xF0] [0x00, 0x01, 0x0C] [0x03, 0x74] [id] [raw_data...] [0xF7]
                          ^command      ^1   ^160 bytes
```

- `id`: Device ID byte (1 byte)
- `raw_data`: 160 bytes of raw patch data (NOT nibble-encoded)

## Patch Dump Response

```
[0xF0] [0x00, 0x01, 0x0C] [0x03, 0x71] [patch_lsb] [patch_msb] [id] [raw_data...] [0xF7]
                          ^command      ^patch number (16-bit)   ^1   ^160 bytes
```

- `patch_lsb`, `patch_msb`: Patch number as 16-bit value (LSB first)
- `id`: Device ID byte
- `raw_data`: 160 bytes of raw patch data (NOT nibble-encoded)

## Patch Request

```
[0xF0] [0x00, 0x01, 0x0C] [0x03, 0x73] [bank] [program] [0xF7]
```

## All Patches Request

```
[0xF0] [0x00, 0x01, 0x0C] [0x01, 0x00, 0x02] [0xF7]
```

## Expansion Pack Flags

| Flag | Name | Description |
|------|------|-------------|
| 0x01 | MS | Metal Shop Amp Expansion |
| 0x02 | CC | Collector's Classic Amp Expansion |
| 0x04 | FX | FX Junkie Effects Expansion |
| 0x08 | BX | Bass Expansion |

## Sources

- [pod-ui core/src/midi.rs](https://github.com/arteme/pod-ui/blob/master/core/src/midi.rs)
- [pod-ui mod-xt/src/config.rs](https://github.com/arteme/pod-ui/blob/master/mod-xt/src/config.rs)
- [netzstaub - Encoding 8 bit data in MIDI sysex](https://blogs.bl0rg.net/netzstaub/2008/08/14/encoding-8-bit-data-in-midi-sysex/)
