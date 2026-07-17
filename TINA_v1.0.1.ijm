// ============================================================================
// TINA
// A workflow for microscopy image optimisation and batch preprocessing
// prior to quantitative analysis.
//
// Description:
// TINA is an open-source ImageJ/FIJI workflow designed to support
// reproducible microscopy image preprocessing through guided signal refinement,
// standardised batch processing, and export consistency prior to downstream
// segmentation and quantitative analysis.
//
// Current functionality includes:
// - Signal refinement workflows for background correction calibration
// - Signal standardisation workflows for batch preprocessing
// - Image polarity standardisation
// - Optional median filtering for noise reduction
// - Reproducibility-focused processing logs
// - Calibration metadata preservation
//
// Designed for broad compatibility across microscopy modalities,
// including immunofluorescence, brightfield, histological,
// and other biological imaging applications.
//
// Developed using FIJI / ImageJ macro language.
//
// Authors:    GL Kennedy-Clark, P. Jobling
//             University of Newcastle, Australia
// Contact:    https://github.com/GLKC-Lab/TINA
// DOI:        https://doi.org/10.5281/zenodo.20541754
// Licence:    MIT
// ============================================================================
// Version: 1.0.1
// ============================================================================

macro "TINA" {
    Dialog.create("TINA");
    Dialog.addMessage("A workflow for microscopy image optimisation and batch preprocessing prior to quantitative analysis.");
    Dialog.addMessage("Select the preprocessing workflow to perform:");
    Dialog.addChoice("Workflow type", newArray("Signal Refinement Workflow", "Signal Standardisation Workflow"), "Signal Refinement Workflow");
    Dialog.show();

    workflow = Dialog.getChoice();

    if (workflow == "Signal Refinement Workflow") {
        runSignalRefinementWorkflow();
    } else {
        runSignalStandardisationWorkflow();
    }
}

// ============================================================================
// WORKFLOW 1: SIGNAL REFINEMENT
// ============================================================================

