# TINA User Guide

**A workflow for microscopy image optimisation and batch preprocessing prior to quantitative analysis**

Version 1.0 | GL Kennedy-Clark & P. Jobling | GLKC Lab

[GitHub Repository](https://github.com/GLKC-Lab/TINA)

---

## Contents

1. [What is TINA?](#1-what-is-tina)
2. [The Two Workflows](#2-the-two-workflows)
3. [Before You Begin](#3-before-you-begin)
4. [Step-by-Step Guide](#4-step-by-step-guide)
5. [Choosing a Rolling Ball Radius](#5-choosing-a-rolling-ball-radius)
6. [Understanding Your Output Files](#6-understanding-your-output-files)
7. [Troubleshooting](#7-troubleshooting)
8. [Citation](#8-citation)

---

## 1. What is TINA?

TINA is a free, open-source tool that runs inside FIJI (a version of ImageJ, the standard image analysis software used in biological research). Its purpose is to help you prepare microscopy images for quantitative analysis in a way that is consistent, documented, and reproducible.

If you are measuring signal intensity, counting cells, or segmenting structures in microscopy images, the quality and consistency of your preprocessing directly affects the reliability of your results. TINA standardises that preprocessing step and keeps a complete record of every decision made along the way.

### 1.1 Why does preprocessing matter?

Raw microscopy images almost always contain background signal — low-level fluorescence or illumination that is not coming from your target protein or structure. If this background is not corrected for, it can:

- **Inflate measured signal intensities**, making weak staining look stronger than it is
- **Introduce variation between images** acquired on different days or with different instruments
- **Cause segmentation algorithms to misidentify** background as signal when thresholding

Background correction removes this unwanted signal. However, the settings you choose matter: too aggressive and you remove real biological signal; too weak and you leave behind artefactual background. TINA guides you through finding the right settings before applying them across your whole dataset.

### 1.2 What does TINA actually do?

TINA uses a background correction method called rolling-ball background subtraction, which is built into ImageJ/FIJI.

> **The rolling ball analogy**
> Imagine rolling a large ball across the underside of your image's intensity landscape. Wherever the ball touches, that is the estimated background. The radius of the ball determines how 'local' the background estimate is: a small radius detects fine-grained background variation; a large radius detects only broad, gradual background trends. Subtracting this estimated background from your image leaves only the foreground signal.

In addition to background subtraction, TINA can:

- **Standardise image polarity** — ensuring all images in your dataset have signal displayed consistently (bright signal on dark background, or vice versa)
- **Apply light median filtering** — a gentle smoothing step to reduce pixel-level noise without blurring biological structures
- **Preserve calibration metadata** — keeping your pixel size and spatial unit information intact throughout processing
- **Generate a complete processing log** — a plain-text record of every setting applied to every image

---

## 2. The Two Workflows

TINA is structured as a two-stage pipeline. This separation is deliberate: it forces a calibration decision to be made and recorded before any batch transformation is applied.

| Workflow 1: Signal Refinement | Workflow 2: Signal Standardisation |
|---|---|
| Interactive. Used on a small set of representative test images to find the right correction settings. | Automated batch processing. Applies the confirmed settings uniformly across your full image set. |
| **Run this first.** | **Run this second, once you are confident in your settings.** |

### 2.1 Signal Refinement Workflow — Overview

You select a small number of test images (between 1 and 7) that are representative of your dataset. TINA walks you through one or more calibration rounds, each with a different rolling ball radius (RBR) and correction option combination. For each round, TINA generates:

- **A processed preview image** — your image after background subtraction, displayed with your chosen colour lookup table (LUT)
- **A binary (black-and-white) preview image** — the same image after automatic thresholding, which gives you a direct view of what a segmentation algorithm would see

You assess each image visually and tell TINA whether the correction was over-corrected, suitable, or under-corrected. At the end you record your final chosen settings, and TINA saves a calibration log.

### 2.2 Signal Standardisation Workflow — Overview

You point TINA at a folder of TIFF images and enter the settings you confirmed in Workflow 1. TINA processes every image in the folder automatically, standardises polarity, and saves the results to your chosen output folder, along with a complete processing log.

> ⚠️ **Important: always run Workflow 1 before Workflow 2**
> Workflow 2 requires you to manually enter the rolling ball radius and settings you selected in Workflow 1. It does not read these automatically. Keep your signal refinement log open as a reference when running the batch workflow.

---

## 3. Before You Begin

### 3.1 Requirements

| Requirement | Details |
|---|---|
| Software | FIJI (free download: [fiji.sc](https://fiji.sc)). TINA requires FIJI version 1.53 or later. |
| Operating system | Windows, macOS, or Linux. |
| Image format | TIFF (.tif or .tiff). Single-channel images only. |
| Bit depth | 8-bit or 16-bit input accepted. TINA converts all images to 8-bit at the start of processing. |

> 📋 **Note on bit depth**
> If your original images are 16-bit, they will be converted to 8-bit during TINA processing. This is a one-way reduction in dynamic range. If your downstream analysis requires 16-bit data, keep an untouched copy of your original images and use TINA-processed images only for the specific quantification step that needs them. Document this in your methods.

### 3.2 Installing TINA

1. Download `TINA_v1.0.ijm` from the [GitHub repository](https://github.com/GLKC-Lab/TINA)
2. Open FIJI
3. **Option A — drag and drop:** drag `TINA_v1.0.ijm` directly onto the FIJI toolbar. The macro editor will open. Click **Run**.
4. **Option B — menu:** go to **Plugins → Macros → Run…** and navigate to `TINA_v1.0.ijm`.

No additional plugins or dependencies are required. TINA uses only built-in ImageJ/FIJI functions.

### 3.3 Organising your files

Before running TINA, organise your files as follows:

- Place all images you want to process in a single folder. TINA processes every `.tif` and `.tiff` file it finds in that folder.
- Create a separate output folder. Do not use the same folder as your inputs — TINA will write new files there.
- Keep a small set of representative test images (2–5 images from different conditions or acquisition sessions if possible) accessible for Workflow 1.
- Do not mix images acquired with different magnifications, exposure settings, or staining protocols in the same batch unless you have verified that a single set of correction parameters is appropriate for all of them.

---

## 4. Step-by-Step Guide

### 4.1 Launching TINA

1. Open FIJI.
2. Run `TINA_v1.0.ijm` using one of the methods described in [Section 3.2](#32-installing-tina).
3. The TINA launch dialog will appear. Select the workflow you want to run from the dropdown menu.

Select **Signal Refinement Workflow** if this is the first time you are working with this image set, or whenever you are using a new imaging protocol. Select **Signal Standardisation Workflow** once you have confirmed your settings in Workflow 1.

---

### 4.2 Workflow 1: Signal Refinement — Step by Step

#### Step 1 — Initial settings dialog

After selecting Signal Refinement Workflow, a dialog box will appear with the following fields:

| Field | What to enter |
|---|---|
| Number of test images | How many representative images to evaluate (1–7). Three to five is recommended for a robust calibration. |
| Group or image set name | A short label for this calibration session (e.g., "Batch1_IF"). This will appear in the log filename. |
| Original image polarity | Whether your raw images have bright signal on a dark background (most fluorescence images) or dark signal on a light background (e.g., DAB staining, brightfield). |
| Viewing LUT for preview | The colour map used for the processed preview. Fire is recommended for fluorescence; Grays for brightfield. |
| Synchronize Windows | Check this if you want FIJI to link the cursor position across all open preview windows. Recommended. |

#### Step 2 — Select your test images

A series of file selection dialogs will open, one per test image. Navigate to and select each representative TIFF image. TINA will not open or process these images yet — it is just recording the file paths.

#### Step 3 — Select your output folder

Choose or create a folder where TINA will save the signal refinement preview images and log. A subfolder called `Signal refinement` will be created inside it automatically.

#### Step 4 — Set correction parameters (calibration round)

The background correction settings dialog will open. This is the core of the calibration process.

| Parameter | Guidance |
|---|---|
| Rolling ball radius (RBR) | The most important parameter. Start with 50 pixels. If your fluorescent structures are large relative to the field of view, try a higher value first (75–100). If structures are small and dense, try lower (25–40). See [Section 5](#5-choosing-a-rolling-ball-radius) for detailed guidance. |
| Light background | Tick this if your images have a light (bright) background — for example, H&E or DAB staining. Leave unticked for most fluorescence images. |
| Sliding paraboloid | An alternative rolling-ball algorithm that can perform better on images with very uneven illumination. Ticked by default; untick if results look over-smoothed. |
| Disable smoothing | By default, ImageJ smooths the background estimate before subtracting it. Tick this to skip that smoothing. Only useful if you notice smoothing artefacts in your previews. |
| Apply median filter | A light noise reduction step (radius = 1 pixel) applied after background correction. Recommended for most fluorescence images. |

#### Step 5 — Review preview images

TINA will open two preview images for each of your test images:

- **Processed image:** your image after background correction, shown in your chosen LUT. Look at the background regions: do they appear uniformly dark/blank? Is the signal in the foreground still present and well-defined?
- **Binary image:** the result of automatic thresholding applied to the processed image. This shows what a segmentation algorithm would identify as signal (white) versus background (black). This is often the most informative view for assessing correction quality.

If you enabled Synchronize Windows, click **Synchronize All** in the sync panel to link cursor positions across all open windows.

> 🔍 **What to look for in the binary image**
> The binary image is your most direct indicator of correction quality. You want genuine signal (cells, fibres, labelled structures) to appear white, and background to appear black. If large regions of background are white (noisy), your correction may be insufficient. If your biological structures are partially or fully black (absent), your correction may be too aggressive.

When you have finished inspecting the images, click **OK** in the "Inspect preview images" prompt.

#### Step 6 — Assess each image

For each test image, TINA will show an assessment dialog. Select the option that best describes the result:

| Assessment | What it means |
|---|---|
| RBR too low: over-corrected background | The background correction was too aggressive. Background may appear artificially dark or 'scooped out'. Genuine signal near background regions may have been partially removed. Increase the RBR in the next round. |
| Suitable background correction | The correction appears appropriate for this image. Background is suppressed and signal is retained. |
| RBR too high: under-corrected background | The background correction was insufficient. Residual background or noise remains visible. Decrease the RBR in the next round. |

#### Step 7 — Continue or finish calibration

After assessing all test images, TINA will show a round summary and ask whether you want to test another setting. Repeat Steps 4–6 with a different rolling ball radius or option combination as many times as needed.

> 💡 **Tip: comparing rounds**
> From the second calibration round onwards, TINA will open the previous round's preview images alongside the current ones. This direct comparison is often the fastest way to judge whether your adjustment improved things.

#### Step 8 — Record your final settings

When you select "No" at the continue prompt, TINA will display a final settings dialog. Enter the rolling ball radius and options you have chosen. These values are saved to the signal refinement log. They are also what you will enter manually in Workflow 2.

TINA will display a completion message and confirm the location of the output folder. Your preview images and log are now saved.

---

### 4.3 Workflow 2: Signal Standardisation — Step by Step

#### Step 1 — Select input and output folders

TINA will ask you to select:

- **Input folder:** the folder containing all TIFF images you want to process. TINA will find and process every `.tif` and `.tiff` file in this folder.
- **Output folder:** where standardised TIFF images and the processing log will be saved. Use a separate folder from your inputs.

#### Step 2 — Enter processing parameters

The signal standardisation dialog will appear. Have your signal refinement log open for reference.

| Field | What to enter |
|---|---|
| Group or image set name | A label for this batch (e.g., "Batch1_IF"). Used in the log filename. |
| Output filename suffix | Text appended to each output filename (default: `_standardised`). For example, `image01.tif` becomes `image01_standardised.tif`. |
| Original image polarity | Match this to what you entered in Workflow 1. |
| Output image polarity | The polarity you want in your output files. Usually the same as input. Change only if downstream analysis requires a specific polarity. |
| Rolling ball radius | Enter the value you selected in Workflow 1. |
| Light background | Match to your Workflow 1 selection. |
| Sliding paraboloid | Match to your Workflow 1 selection. |
| Disable smoothing | Match to your Workflow 1 selection. |
| Apply median filter | Match to your Workflow 1 selection. |

#### Step 3 — Processing

Click **OK**. TINA will process each TIFF file in the input folder automatically. A progress indicator will be visible in the FIJI status bar. Do not close FIJI or open other files while batch processing is running. When complete, TINA will display a summary message showing how many images were processed and where the log was saved.

#### Step 4 — Check your outputs

Navigate to your output folder. You should find:

- **One standardised TIFF per input image** — named `[original_name][suffix].tif`
- **A processing log** — a plain-text file named `[group_name]_signal_standardisation_log.txt`, containing all parameter values, file counts, timestamps, and a step-by-step description of the processing pipeline

Open a sample of output images in FIJI to verify they look as expected before proceeding to downstream analysis.

---

## 5. Choosing a Rolling Ball Radius

The rolling ball radius (RBR) is the single most consequential parameter in TINA. There is no universally correct value — it depends on your imaging modality, magnification, and the size of the structures you are imaging. The table below provides starting-point guidance.

| Scenario | Suggested starting RBR |
|---|---|
| High-magnification fluorescence (63×, 40×), small puncta or processes | 25–40 pixels |
| Standard fluorescence (20×), mixed feature sizes | 50 pixels (default) |
| Low-magnification fluorescence (10× or lower), large regions of interest | 75–100 pixels |
| Brightfield / histology (H&E, DAB) with large tissue areas | 100–200 pixels |
| Images with heavy uneven illumination ('vignetting') | Start high (100+); also enable Sliding Paraboloid |

As a general rule: the RBR should be at least as large as the largest object you want to keep in your image after correction. If the ball is smaller than an object, it will 'roll inside' it and partially subtract it as if it were background.

> ⚠️ **A common mistake**
> Using a very small RBR on images with large labelled structures (e.g., whole-cell soma fluorescence, large tissue regions) is a frequent error. The background estimator treats the large bright structure itself as foreground during correction, but if the ball fits inside it, it will subtract part of the structure. Always check the binary preview image for unexpected loss of expected signal.

---

## 6. Understanding Your Output Files

### 6.1 Signal Refinement outputs

| File | Description |
|---|---|
| `[settings]_[image]_processed.tif` | Background-corrected preview image with your chosen LUT applied. One per test image per calibration round. |
| `[settings]_[image]_binary.tif` | Binary (thresholded) version of the processed preview. One per test image per calibration round. |
| `[group]_signal_refinement_log.txt` | Complete calibration log: group name, all tested RBR values and options, per-image assessments for every round, and final selected parameters. |

### 6.2 Signal Standardisation outputs

| File | Description |
|---|---|
| `[image][suffix].tif` | Standardised 8-bit TIFF. Background-corrected, polarity-standardised, calibration metadata preserved. |
| `[group]_signal_standardisation_log.txt` | Full batch processing log: parameters, file count, start/end timestamps, elapsed time, and step-by-step pipeline description. |

> 📋 **Keep your logs**
> Both log files are designed to be included as supplementary data in publications. They provide a complete, machine-readable record of your preprocessing, which satisfies data transparency requirements and enables others to reproduce your pipeline exactly.

---

## 7. Troubleshooting

| Problem | Solution |
|---|---|
| TINA dialog does not appear after running the macro | Ensure FIJI (not plain ImageJ) is version 1.53 or later. Go to **Help → Update FIJI** to update. |
| File selection dialog does not open for a test image | The maximum is 7 test images. Ensure you entered a valid number (1–7). |
| Preview images open but look identical across rounds | Check that you changed the RBR or at least one option between rounds. Small RBR differences on some image types may produce visually similar results — try a larger step change (e.g., 25 vs 75). |
| Binary image is entirely white or entirely black | An entirely white binary suggests the image is very low contrast after correction (possibly over-corrected). An entirely black binary suggests no signal was detected above threshold (possibly heavily over-corrected, or image polarity is set incorrectly). Check your polarity setting. |
| Batch processing finishes immediately with zero images processed | TINA only processes `.tif` and `.tiff` files. Check that your input folder contains files with these extensions. Note that `.TIF` (uppercase) should also be detected. |
| Output images look different from previews | Preview images in Workflow 1 are displayed with a specific LUT for visual assessment. Output images from Workflow 2 are saved with the Grays LUT and should be identical in pixel values to what the previews showed. Open an output image, reset brightness/contrast, and compare. |
| Processing log is missing | The log is saved to the output folder. If the output folder path contains unusual characters, the log filename may have been sanitised. Check the folder directly. |

---

## 8. Citation

If you use TINA in your research, please cite:

> Kennedy-Clark, G.L. & Jobling, P. (2026). *TINA: A workflow for microscopy image optimisation and batch preprocessing prior to quantitative analysis* (v1.0). Zenodo. https://doi.org/10.5281/zenodo.XXXXXXX

A `CITATION.cff` file is included in the GitHub repository for citation manager compatibility.

TINA is open-source software released under the MIT Licence.

---

*TINA v1.0 — User Guide | GL Kennedy-Clark & P. Jobling (GLKC Lab) | [https://github.com/GLKC-Lab/TINA](https://github.com/GLKC-Lab/TINA)*
