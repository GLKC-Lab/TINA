# Changelog

All notable changes to TINA will be documented in this file.

## [1.0.1] - 2026-07-17

### Improved

- Refined the interactive Signal Refinement workflow with clearer Signal Optimisation terminology.
- Expanded the preview-inspection guidance for linked cursor, image-coordinate, and image-scaling comparison.
- Replaced the blocking preview prompt with a controlled inspection dialog that remains visible while preview images are interactive.
- Improved positioning of the ImageJ **Synchronize Windows** controller.
- Improved cleanup of the Synchronize Windows controller before preview images are closed.

### Changed

- Replaced the generic **Continue?** choice with **Continue Signal Optimisation?**.
- Updated the continuation options to:
  - **Yes - Trial another combination of signal optimisation settings**
  - **No - I have chosen my signal optimisation settings**
- Updated software version identifiers and processing logs to v1.0.1.

### Compatibility

- No changes were made to the background-subtraction algorithm, processing sequence, output image format, calibration preservation, or quantitative behaviour introduced in v1.0.0.

## [1.0.0] - 2026-05-14

### Initial release

- Signal Refinement Workflow for interactive background correction calibration.
- Signal Standardisation Workflow for batch preprocessing.
- Rolling ball background subtraction with configurable parameters.
- Image polarity standardisation.
- Optional median filter for noise reduction.
- Calibration metadata preservation.
- Automated processing logs for both workflows.
