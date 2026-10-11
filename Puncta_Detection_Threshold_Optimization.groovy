//------------------------------------------------------------
// USER SETTINGS
//------------------------------------------------------------

// Desired fraction of positive cells

double ch1TargetMin = 0.4
double ch1TargetMax = 0.5

double ch2TargetMin = 0.85
double ch2TargetMax = 0.95

//------------------------------------------------------------
// Initial thresholds

double ch1Threshold = 100.0
double ch2Threshold = 1.0

//------------------------------------------------------------
// Initial step sizes

double ch1Step = 20.0
double ch2Step = 0.5

//------------------------------------------------------------

double minimumStep = 0.05

//------------------------------------------------------------
// Fixed plugin parameters
//------------------------------------------------------------

def params = [
        "detection[Channel 1]":100.0,
        "detection[Channel 2]":1.0,
        "detection[Channel 3]":-1.0,
        "doSmoothing":true,
        "splitByIntensity":true,
        "splitByShape":true,
        "spotSizeMicrons":0.5,
        "minSpotSizeMicrons":0.5,
        "maxSpotSizeMicrons":15.0,
        "includeClusters":true
]

//------------------------------------------------------------
// Build plugin JSON
//------------------------------------------------------------

def buildJSON = { p ->

    return """{
"detection[Channel 1]":${p["detection[Channel 1]"]},
"detection[Channel 2]":${p["detection[Channel 2]"]},
"detection[Channel 3]":${p["detection[Channel 3]"]},
"doSmoothing":${p["doSmoothing"]},
"splitByIntensity":${p["splitByIntensity"]},
"splitByShape":${p["splitByShape"]},
"spotSizeMicrons":${p["spotSizeMicrons"]},
"minSpotSizeMicrons":${p["minSpotSizeMicrons"]},
"maxSpotSizeMicrons":${p["maxSpotSizeMicrons"]},
"includeClusters":${p["includeClusters"]}
}"""
}

//------------------------------------------------------------
// Run Subcellular Detection
//------------------------------------------------------------

def runSubcellular = {

    runPlugin(
        'qupath.imagej.detect.cells.SubcellularDetection',
        buildJSON(params)
    )

}

//------------------------------------------------------------
// Calculate fraction of positive cells
//------------------------------------------------------------

def fractionPositive = { int channel ->

    String measurement =
            "Subcellular: Channel ${channel}: Num spots estimated"

    def cells = getCellObjects()

    if (cells.isEmpty())
        return Double.NaN

    int positive = 0

    cells.each { cell ->

        double value =
                cell.getMeasurementList().get(measurement)

        if (!Double.isNaN(value) && value > 0)
            positive++

    }

    return positive / (double)cells.size()

}

//------------------------------------------------------------
// Evaluate a threshold
//------------------------------------------------------------

def evaluateThreshold = { int channel, double threshold ->

    params["detection[Channel ${channel}]"] = threshold

    runSubcellular()

    return fractionPositive(channel)

}

//------------------------------------------------------------
// Adaptive optimizer
//------------------------------------------------------------

def optimizeChannel = { int channel,
                        double initialThreshold,
                        double initialStep,
                        double targetMin,
                        double targetMax ->

    double threshold = initialThreshold
    double step = initialStep

    double target = (targetMin + targetMax)/2.0

    double bestThreshold = threshold
    double bestFraction = Double.NaN
    double bestError = Double.MAX_VALUE

    int previousDirection = 0

    while(step > minimumStep){

        double fraction = evaluateThreshold(channel, threshold)

        println(String.format(
                "Ch%d  Threshold %.3f  Positive %.2f%%",
                channel,
                threshold,
                fraction*100))

        //----------------------------------------------------
        // Keep best solution
        //----------------------------------------------------

        double error = Math.abs(fraction-target)

        if(error < bestError){

            bestError = error
            bestThreshold = threshold
            bestFraction = fraction

        }

        //----------------------------------------------------
        // Stop if inside target range
        //----------------------------------------------------

        if(fraction >= targetMin &&
           fraction <= targetMax){

            println("Target range reached.")
            break

        }

        //----------------------------------------------------
        // Search direction
        //----------------------------------------------------

        int direction

        if(fraction > targetMax){

            // too many positive cells
            direction = 1

        }else{

            // too few positive cells
            direction = -1

        }

        //----------------------------------------------------
        // Reduce step after overshooting
        //----------------------------------------------------

        if(previousDirection != 0 &&
           direction != previousDirection){

            step /= 2.0

            println(String.format(
                    "Reducing step to %.3f",
                    step))

        }

        threshold += direction*step

        previousDirection = direction

    }

    return [
            threshold : bestThreshold,
            fraction  : bestFraction
    ]

}

println("")
println("----------------------------------------")
println("Optimizing Channel 1")
println("----------------------------------------")

def ch1 = optimizeChannel(
        1,
        ch1Threshold,
        ch1Step,
        ch1TargetMin,
        ch1TargetMax)

params["detection[Channel 1]"] = ch1.threshold

println("")
println("----------------------------------------")
println("Optimizing Channel 2")
println("----------------------------------------")

def ch2 = optimizeChannel(
        2,
        ch2Threshold,
        ch2Step,
        ch2TargetMin,
        ch2TargetMax)

params["detection[Channel 2]"] = ch2.threshold

//------------------------------------------------------------
// Final detection
//------------------------------------------------------------

println("")
println("----------------------------------------")
println("Running final detection")
println("----------------------------------------")

runSubcellular()

double finalCh1 = fractionPositive(1)
double finalCh2 = fractionPositive(2)

println("")
println("========================================")
println("Optimization complete")
println("========================================")
println(String.format(
        "Channel 1 threshold : %.3f",
        ch1.threshold))
println(String.format(
        "Channel 1 positivity: %.2f%%",
        finalCh1*100))

println("")

println(String.format(
        "Channel 2 threshold : %.3f",
        ch2.threshold))
println(String.format(
        "Channel 2 positivity: %.2f%%",
        finalCh2*100))
println("========================================")
