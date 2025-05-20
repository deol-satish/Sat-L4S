Great — you're asking for **channel bandwidth and frequencies specifically for OneWeb's user link**. Here's what you need to model it accurately:

---

## ✅ OneWeb User Link Overview

### 📡 Frequency Bands (from FCC and ITU filings):

* **Uplink (User → Satellite)**: **14.0 – 14.5 GHz** (Ku-band)
* **Downlink (Satellite → User)**: **10.7 – 12.7 GHz** (Ku-band)

### 📶 Channel Bandwidth:

* OneWeb typically uses **250 MHz** channel bandwidths.

This is the practical standard used for FDMA/TDMA in user terminals.

---

## 🧮 MATLAB Channel Frequency Setup (User Link)

### For **downlink** (Satellite → User):

```matlab
channelBW = 250e6;  % 250 MHz per channel
startFreq = 10.75e9;  % Start safely inside the band
channelFreqs = startFreq + (0:9) * channelBW;  % 10 channels
```

### Output `channelFreqs` (Hz):

```
1.075e10  (10.75 GHz)
1.100e10  (11.00 GHz)
1.125e10  (11.25 GHz)
1.150e10  (11.50 GHz)
1.175e10  (11.75 GHz)
1.200e10  (12.00 GHz)
1.225e10  (12.25 GHz)
1.250e10  (12.50 GHz)
1.275e10  (12.75 GHz)
1.300e10  (13.00 GHz) ← Slightly outside official band, can trim if needed
```

To stay strictly inside the **10.7 – 12.7 GHz** range, you can reduce to 8 channels:

```matlab
channelFreqs = 10.75e9 + (0:7) * channelBW;
```

---

### ✅ Summary:

* **Use 250 MHz** channel bandwidth
* **Use downlink frequencies** in **10.7–12.7 GHz**, starting at 10.75 GHz
* Adjust number of channels to stay within the band

Let me know if you also want the **uplink** version (14.0–14.5 GHz).
