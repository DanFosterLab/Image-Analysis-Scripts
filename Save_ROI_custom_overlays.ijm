// ==================================================
// BATCH ROI COLOR / OPACITY PROCESSOR
// ==================================================
// Options:
//
// 1 = Generate new ROIs only
// 2 = Generate new ROIs and open them in ROI Manager
// 3 = Generate new ROIs and create a flattened image
//
// Original ROI:
//     CA1.roi
//
// Example settings:
//     Color:   FF0000
//     Opacity: 10%
//
// Output ROI:
//     CA1__10_FF0000.roi
//
// The internal ROI Manager name is also:
//     CA1__10_FF0000
//
// Any ROI filename containing "__" is considered
// already processed and is skipped.
// ==================================================

//requires("1.54e");


// --------------------------------------------------
// SELECT ACTION
// --------------------------------------------------

Dialog.create("Batch ROI Processor");

actions = newArray(
    "1 - Generate new ROIs only",
    "2 - Generate and open all",
    "3 - Generate and create flattened image"
);

Dialog.addChoice("Action:", actions, actions[0]);

Dialog.show();

action = Dialog.getChoice();

if (action == "2 - Generate and open all") {

    imagePath = File.openDialog(
        "Choose background image."
    );

    if (imagePath == "")
        exit("Canceled.");

    open(imagePath);

}

// --------------------------------------------------
// CHOOSE ROI FOLDER
// --------------------------------------------------

dir = getDirectory("Choose original ROI directory.");

if (dir == "")
    exit("Canceled.");


// --------------------------------------------------
// COLOR / OPACITY DIALOG
// --------------------------------------------------

Dialog.create("ROI Color / Opacity");

Dialog.addString(
    "Color (RRGGBB):",
    "FF0000",
    8
);

Dialog.addNumber(
    "Opacity (%):",
    10,
    0,
    4,
    "%"
);

Dialog.show();

rgb = Dialog.getString();
opacity = Dialog.getNumber();


// --------------------------------------------------
// CLEAN AND VALIDATE COLOR
// --------------------------------------------------

rgb = toUpperCase(trim(rgb));

// Allow user to enter #FF0000 as well as FF0000
if (startsWith(rgb, "#"))
    rgb = substring(rgb, 1);

if (!matches(rgb, "[0-9A-F]{6}"))
    exit(
        "Invalid color.\n\n" +
        "Enter exactly six hexadecimal characters.\n\n" +
        "Examples:\n" +
        "FF0000 = red\n" +
        "00FF00 = green\n" +
        "0000FF = blue\n" +
        "808080 = gray"
    );

if (opacity < 0 || opacity > 100)
    exit("Opacity must be between 0 and 100.");


// --------------------------------------------------
// CONVERT OPACITY (%) TO ALPHA (AA)
// --------------------------------------------------
// AARRGGBB format:
//     AA = opacity
//     RR = red
//     GG = green
//     BB = blue
//
// Example:
//     10% -> approximately 1A
//     50% -> 80
//     100% -> FF
// --------------------------------------------------

alphaDecimal = round((opacity / 100) * 255);

hexDigits = "0123456789ABCDEF";

firstDigit = floor(alphaDecimal / 16);
secondDigit = alphaDecimal - (firstDigit * 16);

alphaHex =
    substring(hexDigits, firstDigit, firstDigit + 1) +
    substring(hexDigits, secondDigit, secondDigit + 1);

// Complete AARRGGBB value
fillColor = alphaHex + rgb;


// --------------------------------------------------
// CREATE HUMAN-READABLE OUTPUT SUFFIX
// --------------------------------------------------
// The filename records the ORIGINAL percentage,
// Example:
//     "10% + FF0000" -> "__10_FF0000"
// --------------------------------------------------

opacityText = "" + opacity;

suffix = "__" + opacityText + "_" + rgb;


// --------------------------------------------------
// FIND ROI FILES
// --------------------------------------------------

files = getFileList(dir);

found = 0;
processed = 0;
skipped = 0;


// --------------------------------------------------
// PROCESS ROIS
// --------------------------------------------------

