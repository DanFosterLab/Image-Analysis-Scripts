# Image-Analysis-Scripts
Scripts for various applications for various steps of the image analysis process.

Puncta Detection Threshold Optimization (Groovy script for QuPath)
  - Optimizes mRNA spot-detection thresholds for Channels 1 (red) and 2 (green) using a control region with known expression levels, so the resulting thresholds can be applied consistently to an experimentally altered region.
  - To change the desired positivity ranges, edit:
    - ch1TargetMin and ch1TargetMax for Channel 1
    - ch2TargetMin and ch2TargetMax for Channel 2

Save ROI Customer Overlays (Fiji [Is Just ImageJ] ROI manager)
  - Once ROIs are created and saved as .roi files, this script allow for bulk changes to generate new ROIs with chosen color (RGB format: RRGGBB) and transparency percentage.
  - New ROIs are saved with original name appended with the transparency percentage and RGB color code added to identify settings used to generate.
  - No files are required to be opened before hand, merely go to Fiji > Plugins > Macros > Run
  - The script offers a drop-down with 3 modes:
      1. Create new ROIs only. Choose the directory containing the ROI files, new files will be saved in the same directory.
      2. Create and open new ROIs in ROI manager. ROIs created as before but all open to be manually inspected and added to a background image.
      3. Create ROIs, overlay on background, and save new image. Creates ROIs as before, then asks for background image. New ROIs are layered onto the background image, flattened, and the resultant image is saved with the same extension as original background (appended with transparency and RGB code).