function runSignalRefinementWorkflow() {
    requires("1.53");

    Dialog.create("Signal Refinement Workflow");
    Dialog.addMessage("Evaluate background correction settings using representative test images before applying them across the full image set.");
    Dialog.addNumber("Number of test images", 3);
    Dialog.addString("Experimental group or image set name", "Group_A");
    Dialog.addChoice("Original image polarity", newArray("Dark background with bright signal", "Light background with dark signal"), "Dark background with bright signal");
    Dialog.addChoice("Viewing LUT for processed preview", newArray("Fire", "Grays", "Green", "Cyan", "Magenta", "Red", "Blue"), "Fire");
    Dialog.addCheckbox("Open Synchronize Windows during comparison", true);
    Dialog.show();

    numTestImages = Dialog.getNumber();
    groupName = Dialog.getString();
    inputPolarity = Dialog.getChoice();
    previewLUT = Dialog.getChoice();
    syncComparisonWindows = Dialog.getCheckbox();

    if (numTestImages < 1) {
        numTestImages = 1;
    }
    if (numTestImages > 7) {
        numTestImages = 7;
    }

    imagePaths = newArray(numTestImages);

    for (i = 0; i < numTestImages; i++) {
        imagePaths[i] = File.openDialog("Select TIFF test image " + (i + 1) + " of " + numTestImages);
        if (imagePaths[i] == "") {
            exit("Image selection cancelled.");
        }
    }

    outputBase = getDirectory("Choose or create a folder to save signal refinement outputs");
    if (outputBase == "") {
        exit("No output location selected.");
    }

    optDir = outputBase + "Signal refinement" + File.separator;
    File.makeDirectory(optDir);

    testedSettingsLog = "";
    testedImageAssessmentLog = "";
    roundCount = 0;
    keepTesting = 1;
    previousSettingsLabel = "";

    while (keepTesting == 1) {
        Dialog.create("Background Correction Settings");
        Dialog.addMessage("Select the rolling ball radius and background correction options to evaluate.");
        Dialog.addMessage("RBR guide: lower RBR values produce stronger background correction, while higher RBR values produce weaker background correction.");
        Dialog.addNumber("Rolling ball radius", 50);
        Dialog.addCheckbox("Light background", false);
        Dialog.addCheckbox("Sliding paraboloid", true);
        Dialog.addCheckbox("Disable smoothing", false);
        Dialog.addChoice("Apply median filter to reduce noise after background correction?", newArray("Yes", "No"), "Yes");
        Dialog.show();

        rbr = Dialog.getNumber();
        lightBackground = Dialog.getCheckbox();
        slidingParaboloid = Dialog.getCheckbox();
        disableSmoothing = Dialog.getCheckbox();
        noiseReductionChoice = Dialog.getChoice();

        applyMedianRefinement = 0;
        if (noiseReductionChoice == "Yes") {
            applyMedianRefinement = 1;
        }

        roundCount = roundCount + 1;

        settingsLabel = "RBR-" + cleanNumberForFilename(rbr) + "_settings";
        anySettingTicked = 0;

        if (lightBackground == 1) {
            settingsLabel = settingsLabel + "-LightBackground";
            anySettingTicked = 1;
        }

        if (slidingParaboloid == 1) {
            settingsLabel = settingsLabel + "-SlidingParaboloid";
            anySettingTicked = 1;
        }

        if (disableSmoothing == 1) {
            settingsLabel = settingsLabel + "-DisableSmoothing";
            anySettingTicked = 1;
        }

        if (anySettingTicked == 0) {
            settingsLabel = settingsLabel + "-None";
        }

        if (applyMedianRefinement == 1) {
            settingsLabel = settingsLabel + "_MedianFilterNoiseReduction-Yes";
        } else {
            settingsLabel = settingsLabel + "_MedianFilterNoiseReduction-No";
        }

        settingsLabel = safeFilename(settingsLabel);

        testedSettingsLog = testedSettingsLog + "Round " + roundCount + ": RBR=" + rbr;
        testedSettingsLog = testedSettingsLog + ", Light background=" + yesNo(lightBackground);
        testedSettingsLog = testedSettingsLog + ", Sliding paraboloid=" + yesNo(slidingParaboloid);
        testedSettingsLog = testedSettingsLog + ", Disable smoothing=" + yesNo(disableSmoothing);
        testedSettingsLog = testedSettingsLog + ", Median filter for noise reduction after background correction=" + yesNo(applyMedianRefinement) + "\n";

        roundSummary = "Signal refinement assessment results for this round:\n\n";
        countOverCorrected = 0;
        countSuitable = 0;
        countUnderCorrected = 0;

        for (i = 0; i < numTestImages; i++) {
            currentImageName = getBaseNameFromPath(imagePaths[i]);

            currentAssessment = processOneSignalRefinementImage(
                imagePaths[i],
                optDir,
                settingsLabel,
                previousSettingsLabel,
                rbr,
                lightBackground,
                slidingParaboloid,
                disableSmoothing,
                inputPolarity,
                previewLUT,
                applyMedianRefinement,
                syncComparisonWindows
            );

            roundSummary = roundSummary + currentImageName + ": " + currentAssessment + "\n";
            testedImageAssessmentLog = testedImageAssessmentLog + "Round " + roundCount + ", " + currentImageName + ": " + currentAssessment + "\n";

            if (currentAssessment == "RBR too low: over-corrected background") {
                countOverCorrected = countOverCorrected + 1;
            }
            if (currentAssessment == "Suitable background correction") {
                countSuitable = countSuitable + 1;
            }
            if (currentAssessment == "RBR too high: under-corrected background") {
                countUnderCorrected = countUnderCorrected + 1;
            }
        }

        roundSummary = roundSummary + "\nSummary:\n";
        roundSummary = roundSummary + "RBR too low: over-corrected background: " + countOverCorrected + "\n";
        roundSummary = roundSummary + "Suitable background correction: " + countSuitable + "\n";
        roundSummary = roundSummary + "RBR too high: under-corrected background: " + countUnderCorrected + "\n";

        previousSettingsLabel = settingsLabel;

        continueMessage = roundSummary;
        continueMessage = continueMessage + "\nImages from this round have been saved.\n";

        continueYes = "Yes - Trial another combination of signal optimisation settings";
        continueNo = "No - I have chosen my signal optimisation settings";

        Dialog.create("Continue signal refinement?");
        Dialog.addMessage(continueMessage);
        Dialog.addChoice(
            "Continue Signal Optimisation?",
            newArray(continueYes, continueNo),
            continueYes
        );
        Dialog.show();

        continueChoice = Dialog.getChoice();
        if (continueChoice == continueNo) {
            keepTesting = 0;
        }
    }

    Dialog.create("Selected Signal Refinement Settings");
    Dialog.addMessage("Record the final background correction settings selected for signal standardisation.");
    Dialog.addString("Experimental group or image set name", groupName);
    Dialog.addNumber("Selected rolling ball radius", 50);
    Dialog.addCheckbox("Selected: Light background", false);
    Dialog.addCheckbox("Selected: Sliding paraboloid", true);
    Dialog.addCheckbox("Selected: Disable smoothing", false);
    Dialog.addChoice("Selected: Apply median filter to reduce noise after background correction?", newArray("Yes", "No"), "Yes");
    Dialog.show();

    finalGroupName = Dialog.getString();
    finalRBR = Dialog.getNumber();
    finalLightBackground = Dialog.getCheckbox();
    finalSlidingParaboloid = Dialog.getCheckbox();
    finalDisableSmoothing = Dialog.getCheckbox();
    finalNoiseChoice = Dialog.getChoice();

    finalApplyMedian = 0;
    if (finalNoiseChoice == "Yes") {
        finalApplyMedian = 1;
    }

    logPath = optDir + safeFilename(finalGroupName) + "_signal_refinement_log.txt";

    writeSignalRefinementLog(
        logPath,
        finalGroupName,
        inputPolarity,
        finalRBR,
        finalLightBackground,
        finalSlidingParaboloid,
        finalDisableSmoothing,
        finalApplyMedian,
        numTestImages,
        roundCount,
        outputBase,
        optDir,
        testedSettingsLog,
        testedImageAssessmentLog
    );

    showMessage("Signal Refinement Complete", "Signal refinement completed.\n\nImages and log saved in:\n" + optDir);
}

