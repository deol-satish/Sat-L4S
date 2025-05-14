Both **OneWeb** and **Starlink** use **LEO (Low Earth Orbit) satellite constellations** to provide internet services, but the specifics of their internal network implementations, including **Active Queue Management (AQM)** mechanisms, are **not fully disclosed publicly**. However, based on what’s known from technical reports, public statements, and general networking best practices, here's what can be reasonably inferred:

---

### 🛰 **1. Starlink (SpaceX)**

#### ✅ Likely Uses AQM

* Starlink networks have been analyzed by independent researchers (e.g., through packet captures and latency measurements).
* Observed behavior during congestion (e.g., low latency under load) suggests **some form of AQM or queue management is in place**, likely to maintain low latency for real-time applications like gaming and video calls.

#### 🧠 Likely Default AQM: **FQ-CoDel**

* **FQ-CoDel (Fair Queuing Controlled Delay)** is the most common AQM used in modern low-latency networks.
* OpenWRT, Linux, and many commercial routers use it by default.
* Researchers such as Jim Gettys (bufferbloat.net) have speculated or suggested that **Starlink uses FQ-CoDel or a variation** of it.
* Empirical behavior (latency under load, throughput patterns) aligns well with FQ-CoDel.

---

### 🛰 **2. OneWeb**

#### ❓ Unclear AQM Usage

* OneWeb’s technical architecture is more enterprise and mobile-backhaul oriented, and less is known about their consumer-level traffic shaping.
* Their system uses ground-based gateways and inter-satellite links, and their partners often control the last-mile network where AQM would be applied.

#### 🔍 Possible AQM: **Depends on gateway operators**

* If OneWeb terminals or gateways use Linux-based routing platforms (likely), they may use **FQ-CoDel or Cake** as default AQMs.
* However, enterprise or mobile operators using OneWeb may disable AQM in favor of static QoS or MPLS prioritization.

---

### 📌 Summary Table

| Provider     | AQM Used?           | Likely AQM Technique                       | Notes                                |
| ------------ | ------------------- | ------------------------------------------ | ------------------------------------ |
| **Starlink** | Yes (likely)        | FQ-CoDel or variant                        | Inferred from performance behavior   |
| **OneWeb**   | Possibly (variable) | Gateway-dependent (FQ-CoDel/Cake/MPLS QoS) | May not apply AQM at satellite level |

---

### 🔧 Additional Note:

In LEO systems, congestion is **most likely managed at the terminal/router** and **ground gateway**, not on the satellites themselves. Satellites forward packets at very high speeds and have limited onboard processing, so queue management is typically applied closer to the edge or user devices.

Would you like help analyzing a packet capture from Starlink to detect if AQM is active (e.g., latency under load test)?
