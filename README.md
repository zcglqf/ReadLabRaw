# ReadLabRaw
Matlab Program to read Philips MR raw data

This matlab package is developed based on an early package from Welcheb.

The DDAS data ( which is encoded ) reading capability is added.

To use this package, add the folder to Matlab path.

Syntax: 
[data, info] = main_loadLABRAW('mydata.lab');

 'data' is a multi-dimentional matrix that can be viewed using other tools.
 'info' contains information of the data.
 note: the files 'mydata.sin', 'mydata.lab', 'mydata.raw' should be all existing.

Remarks:
For special scans, you may need to slightly modify the program to run it through. The special scans include:
  CoilSurveyScan
  
  SenseRefScan
  
  Spectroscopy Scan
  
  None Cartesian Scan

MATLAB Version: 8.0.0.783 (R2012b)

Contact:
Chenguang Zhao, Philips Healthcare (Suzhou) MR

chenguang.z.zhao@philips.com
