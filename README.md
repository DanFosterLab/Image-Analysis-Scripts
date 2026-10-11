# Image-Analysis-Scripts
Scripts for various steps of the image analysis process.

The current version of this repository can be cited via Zenodo: https://doi.org/10.5281/zenodo.23301431

**Puncta Detection Threshold Optimization** (Groovy script for QuPath)
  - Optimizes mRNA spot-detection thresholds for Channels 1 (red) and 2 (green) using a **control** region with known expression levels.
  - The resulting detection thresholds can then be applied consistently to an **experimentally** altered region.
  - To change the desired positivity ranges, edit:
    - ch1TargetMin and ch1TargetMax for Channel 1
    - ch2TargetMin and ch2TargetMax for Channel 2

**Save ROI Customer Overlays** (Fiji [Is Just ImageJ] ROI manager)
  - Once ROIs are created and saved as .roi files, this script allows for bulk changes to generate new ROIs with a chosen color (RGB format: RRGGBB) and transparency percentage.
  - New ROIs are saved with original name appended with the transparency percentage and RGB color code to identify settings used to generate.
  - No files are required to be opened in Fiji beforehand, merely go to Fiji > Plugins > Macros > Run.
  - The script offers a drop-down with 3 modes:
      1. **Generate new ROIs only** - Choose the directory containing the ROI files, new files will be saved in the same directory.
      2. **Generate new ROIs and open them in ROI Manager** - ROIs created as before but all open to be manually inspected and added to a background image.
      3. **Generate new ROIs and create a flattened image** - Creates ROIs as before, then asks for background image. New ROIs are layered onto the background image, flattened, and the resultant image is saved (same extension as background image), appended with transparency and RGB code.
