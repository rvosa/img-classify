#include <stdio.h>
#include <stdlib.h>
#include <wand/MagickWand.h>

// holds a set of values resulting from one of the phenotyping algorithms
typedef struct PhenoType {
	int size;
	double *data;
} PhenoType;

// constructor for phenotype structs
PhenoType *NewPhenoType(int bin_size) 
{
	PhenoType *result = (PhenoType*) malloc(sizeof(PhenoType));
	double data[bin_size];
	result->size = bin_size;
	result->data = data;
	return result;
}

// example algorithm
PhenoType *average_pixel_value(MagickWand *wand, int bin_size) 
{
 	PixelIterator *iterator = NewPixelIterator(wand);
	Quantum red, green, blue; // i.e. unsigned short
	PixelWand **row;
	printf("initialized helper objects\n");
	
	// create a new phenotype struct
	PhenoType *result = NewPhenoType(bin_size * 2);
	printf("initialized PhenoType result data structure\n");
	
	// get image dimensions
 	unsigned long width = MagickGetImageWidth(wand);
 	unsigned long height = MagickGetImageHeight(wand);
 	printf("image width is %lu\n",width);
 	printf("image height is %lu\n",height);
 	
 	// this is how many pixels it takes until we've filled a bin over which to compute
 	int horiz_bin = width / bin_size;
 	int vert_bin  = height / bin_size;
 	printf("horizontal bin size is %d pixels\n", horiz_bin);
 	printf("vertical bin size is %d pixels\n", vert_bin);
 	
 	// will have a running tally over these
 	double x_average = 0.0;
 	double y_average = 0.0;
 	

 	// iterate over pixels
 	for ( int y = 0; y < height; y++ ) 
 	{
		row = PixelGetNextIteratorRow(iterator,&width); 	
 		for ( int x  = 0; x < width; x++ ) 
 		{

			// get RGB values
			red   = PixelGetRedQuantum(row[x]);
			green = PixelGetGreenQuantum(row[x]);
			blue  = PixelGetBlueQuantum(row[x]);
			
			x_average = x_average + red + green + blue;
			y_average = y_average + red + green + blue;
			
			if ( x % horiz_bin == 0 ) 
			{
				int x_idx = x / horiz_bin;
				result->data[x_idx] = result->data[x_idx] + x_average;
				x_average = 0.0;
			}
 		}
		if ( y % vert_bin == 0 ) 
		{
			int y_idx = ( y / vert_bin ) + bin_size;
			printf("%d\n",y_idx);
			result->data[y_idx] = result->data[y_idx] + y_average;
			y_average = 0.0;
		} 		
 	}
 	
 	// now divide
 	for ( int i = 0; i < bin_size; i++ ) 
 	{
 		result->data[i] = result->data[i] / 3 / horiz_bin;
 		result->data[i+bin_size] = result->data[i+bin_size] / 3 / vert_bin;
 		printf("bin %d, x value %f, y value %f\n", i, result->data[i], result->data[i+bin_size]); 		
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
	
	for ( int i = 0; i < bin_size; i++ ) {
		printf("%f\t%f\n", pt->data[i], pt->data[i+bin_size]);
	}
	
	// tear things down
	wand = DestroyMagickWand(wand);
	MagickCoreTerminus();
	return(0);
}