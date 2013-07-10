#include <stdio.h>
#include <stdlib.h>
#include <wand/MagickWand.h>
#include "types.h"

// http://docs.opencv.org/2.4.6/modules/imgproc/doc/imgproc.html
// http://bsd-noobz.com/opencv-guide/60-2-color-based-object-segmentation
// http://docs.opencv.org/2.4.6/doc/user_guide/ug_traincascade.html

// constructor for phenotype structs
PhenoType *NewPhenoType(int bin_size) 
{
	PhenoType *result = (PhenoType*) malloc(sizeof(PhenoType));
	result->size = bin_size;
	return result;
}

// scales the values of the phenotype between a min and max value
void normalize_phenotype(PhenoType *pt,double min,double max) {

	// find the highest and lowest values in our data set
	double current_min = pt->data[0];
	double current_max = pt->data[0];
	for ( int i = 1; i < pt->size; i++ ) {
		if ( pt->data[i] > current_max ) {
			current_max = pt->data[i];
		}
		if ( pt->data[i] < current_min ) {
			current_min = pt->data[i];
		}
	}
	
	// compute the scaling factor
	double scale = ( max - min ) / ( current_max - current_min );
	
	// now re-scale
	for ( int i = 0; i < pt->size; i++ ) {
		double value = pt->data[i];
		pt->data[i] = ( ( value - current_min ) * scale ) + min;
	}
	
}

// example algorithm
PhenoType *average_pixel_value(MagickWand *wand, int bin_size) 
{
	// instantiate helper objects
 	PixelIterator *iterator = NewPixelIterator(wand);
	PhenoType *result = NewPhenoType(bin_size * 2);
	
	// get image dimensions
 	unsigned long width = MagickGetImageWidth(wand);
 	unsigned long height = MagickGetImageHeight(wand);
 	
 	// this is how many pixels it takes until we've filled a 
 	// bin over which to compute some value
 	int horiz_bin = width / bin_size;
 	int vert_bin  = height / bin_size;
 	
 	// will have a running tally over these
 	double x_sum = 0.0;
 	double y_sum = 0.0;

 	// iterate over rows
 	for ( int y = 0; y < height; y++ ) 
 	{
 	
 		// iterate over columns
 		PixelWand **row;
		row = PixelGetNextIteratorRow(iterator,&width); 	
 		for ( int x  = 0; x < width; x++ ) 
 		{

			// get RGB values
			unsigned char red   = PixelGetRedQuantum(row[x]);
			unsigned char green = PixelGetGreenQuantum(row[x]);
			unsigned char blue  = PixelGetBlueQuantum(row[x]);
			double pixel_average = ( red + green + blue ) / 3;	
			x_sum += pixel_average;
			y_sum += pixel_average;
			
			// the column number is a multiple of bin
			if ( x % horiz_bin == 0 ) 
			{
				int x_idx = x / horiz_bin;
				result->data[x_idx] += x_sum / horiz_bin;
				x_sum = 0.0;
			}			
 		}
 		
 		// the row number is a multiple of bin
		if ( y % vert_bin == 0 ) 
		{
			int y_idx = ( y / vert_bin ) + bin_size;
			if ( y_idx < result->size ) {
				result->data[y_idx] += y_sum / vert_bin;
				y_sum = 0.0;
			}
			else {
				//printf("ignoring edges at %d\n", y_idx);
			}
		} 			
 	}	
 	 	
	// clean up
	iterator = DestroyPixelIterator(iterator); 	
	return result;
}

int main(int argc,char **argv) 
{
	MagickWand *wand;
  	
	// set things up
	MagickWandGenesis();
	wand = NewMagickWand();
	printf("initialized MagickWand\n");
	
	// read image
	MagickReadImage(wand, argv[1]);
	printf("read image %s\n", argv[1]);

	// parse bin size
	int bin_size = strtoul( argv[2], NULL, 10 );
	printf("bin size %i\n", bin_size);
	
	// compute a phenotype
	PhenoType *pt = average_pixel_value(wand,bin_size);
	
	// rescale 
	normalize_phenotype(pt,-1.0,1.0);
	
	for ( int i = 0; i < bin_size; i++ ) {
		printf("%f\t%f\n", pt->data[i], pt->data[i+bin_size]);
	}
	
	// tear things down
	wand = DestroyMagickWand(wand);
	MagickCoreTerminus();
	return(0);
}