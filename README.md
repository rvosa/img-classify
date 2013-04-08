img-classify
============

This repository contains code and examples that demonstrate the ability for artificial
neural networks to classify images of insect specimens. The layout is as follows:

* lib: contains a utility class that does image pre-processing
* data/img: contains training and testing data with pictures of beetles and butterflies 
* data/traindata: contains tab-separated tables of "fingerprints" of training images
* data/ai: contains a stored AI
* script/splitter.pl: a naive implementation of an image segmentation algorithm
* script/traindata.pl: generates "fingerprints" of images as tab-separated tables
* script/trainai.pl: feeds training data into the ANN
* script/classify.pl: classifies a directory of out-of-sample images

dependencies
============
* ImageMagick (c library) and Image::Magick (perl bindings)
* FANN (c library) and AI::FANN (perl bindings)
* Bio::Phylo (for logging)

