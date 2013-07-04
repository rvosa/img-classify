#include <stdio.h>
#include <stdlib.h>
#include <wand/MagickWand.h>

int main(int argc,char **argv) {
	PixelIterator *iterator;
	MagickWand *wand;
	PixelWand **row;
	unsigned long width, height;
	Quantum red, green, blue; // i.e. unsigned short
  	
	// set things up
	MagickWandGenesis();
	wand = NewMagickWand();
		
	// read an image, get dimensions
	MagickReadImage(wand, argv[1]);
	width = MagickGetImageWidth(wand);
	height = MagickGetImageHeight(wand);

	// iterate over rows
	iterator = NewPixelIterator(wand);
	for( int y = 0; y < height; y++ ) {
		row = PixelGetNextIteratorRow(iterator,&width);
		
		// iterate over columns
		for ( int x = 0; x < width; x++ ) {
			
			// get RGB values
			red   = PixelGetRedQuantum(row[x]);
			green = PixelGetGreenQuantum(row[x]);
			blue  = PixelGetBlueQuantum(row[x]);
			
			// print the output
			printf("pixel %d,%d is rgb=(%d,%d,%d)\n", x, y, red, green, blue);
		}
	}
	
	// clean up
	iterator = DestroyPixelIterator(iterator);
	wand = DestroyMagickWand(wand);
	MagickCoreTerminus();
	return(0);
}