#ifndef TYPES_H
#define TYPES_H

// XXX the array of doubles needs to be variable, i.e. using a pointer
#define MAXCOLS 100
// holds a set of values resulting from one of the phenotyping algorithms
typedef struct {
	int size;
	double data[MAXCOLS];
} PhenoType;

#endif