# DO NOT DELETE THIS LINE -- make depend depends on it.


# Edit the lines below to point to any needed include and link paths
# Or to change the compiler's optimization flags
CC = g++ -g -O3
COMPILEFLAGS = -I /Users/ngocdt/tmp/PTAM -D_OSX -D_REENTRANT -D CVD_HAVE_TOON
LINKFLAGS = -framework OpenGL -framework VecLib -lGVars3 -lcvd -lz

OBJECTS=	main.o\
		VideoSource_TCP.o\
		Client.o\
		GLWindow2.o\
		GLWindowMenu.o\
		System.o \
		ATANCamera.o\
		KeyFrame.o\
		MapPoint.o\
		Map.o\
		SmallBlurryImage.o\
		ShiTomasi.o \
		MapMaker.o \
		Bundle.o \
		PatchFinder.o\
		HomographyInit.o\
		Relocaliser.o\
		MiniPatch.o\
		MapViewer.o\
		ARDriver.o\
		EyeGame.o\
		Tracker.o 

CALIB_OBJECTS=	GLWindow2.o\
		GLWindowMenu.o\
		VideoSource_TCP.o\
		Client.o\
		CalibImage.o \
		CalibCornerPatch.o\
		ATANCamera.o \
		CameraCalibrator.o 

All: PTAM CameraCalibrator

PTAM:$(OBJECTS)
	$(CC) -o PTAM $(OBJECTS) $(LINKFLAGS)
	/Developer/Tools/Rez OSX_resource_file.r -o PTAM
CameraCalibrator:$(CALIB_OBJECTS)
	$(CC) -o CameraCalibrator $(CALIB_OBJECTS) $(LINKFLAGS)
	/Developer/Tools/Rez OSX_resource_file.r -o CameraCalibrator

%.o: %.cc
	$(CC) $< -o $@ -c $(COMPILEFLAGS)

clean:
	rm *.o


depend:
	rm dependecies; touch dependencies
	makedepend -fdependencies $(INCLUDEFLAGS) $(MOREINCS) *.cc *.h

-include dependencies