function processOneSignalRefinementImage(path, optDir, settingsLabel, previousSettingsLabel, rbr, lightBackground, slidingParaboloid, disableSmoothing, inputPolarity, previewLUT, applyMedianRefinement, syncComparisonWindows) {
    open(path);

    originalTitle = getTitle();
    baseName = stripExtension(originalTitle);
    baseName = safeFilename(baseName);

    getPixelSize(originalUnit, originalPixelWidth, originalPixelHeight, originalVoxelDepth);

    run("8-bit");

    if (inputPolarity == "Light background with dark signal") {
        run("Invert");
    }

    applyBackgroundCorrection(rbr, lightBackground, slidingParaboloid, disableSmoothing);

    if (applyMedianRefinement == 1) {
        run("Median...", "radius=1");
    }

    applyCalibration(originalPixelWidth, originalPixelHeight, originalVoxelDepth, originalUnit);
    applyLUT(previewLUT);

    processedTitle = settingsLabel + "_" + baseName + "_processed";
    rename(processedTitle);
    processedID = getImageID();

    applyCalibration(originalPixelWidth, originalPixelHeight, originalVoxelDepth, originalUnit);
    saveAs("Tiff", optDir + processedTitle + ".tif");

    selectImage(processedID);

    binaryTitle = settingsLabel + "_" + baseName + "_binary";
    run("Duplicate...", "title=[" + binaryTitle + "]");
    binaryID = getImageID();

    selectImage(binaryID);
    applyCalibration(originalPixelWidth, originalPixelHeight, originalVoxelDepth, originalUnit);
    setOption("BlackBackground", false);
    run("Make Binary");
    applyCalibration(originalPixelWidth, originalPixelHeight, originalVoxelDepth, originalUnit);
    saveAs("Tiff", optDir + binaryTitle + ".tif");

    prevProcessedID = -1;
    prevBinaryID = -1;

    if (previousSettingsLabel != "") {
        previousProcessedPath = optDir + previousSettingsLabel + "_" + baseName + "_processed.tif";
        previousBinaryPath = optDir + previousSettingsLabel + "_" + baseName + "_binary.tif";

        if (File.exists(previousProcessedPath)) {
            open(previousProcessedPath);
            prevProcessedID = getImageID();
        }

        if (File.exists(previousBinaryPath)) {
            open(previousBinaryPath);
            prevBinaryID = getImageID();
        }
    }

    if (prevProcessedID != -1) {
        selectImage(prevProcessedID);
        run("Enhance Contrast", "saturated=0.35");
    }

    if (prevBinaryID != -1) {
        selectImage(prevBinaryID);
        run("Enhance Contrast", "saturated=0.35");
    }

    selectImage(processedID);
    run("Enhance Contrast", "saturated=0.35");

    selectImage(binaryID);
    run("Enhance Contrast", "saturated=0.35");

    // Restore the original TINA preview presentation. ImageJ tiles the open
    // processed and binary images using its native window sizing, rather than
    // forcing them into fixed cells or applying a custom magnification.
    run("Tile");

    if (syncComparisonWindows == 1) {
        run("Synchronize Windows");
        wait(250);
        positionSynchronizeWindows();
    }

    if (previousSettingsLabel == "") {
        inspectMessage = "Review the processed and binary preview images\n";
        inspectMessage = inspectMessage + "to assess the current background correction.\n\n";
        inspectMessage = inspectMessage + "TIP - For the best comparison:\n";
        inspectMessage = inspectMessage + "[x] Enable Sync Cursor\n";
        inspectMessage = inspectMessage + "[x] Enable Image Coordinates\n";
        inspectMessage = inspectMessage + "[x] Enable Image Scaling\n";
        inspectMessage = inspectMessage + "Then click Synchronize All.\n\n";
        inspectMessage = inspectMessage + "You can then pan and zoom either image while the matching\n";
        inspectMessage = inspectMessage + "region is automatically displayed in the other preview.\n\n";
        inspectMessage = inspectMessage + "When inspection is complete, click OK - Continue to proceed\n";
        inspectMessage = inspectMessage + "to the background correction assessment.";
        showControlledInspectionDialog("Inspect preview images", inspectMessage);
    } else {
        inspectMessage = "Review the previous and current preview images\n";
        inspectMessage = inspectMessage + "to assess the current background correction.\n\n";
        inspectMessage = inspectMessage + "TIP - For the best comparison:\n";
        inspectMessage = inspectMessage + "[x] Enable Sync Cursor\n";
        inspectMessage = inspectMessage + "[x] Enable Image Coordinates\n";
        inspectMessage = inspectMessage + "[x] Enable Image Scaling\n";
        inspectMessage = inspectMessage + "Then click Synchronize All.\n\n";
        inspectMessage = inspectMessage + "You can then pan and zoom any preview while matching\n";
        inspectMessage = inspectMessage + "regions remain automatically aligned.\n\n";
        inspectMessage = inspectMessage + "When inspection is complete, click OK - Continue to proceed\n";
        inspectMessage = inspectMessage + "to the background correction assessment.";
        showControlledInspectionDialog("Inspect current and previous results", inspectMessage);
    }

    Dialog.create("Assess Background Correction");
    rateMessage = "Image: " + baseName + "\n\nAssess the suitability of the current background correction setting.\n\nLower RBR values produce stronger background correction. Higher RBR values produce weaker background correction.";
    Dialog.addMessage(rateMessage);
    Dialog.addChoice("Signal refinement assessment", newArray("RBR too low: over-corrected background", "Suitable background correction", "RBR too high: under-corrected background"), "Suitable background correction");
    Dialog.show();

    assessmentResult = Dialog.getChoice();

    // Close the Synchronize Windows controller before closing any preview image.
    // This preserves the original interface and prevents SyncWindows from
    // retaining references to images that are about to be closed.
    if (syncComparisonWindows == 1) {
        closeSynchronizeWindowsSafely();
    }

    if (prevBinaryID != -1) {
        selectImage(prevBinaryID);
        close();
    }

    if (prevProcessedID != -1) {
        selectImage(prevProcessedID);
        close();
    }

    selectImage(binaryID);
    close();

    selectImage(processedID);
    close();

    return assessmentResult;
}

