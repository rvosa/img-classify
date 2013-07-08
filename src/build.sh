cc -o helloworld `pkg-config --cflags --libs MagickWand` helloworld.c
./helloworld ../data/img/out-of-sample/may07_mossii.png 50

