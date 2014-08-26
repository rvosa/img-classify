Splitter output
===============
This directory demonstrates the input and output of the 
`splitter.pl` script, which segments input images (such
as img004_s.png in this folder) into the separated 
components of the image. The output consists of zero or
more images whose filenames consist of the x,y coordinates
of the first pixel of the component that was encountered
when traversing from left to right, top to bottom. As such,
components of the input image can be reconciled with other
data organized similarly by sorting the output files 
numerically.