// ============================================================================
// WORKFLOW 2: SIGNAL STANDARDISATION
// ============================================================================

function runSignalStandardisationWorkflow() {
    requires("1.53");

    inputDir = getDirectory("Choose folder containing TIFF images for signal standardisation");
    if (inputDir == "") {
        exit("No input folder selected.");
    }

    outputDir = getDirectory("Choose output folder for standardised TIFF images");
    if (outputDir == "") {
        exit("No output folder selected.");
    }

    Dialog.create("Signal Standardisation Workflow");
    Dialog.addMessage("Apply selected background correction settings across a full image set using a standardised preprocessing workflow.");
    Dialog.addString("Experimental group or image set name", "Group_A");
    Dialog.addString("Output filename suffix", "_standardised");
    Dialog.addChoice("Original image polarity", newArray("Dark background with bright signal", "Light background with dark signal"), "Dark background with bright signal");
    Dialog.addChoice("Output image polarity", newArray("Dark background with bright signal", "Light background with dark signal"), "Dark background with bright signal");
    Dialog.addNumber("Rolling ball radius", 50);
    Dialog.addCheckbox("Light background", false);
    Dialog.addCheckbox("Sliding paraboloid", true);
    Dialog.addCheckbox("Disable smoothing", false);
    Dialog.addCheckbox("Apply median filter to reduce noise after background correction", true);
    Dialog.show();

    groupName = Dialog.getString();
    extension = Dialog.getString();
    inputPolarity = Dialog.getChoice();
    outputPolarity = Dialog.getChoice();
    rbr = Dialog.getNumber();
    lightBackground = Dialog.getCheckbox();
    slidingParaboloid = Dialog.getCheckbox();
    disableSmoothing = Dialog.getCheckbox();
    applyMedian = Dialog.getCheckbox();

    startMs = getTime();
    startDateTime = getTimestampString();

    list = getFileList(inputDir);
    processedCount = 0;
    failedCount = 0;
    failedFiles = "";

    setBatchMode(true);

    for (i = 0; i < list.length; i++) {
        filename = list[i];
        lower = toLowerCase(filename);

        if (endsWith(lower, ".tif") || endsWith(lower, ".tiff")) {
            fullPath = inputDir + filename;

            processOneSignalStandardisationImage(
                fullPath,
                outputDir,
                extension,
                rbr,
                lightBackground,
                slidingParaboloid,
                disableSmoothing,
                inputPolarity,
                applyMedian,
                outputPolarity
            );

            processedCount = processedCount + 1;
        }
    }

    setBatchMode(false);

    endMs = getTime();
    endDateTime = getTimestampString();
    elapsedSeconds = (endMs - startMs) / 1000;

    logPath = outputDir + safeFilename(groupName) + "_signal_standardisation_log.txt";

    writeSignalStandardisationLog(
        logPath,
        groupName,
        startDateTime,
        endDateTime,
        elapsedSeconds,
        inputDir,
        outputDir,
        extension,
        inputPolarity,
        outputPolarity,
        rbr,
        lightBackground,
        slidingParaboloid,
        disableSmoothing,
        applyMedian,
        processedCount,
        failedCount,
        failedFiles
    );

    showMessage("Signal Standardisation Complete", "Signal standardisation completed.\n\nImages processed: " + processedCount + "\nFailed: " + failedCount + "\n\nLog saved to:\n" + logPath);
}

