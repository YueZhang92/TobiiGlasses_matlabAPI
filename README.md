# TobiiGlasses_matlabAPI
Matlab scripts using Tobii Pro 2 Glasses API for running psychology experiments

Complete Tobii API can be downloaded on Tobii official website: https://www.tobiipro.com/product-listing/tobii-pro-glasses-2-sdk/.
While they provide Python examples, there is no Matlab example scripts to demonstrate how to interact with the Tobii Glasses.

- TobiiGlass.m contains a class object with functions documented in the API, executable in Matlab.
- listenPupil.m provides a working example of using TobiiGlass class for a simple recording of listeners gaze/pupil size during listening to a BEL English sentence.

# Running
- add TobiiGlass.m in MATLAB path
- import TobiiGlass.m in the local script
`import TobiiGlass`
- call the functions in TobiiGlass.m from the local script
`tb = TobiiGlass`
