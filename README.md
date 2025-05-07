# DynoPowerAnalyzer

**DynoPowerAnalyzer** is a MATLAB-based analysis tool for processing and evaluating test bench data from combustion engines. It enables precise performance assessments by correcting systematic measurement influences, filtering noisy signals, and generating RPM-resolved full-load power curves. This tool is ideal for engine tuning, performance optimization, and parametric studies.

---

## 📋 Features

* Modular, multi-stage data processing pipeline in MATLAB
* Inertia correction based on rotational mass moment
* Advanced signal filtering (moving median, moving average, Butterworth)
* Generation of full-load power curves across the RPM range
* Visualization of raw vs. filtered performance data
* Easily adaptable for different engine configurations and test conditions

---

## 🧪 Measurement Data Processing

### 1. Inertia Correction

The measured torque is corrected by compensating for the counter-torque caused by the engine's rotational inertia. Angular acceleration is derived from RPM changes between sampling points and used in the inertia compensation formula. This correction ensures more accurate power calculations.

### 2. Signal Filtering and Smoothing

The calculated power signal often exhibits significant fluctuations due to combustion cycles and high sampling resolution. To obtain a meaningful, noise-reduced signal, a dual-filtering approach is used:

* **3x Moving Median (100 ms window)** followed by **1x Moving Average (100 ms window)**
* **4th-order Butterworth low-pass filter (cutoff at 5 Hz)**

The final filtered signal is computed as the average of both methods, ensuring local effects are preserved while reducing noise. The following example illustrates the filter effectiveness:

![FilterFinal](https://github.com/user-attachments/assets/942c5b77-6aea-4c73-aa7f-22bee2a12d97)


### 3. Full-Load Power Curve Generation

For each RPM step, the highest recorded power value is extracted and plotted to form a full-load power curve. This curve enables detailed analysis of the engine’s behavior across its speed range.

---

## 📈 Example Use Cases

DynoPowerAnalyzer has been applied to evaluate engine performance of a small two-stroke engine under varying the following configuration parameters. See the [additional ressources](#-Additional-Resources) for example plots and visualizations.

* [**Main Jet Size**](#main-jet-variation)
* [**Additional Fuel Enrichment by Choke**](#choke-fuel-enrichment-variation)
* [**Ignition Timing**](#ignition-timing-variation)

The tool supports **one-factor-at-a-time** experimentation to isolate the effect of individual variables.

---

## 🔧 Requirements

* MATLAB R2020b or later
* Signal Processing Toolbox (`butter`, `filtfilt`)
* Measurement CSV files placed in the `/Messdaten` directory

---

## 📌 Notes

* The moment of inertia (`J = 0.006406 kg·m²`) is estimated based on test bench hardware.
* Adjust the gear ratio in the configuration section if the setup changes.
* CSV files must follow the expected format for proper parsing and analysis.

---

## 📚 Additional Resources

### 🔍 Filter Comparison

Below are two measurement excerpts demonstrating the performance of various filtering methods:

![Filter1](https://github.com/user-attachments/assets/c340d528-cd2a-4baa-9ad5-07d448b0ea49)
![Filter2](https://github.com/user-attachments/assets/a0304d95-9898-454e-b638-5fc2f0e12e59)



### 🔧 Main Jet Variation

![Leistungskurve\_HD](https://github.com/user-attachments/assets/517fa964-4f31-49cd-906d-864270c0a13f)



### 🌀 Choke (Fuel Enrichment) Variation

![Leistungskurve\_Choke](https://github.com/user-attachments/assets/caf7e7f4-bdb8-44de-a0e3-adbf7088ba1a)



### ⚡ Ignition Timing Variation

![Leistungskurve\_ZW](https://github.com/user-attachments/assets/cf2a7390-8f86-485e-adaa-8ed9b1895f99)