function processOneSignalStandardisationImage(path, outputDir, extension, rbr, lightBackground, slidingParaboloid, disableSmoothing, inputPolarity, applyMedian, outputPolarity) {
    open(path);

    title = getTitle();
    baseName = stripExtension(title);
    baseName = safeFilename(baseName);

    getPixelSize(originalUnit, originalPixelWidth, originalPixelHeight, originalVoxelDepth);

    run("8-bit");

    if (inputPolarity == "Light background with dark signal") {
        run("Invert");
    }

    applyBackgroundCorrection(rbr, lightBackground, slidingParaboloid, disableSmoothing);

    if (applyMedian == 1) {
        run("Median...", "radius=1");
    }

    run("Grays");

    getStatistics(area, mean, min, max, std);

    if (outputPolarity == "Dark background with bright signal") {
        if (mean > 127) {
            run("Invert");
        }
    }

    if (outputPolarity == "Light background with dark signal") {
        if (mean < 127) {
            run("Invert");
        }
    }

    applyCalibration(originalPixelWidth, originalPixelHeight, originalVoxelDepth, originalUnit);

    saveAs("Tiff", outputDir + baseName + extension + ".tif");
    close();
}

// ============================================================================
// SHARED FUNCTIONS
// ============================================================================


function positionSynchronizeWindows() {
    script = "var WM=Packages.ij.WindowManager;";
    script = script + "var GE=Packages.java.awt.GraphicsEnvironment;";
    script = script + "var b=GE.getLocalGraphicsEnvironment().getMaximumWindowBounds();";
    script = script + "var gap=10; var sw=WM.getWindow('Synchronize Windows');";
    script = script + "if(sw!=null){var swW=Math.min(860,Math.floor(b.width*0.55)); var swH=225;";
    script = script + "sw.setBounds(b.x+gap,b.y+b.height-swH-gap,swW,swH); sw.validate(); sw.toFront();}";
    eval("script", script);
    wait(150);
}