for (i = 0; i < files.length; i++) {

    file = files[i];

    // Only process .roi files
    if (!endsWith(toLowerCase(file), ".roi"))
        continue;

    found++;

    // ------------------------------------------------
    // SKIP ANY FILE CONTAINING "__"
    // ------------------------------------------------

    if (indexOf(file, "__") != -1) {
        skipped++;
        continue;
    }


    // ------------------------------------------------
    // DETERMINE NAMES
    // ------------------------------------------------

    baseName = File.getNameWithoutExtension(file);

    newName = baseName + suffix;

    inputPath = dir + file;

    outputPath = dir + newName + ".roi";


    // ------------------------------------------------
    // OPEN ORIGINAL ROI
    // ------------------------------------------------

    open(inputPath);


    // ------------------------------------------------
    // MODIFY ROI
    // ------------------------------------------------

    Roi.setFillColor(fillColor);

    // Match your original script:
    Roi.setStrokeWidth(0);

    // Rename ROI so that the new descriptive name
    // appears in ROI Manager.
    Roi.setName(newName);


    // ------------------------------------------------
    // SAVE NEW ROI
    // ------------------------------------------------

    save(outputPath);

    processed++;


    // ------------------------------------------------
    // OPTION 2:
    // ADD NEW ROI TO ROI MANAGER
    // ------------------------------------------------

    if (action == "2 - Generate and open all") {

        roiManager("open", outputPath);

    }

}


// --------------------------------------------------
// OPTION 3:
// CREATE FLATTENED IMAGE
// --------------------------------------------------

if (action == "3 - Generate and create flattened image") {

    // ------------------------------------------------
    // ASK USER FOR IMAGE
    // ------------------------------------------------

    imagePath = File.openDialog(
        "Choose background image."
    );

    if (imagePath == "")
        exit("Canceled.");


    // ------------------------------------------------
    // OPEN IMAGE
    // ------------------------------------------------

    open(imagePath);


    // ------------------------------------------------
    // GET IMAGE INFORMATION
    // ------------------------------------------------

    imageName = File.getNameWithoutExtension(imagePath);
    imageExtension = File.getName(imagePath);

    dot = lastIndexOf(imageExtension, ".");

    if (dot < 0)
        exit("Could not determine the image file extension.");

    extension = substring(imageExtension, dot);


    // ------------------------------------------------
    // ADD GENERATED ROIS TO IMAGE OVERLAY
    // ------------------------------------------------
    // User's ROI Manager deliberately not reset.
    //
    // Each generated ROI is opened as a selection
    // and then added directly to the image overlay.
    // ------------------------------------------------

    for (i = 0; i < files.length; i++) {

        file = files[i];

        if (!endsWith(toLowerCase(file), ".roi"))
            continue;

        // Skip original files that were not processed
        // because they contained "__".
        if (indexOf(file, "__") != -1)
            continue;

        baseName = File.getNameWithoutExtension(file);

        newName = baseName + suffix;

        outputPath = dir + newName + ".roi";

        // Open generated ROI
        open(outputPath);

        // Add current ROI to image overlay
        Overlay.addSelection();

    }


    // ------------------------------------------------
    // FLATTEN
    // ------------------------------------------------

    run("Flatten");


    // ------------------------------------------------
    // SAVE FLATTENED IMAGE
    // ------------------------------------------------
    //
    // Same folder as the generated ROIs.
    // Same image extension as the source image.
    //
    // Example:
    // MouseAtlas.png -> MouseAtlas__10_FF0000.png
    // ------------------------------------------------

    outputImagePath =
        dir + imageName + suffix + extension;

    save(outputImagePath);

    close("*");

}


// --------------------------------------------------
// FINAL REPORT
// --------------------------------------------------

message =
    "Batch ROI processing complete." +
    "\n\nColor: #" + rgb +
    "\nOpacity: " + opacity + "%" +
    "\nAARRGGBB: " + fillColor +
    "\n\nROI files found: " + found +
    "\nROIs generated: " + processed +
    "\nROIs skipped: " + skipped;

if (action == "3 - Generate and create flattened image") {

    message =
        message +
        "\n\nFlattened image saved as:" +
        "\n" + outputImagePath;

}

showMessage("Batch ROI Processor", message);