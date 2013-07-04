#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <magick/MagickCore.h>

int main(int argc,char **argv) {
	ExceptionInfo *exception;
	Image *image;
	ImageInfo *image_info;
  	
	// initialize image info structure
	MagickCoreGenesis(*argv,MagickTrue);
	exception=AcquireExceptionInfo();
	image_info=CloneImageInfo((ImageInfo *) NULL);
	
	// read an image
	(void) strcpy(image_info->filename,argv[1]);
	image=ReadImage(image_info,exception);
	
	// handle exceptions
	if (exception->severity != UndefinedException) {
		CatchException(exception);
	}
	if (image == (Image *) NULL) {
		exit(1);
	}

	// write some output
	(void) fprintf(stdout,"Hello world! Read an image: %s\n",argv[1]);

	// clean up
	image=DestroyImageList(image);
	image_info=DestroyImageInfo(image_info);
	exception=DestroyExceptionInfo(exception);
	MagickCoreTerminus();
	return(0);
}