function showControlledInspectionDialog(dialogTitle, dialogMessage) {
    // Non-blocking ImageJ dialog: images and Synchronize Windows remain usable.
    // Short wrapped lines, ASCII markers and an explicit button label keep the
    // instructions readable and fully on-screen.
    safeTitle = replace(dialogTitle, "\"", "'");
    safeMessage = replace(dialogMessage, "\"", "'");
    safeMessage = replace(safeMessage, "\n", "\\n");

    script = "var GD=Packages.ij.gui.NonBlockingGenericDialog;";
    script = script + "var GE=Packages.java.awt.GraphicsEnvironment;";
    script = script + "var b=GE.getLocalGraphicsEnvironment().getMaximumWindowBounds();";
    script = script + "var gd=new GD('" + safeTitle + "');";
    script = script + "gd.addMessage('" + safeMessage + "');";
    script = script + "gd.setOKLabel('OK - Continue');";
    script = script + "gd.hideCancelButton();";
    script = script + "gd.pack();";
    script = script + "var x=b.x+b.width-gd.getWidth()-15;";
    script = script + "var y=b.y+b.height-gd.getHeight()-15;";
    script = script + "gd.setLocation(Math.max(b.x+15,x),Math.max(b.y+15,y));";
    script = script + "gd.showDialog();";
    eval("script", script);
}

function closeSynchronizeWindowsSafely() {
    if (isOpen("Synchronize Windows")) {
        selectWindow("Synchronize Windows");
        run("Close");
        wait(150);
    }
}

function applyBackgroundCorrection(rbr, lightBackground, slidingParaboloid, disableSmoothing) {
    options = "rolling=" + rbr;

    if (lightBackground == 1) {
        options = options + " light";
    }

    if (slidingParaboloid == 1) {
        options = options + " sliding";
    }

    if (disableSmoothing == 1) {
        options = options + " disable";
    }

    // FIJI/ImageJ command name retained for functionality.
    run("Subtract Background...", options);
}

function applyCalibration(pixelWidth, pixelHeight, voxelDepth, unit) {
    setVoxelSize(pixelWidth, pixelHeight, voxelDepth, unit);
}

function applyLUT(lutName) {
    if (lutName == "Fire") {
        run("Fire");
    } else if (lutName == "Grays") {
        run("Grays");
    } else if (lutName == "Green") {
        run("Green");
    } else if (lutName == "Cyan") {
        run("Cyan");
    } else if (lutName == "Magenta") {
        run("Magenta");
    } else if (lutName == "Red") {
        run("Red");
    } else if (lutName == "Blue") {
        run("Blue");
    } else {
        run("Fire");
    }
}

