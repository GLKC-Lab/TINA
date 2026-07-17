# TINA

**A workflow for microscopy image optimisation and batch preprocessing prior to quantitative analysis.**

[![DOI](https://zenodo.org/badge/1237413039.svg)](https://doi.org/10.5281/zenodo.20541753)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ImageJ/FIJI](https://img.shields.io/badge/ImageJ%2FFIJI-%E2%89%A51.53-green)](https://fiji.sc)

---

## Overview

TINA is an open-source ImageJ/FIJI macro workflow designed to support reproducible microscopy image preprocessing prior to downstream segmentation and quantitative analysis. It provides a guided, two-stage approach: first calibrating background correction settings on representative test images, then applying those validated settings uniformly across a full image batch.

TINA is designed for broad compatibility across microscopy modalities, including immunofluorescence, brightfield, histological, and other biological imaging applications.

## Latest release: v1.0.1

Version 1.0.1 improves the interactive Signal Refinement workflow through clearer Signal Optimisation prompts, more detailed synchronised-comparison guidance, improved positioning and cleanup of the ImageJ **Synchronize Windows** controller, and an inspection dialog that remains visible while preview images can still be examined. The underlying image-processing and measurement pipeline is unchanged from v1.0.0.

---

## Features

- **Interactive signal refinement** — test and compare background correction settings on representative images before batch processing
- **Guided preview comparison** — inspect processed and binary previews with optional linked panning, zooming, coordinates, and cursor positions through ImageJ's Synchronize Windows tool
- **Batch signal standardisation** — apply validated settings uniformly across an entire image set
- **Image polarity management** — supports both dark-background and light-background input/output configurations
- **Calibration metadata preservation** — pixel width, height, voxel depth, and unit are retained from source images
- **Optional noise reduction** — median filter (radius = 1) applied after background correction
- **Reproducibility logs** — automated processing logs generated for both workflows, recording all parameters and per-image outcomes

---

## Requirements

- [FIJI](https://fiji.sc) (ImageJ version ≥ 1.53)
- Input images in TIFF format

---

## Video Overview

Watch a brief introduction to the TINA workflows and user interface:

https://youtu.be/o-pia3ybPT0

---

## Installation

1. Download `TINA_v1.0.1.ijm` from this repository.
2. Open FIJI.
3. Install via one of the following methods:
   - Drag and drop the `.ijm` file onto the FIJI toolbar, then click **Run**.
   - Or select **Plugins → Macros → Run...** and navigate to the downloaded file.

---

## Usage

When launched, TINA presents a dialog to select one of two workflows.

### Workflow 1: Signal Refinement

Use this workflow first to calibrate your background correction settings using a small set of representative test images.

**What it does:**

1. Prompts you to select 1–7 representative TIFF test images.
2. For each round, you specify rolling ball radius (RBR) and correction options.
3. TINA generates a processed preview (with your chosen LUT) and a binary preview for each image.
4. Optional synchronised comparison allows linked inspection of matching image regions.
5. You visually assess each image and rate the correction as over-corrected, suitable, or under-corrected.
6. You can trial multiple settings across multiple rounds, comparing current and previous results side by side.
7. At the end, you record your final selected settings.
8. A detailed log is saved recording all tested settings and per-image assessments.

**Key parameters:**

| Parameter | Description |
|---|---|
| Rolling ball radius (RBR) | Lower values = stronger correction; higher values = weaker correction |
| Light background | Enable if your images have a light background with dark signal |
| Sliding paraboloid | Recommended for most fluorescence images |
| Disable smoothing | Disables the pre-smoothing step in background subtraction |
| Median filter | Optional noise reduction step after background correction |

### Workflow 2: Signal Standardisation

Use this workflow after completing Signal Refinement to batch-process your full image set with validated settings.

**What it does:**

1. Prompts you to select an input folder containing TIFF images and an output folder.
2. You enter the background correction parameters identified during Signal Refinement.
3. TINA processes all TIFF images in the input folder using a standardised pipeline.
4. Standardised 8-bit TIFF images are saved to the output folder.
5. A processing log is saved recording all parameters, file counts, and completion status.

**Processing pipeline applied to each image:**

1. Open TIFF image.
2. Record original calibration metadata.
3. Convert to 8-bit.
4. Invert if input polarity is light background with dark signal.
5. Apply background subtraction using ImageJ/FIJI **Subtract Background**.
6. Apply median filter (radius = 1) if selected.
7. Enforce output image polarity.
8. Reapply original calibration metadata.
9. Save the standardised TIFF.

---

## Output files

| File | Description |
|---|---|
| `*_processed.tif` | Background-corrected preview image with selected LUT (Signal Refinement) |
| `*_binary.tif` | Binary threshold preview for assessing correction quality (Signal Refinement) |
| `*_standardised.tif` | Final batch-processed image (Signal Standardisation) |
| `*_signal_refinement_log.txt` | Full log of all tested settings and per-image assessments |
| `*_signal_standardisation_log.txt` | Full log of the batch-processing run, including parameters and file counts |

---

## How to cite

If you use TINA in your research, please cite the version used in your analysis. For version 1.0.1:

> Kennedy-Clark, G. L. & Jobling, P. (2026). *TINA: A workflow for microscopy image optimisation and batch preprocessing prior to quantitative analysis* (v1.0.1). Zenodo. https://doi.org/10.5281/zenodo.20541754

A `CITATION.cff` file is included in this repository for automated citation tools. After the v1.0.1 Zenodo deposit is created, replace the version-specific DOI above with the DOI assigned to that release if it differs.

---

## Authors

- **G. L. Kennedy-Clark** — University of Newcastle, Australia — [ORCID: 0009-0004-3440-9020](https://orcid.org/0009-0004-3440-9020)
- **Phillip Jobling** — School of Biomedical Sciences and Pharmacy, University of Newcastle, Australia

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