function writeSignalRefinementLog(logPath, groupName, inputPolarity, finalRBR, finalLightBackground, finalSlidingParaboloid, finalDisableSmoothing, finalApplyMedian, numTestImages, roundCount, outputBase, optDir, testedSettingsLog, testedImageAssessmentLog) {
    text = "TINA Signal Refinement Log\n";
    text = text + "==========================\n\n";
    text = text + "Software name: TINA\n";
    text = text + "Description: A workflow for microscopy image optimisation and batch preprocessing prior to quantitative analysis.\n";
    text = text + "Version: 1.0.1\n";
    text = text + "Experimental group or image set name: " + groupName + "\n";
    text = text + "Date/time: " + getTimestampString() + "\n";
    text = text + "Original image polarity: " + inputPolarity + "\n";
    text = text + "Calibration metadata: Pixel width, pixel height, voxel depth, and unit were preserved from the original image where available.\n";
    text = text + "Synchronisation note: click Synchronize All if the sync panel opens.\n";
    text = text + "Number of test images used: " + numTestImages + "\n";
    text = text + "Number of signal refinement rounds tested: " + roundCount + "\n";
    text = text + "Output base folder: " + outputBase + "\n";
    text = text + "Signal refinement folder: " + optDir + "\n\n";

    text = text + "Selected background correction settings\n";
    text = text + "---------------------------------------\n";
    text = text + "Selected rolling ball radius: " + finalRBR + "\n";
    text = text + "Light background: " + yesNo(finalLightBackground) + "\n";
    text = text + "Sliding paraboloid: " + yesNo(finalSlidingParaboloid) + "\n";
    text = text + "Disable smoothing: " + yesNo(finalDisableSmoothing) + "\n";
    text = text + "Median filter for noise reduction after background correction: " + yesNo(finalApplyMedian) + "\n\n";

    text = text + "All tested background correction settings\n";
    text = text + "-----------------------------------------\n";
    text = text + testedSettingsLog + "\n";

    text = text + "Per-image signal refinement assessment log\n";
    text = text + "------------------------------------------\n";
    text = text + testedImageAssessmentLog + "\n";

    text = text + "Assessment guide\n";
    text = text + "----------------\n";
    text = text + "RBR too low: over-corrected background means the rolling ball radius was too low and may have removed too much background or biological signal.\n";
    text = text + "Suitable background correction means the background correction setting was appropriate for the image.\n";
    text = text + "RBR too high: under-corrected background means the rolling ball radius was too high and may have left residual background or noise.\n";
    text = text + "Median filtering was included as an optional noise reduction step after background correction.\n\n";

    text = text + "Processing workflow used for preview images\n";
    text = text + "-------------------------------------------\n";
    text = text + "1. Open manually selected TIFF image.\n";
    text = text + "2. Record original image calibration metadata.\n";
    text = text + "3. Convert to 8-bit.\n";
    text = text + "4. Invert first if user specified light background with dark signal.\n";
    text = text + "5. Apply ImageJ/FIJI background correction using the Subtract Background command.\n";
    text = text + "6. Apply median filter radius 1 for noise reduction if selected.\n";
    text = text + "7. Reapply original calibration metadata.\n";
    text = text + "8. Save processed preview TIFF.\n";
    text = text + "9. Duplicate processed image.\n";
    text = text + "10. Convert duplicate to binary using Make Binary.\n";
    text = text + "11. Reapply original calibration metadata.\n";
    text = text + "12. Save binary preview TIFF.\n";

    File.saveString(text, logPath);
}

function writeSignalStandardisationLog(logPath, groupName, startDateTime, endDateTime, elapsedSeconds, inputDir, outputDir, extension, inputPolarity, outputPolarity, rbr, lightBackground, slidingParaboloid, disableSmoothing, applyMedian, processedCount, failedCount, failedFiles) {
    text = "TINA Signal Standardisation Log\n";
    text = text + "===============================\n\n";
    text = text + "Software name: TINA\n";
    text = text + "Description: A workflow for microscopy image optimisation and batch preprocessing prior to quantitative analysis.\n";
    text = text + "Version: 1.0.1\n";
    text = text + "Experimental group or image set name: " + groupName + "\n";
    text = text + "Start date/time: " + startDateTime + "\n";
    text = text + "End date/time: " + endDateTime + "\n";
    text = text + "Total time to complete: " + elapsedSeconds + " seconds\n\n";

    text = text + "Input folder: " + inputDir + "\n";
    text = text + "Output folder: " + outputDir + "\n";
    text = text + "Output filename suffix: " + extension + "\n\n";

    text = text + "Original image polarity: " + inputPolarity + "\n";
    text = text + "Output image polarity: " + outputPolarity + "\n";
    text = text + "Rolling ball radius: " + rbr + "\n";
    text = text + "Light background: " + yesNo(lightBackground) + "\n";
    text = text + "Sliding paraboloid: " + yesNo(slidingParaboloid) + "\n";
    text = text + "Disable smoothing: " + yesNo(disableSmoothing) + "\n";
    text = text + "Median filter for noise reduction after background correction: " + yesNo(applyMedian) + "\n";
    text = text + "Calibration metadata: Pixel width, pixel height, voxel depth, and unit were preserved from the original image where available.\n\n";

    text = text + "Processing workflow used for signal standardisation\n";
    text = text + "--------------------------------------------------\n";
    text = text + "1. Open TIFF image.\n";
    text = text + "2. Record original image calibration metadata.\n";
    text = text + "3. Convert to 8-bit.\n";
    text = text + "4. Invert first if user specified light background with dark signal.\n";
    text = text + "5. Apply ImageJ/FIJI background correction using the Subtract Background command.\n";
    text = text + "6. Apply median filter radius 1 for noise reduction if selected.\n";
    text = text + "7. Convert image display to Grays LUT.\n";
    text = text + "8. Enforce selected output image polarity.\n";
    text = text + "9. Reapply original calibration metadata.\n";
    text = text + "10. Save standardised TIFF image.\n\n";

    text = text + "Number of images processed: " + processedCount + "\n";
    text = text + "Number of images failed: " + failedCount + "\n";

    if (failedCount == 0) {
        text = text + "Completion status: Completed successfully.\n";
    } else {
        text = text + "Completion status: Completed with errors.\n";
        text = text + "Failed filenames:\n" + failedFiles + "\n";
    }

    File.saveString(text, logPath);
}

function getTimestampString() {
    getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

    month = month + 1;

    monthText = "" + month;
    dayText = "" + dayOfMonth;
    hourText = "" + hour;
    minuteText = "" + minute;
    secondText = "" + second;

    if (month < 10) {
        monthText = "0" + month;
    }
    if (dayOfMonth < 10) {
        dayText = "0" + dayOfMonth;
    }
    if (hour < 10) {
        hourText = "0" + hour;
    }
    if (minute < 10) {
        minuteText = "0" + minute;
    }
    if (second < 10) {
        secondText = "0" + second;
    }

    timestampText = "" + year + "-" + monthText + "-" + dayText + " " + hourText + ":" + minuteText + ":" + secondText;
    return timestampText;
}

function getBaseNameFromPath(path) {
    slash = lastIndexOf(path, File.separator);

    if (slash == -1) {
        slash = lastIndexOf(path, "/");
    }

    filename = path;

    if (slash != -1) {
        filename = substring(path, slash + 1);
    }

    filename = stripExtension(filename);
    filename = safeFilename(filename);

    return filename;
}

function stripExtension(filename) {
    dot = lastIndexOf(filename, ".");

    if (dot == -1) {
        return filename;
    }

    shortName = substring(filename, 0, dot);
    return shortName;
}

function safeFilename(text) {
    text = replace(text, " ", "_");
    text = replace(text, "/", "_");
    text = replace(text, ":", "_");
    text = replace(text, "*", "_");
    text = replace(text, "?", "_");
    text = replace(text, "\"", "_");
    text = replace(text, "<", "_");
    text = replace(text, ">", "_");
    text = replace(text, "|", "_");
    text = replace(text, "(", "_");
    text = replace(text, ")", "_");
    text = replace(text, "[", "_");
    text = replace(text, "]", "_");

    return text;
}

function cleanNumberForFilename(numberValue) {
    s = "" + numberValue;
    s = replace(s, ".", "p");
    return s;
}

function yesNo(value) {
    if (value == 1) {
        return "Yes";
    }

    return "No";
}
