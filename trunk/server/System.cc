// Copyright 2008 Isis Innovation Limited
#include "System.h"
#include "OpenGL.h"
#include <gvars3/instances.h>
#include <stdlib.h>
#include "ATANCamera.h"
#include "MapMaker.h"
#include "Tracker.h"
#include "ARDriver.h"
#include "MapViewer.h"

#include "Net.h"

using namespace CVD;
using namespace std;
using namespace GVars3;

extern float dRX, dRY, dRZ;
extern float dPX, dPY, dPZ;

System::System()
: mGLWindow(mVideoSource.Size(), "PTAM")
{
	GUI.RegisterCommand("exit", GUICommandCallBack, this);
	GUI.RegisterCommand("quit", GUICommandCallBack, this);
	GUI.RegisterCommand("KeyPress", GUICommandCallBack, this);

	mimFrameBW.resize(mVideoSource.Size());

	// First, check if the camera is calibrated.
	// If not, we need to run the calibration widget.
	Vector<NUMTRACKERCAMPARAMETERS> vTest;

	vTest = GV3::get<Vector<NUMTRACKERCAMPARAMETERS> >("Camera.Parameters", ATANCamera::mvDefaultParams, HIDDEN);
	mpCamera = new ATANCamera("Camera");
	if(vTest == ATANCamera::mvDefaultParams)
	{
		cout << endl;
		cout << "! Camera.Parameters is not set, need to run the CameraCalibrator tool" << endl;
		cout << "  and/or put the Camera.Parameters= line into the appropriate .cfg file." << endl;
		exit(1);
	}

	mpMap = new Map;
	mpMapMaker = new MapMaker(*mpMap, *mpCamera);
	mpTracker = new Tracker(mVideoSource.Size(), *mpCamera, *mpMap, *mpMapMaker);
	mpARDriver = new ARDriver(*mpCamera, mVideoSource.Size(), mGLWindow);
	mpMapViewer = new MapViewer(*mpMap, mGLWindow);

	GUI.ParseLine("GLWindow.AddMenu Menu Menu");
	GUI.ParseLine("Menu.ShowMenu Root");
	GUI.ParseLine("Menu.AddMenuButton Root Reset Reset Root");
	//GUI.ParseLine("Menu.AddMenuButton Root Spacebar PokeTracker Root");
	GUI.ParseLine("DrawAR=0");
	GUI.ParseLine("DrawMap=0");
	GUI.ParseLine("Menu.AddMenuToggle Root \"Map\" DrawMap Root");
	GUI.ParseLine("Menu.AddMenuToggle Root \"AR\" DrawAR Root");

	mbDone = false;
}

static void sendFile(const char *fileName)
{
	FILE *fp;
	char *buffer;
	int length;

	fp = fopen(fileName, "rb");
	if (!fp) {
		char msg[100];
		sprintf(msg, "Could not open %s\n", fileName);
		printf(msg);
		exit(-1);
	}
	fseek(fp, 0, SEEK_END);
	length = ftell(fp);
	rewind(fp);
	buffer = (char *) malloc(length);
	fread(buffer, length, 1, fp);
	fclose(fp);
	Net::get_instance()->send_bytes(buffer, length);
	free(buffer);
}

void System::Run()
{
	while(!mbDone)
	{
		// We use two versions of each video frame:
		// One black and white (for processing by the tracker etc)
		// and one RGB, for drawing.

		// Grab new video frame...
		mVideoSource.GetAndFillFrameBW(mimFrameBW);  
		static bool bFirstFrame = true;
		if(bFirstFrame)
		{
			mpARDriver->Init();
			bFirstFrame = false;
		}

		mGLWindow.SetupViewport();
		mGLWindow.SetupVideoOrtho();
		mGLWindow.SetupVideoRasterPosAndZoom();

		if (!mpMap->IsGood())
			mpARDriver->Reset();

		static gvar3<int> gvnDrawMap("DrawMap", 0, HIDDEN|SILENT);
		static gvar3<int> gvnDrawAR("DrawAR", 0, HIDDEN|SILENT);

		bool bDrawMap = mpMap->IsGood() && *gvnDrawMap;
		bool bDrawAR = mpMap->IsGood() && *gvnDrawAR;

		mpTracker->TrackFrame(mimFrameBW, !bDrawAR && !bDrawMap);

		TooN::SE3 pose = mpTracker->GetCurrentPose();
		if(bDrawMap)
			mpMapViewer->DrawMap(pose);
		else if(bDrawAR)
			mpARDriver->Render(mimFrameBW, pose);

		// For some reason (maybe because of PTAM) Leopard cannot display 320x240 frame with feature points
		// This hack is to force the display
		if (mimFrameBW.size().area() == 320*240) {
			mpTracker->TrackFrame(mimFrameBW, true);
		}

		// Send viewing fields only once
		static bool modelAndViewingFieldsSent = false;
		if (!modelAndViewingFieldsSent) {
			sendFile("data/triangles.tr");
			sendFile("data/viewing_fields.vf");
			modelAndViewingFieldsSent = true;
		}

		// Send pose to remote camera, see ARDriver::Render
		char valid;
		if (mpMap->IsGood() && !mpTracker->isFrameLost()) {
			float numbers[28 + 3 + 3];
			int i, j;

			// Frustom
			Matrix<4> opengl_frustum = mpCamera->MakeUFBLinearFrustumMatrix(0.005, 100).T();
			for (i = 0; i < 4; i++) {
				Vector<4> row = opengl_frustum[i];
				for (j = 0; j < 4; j++) {
					numbers[i*4 + j] = row[j];
				}
			}

			// Translation
			Vector<3> translation = pose.get_translation();
			for (j = 0; j < 3; j++) {
				numbers[16 + j] = translation[j];
			}

			// Rotation
			Matrix<3> opengl_rotation = pose.get_rotation().get_matrix().T();
			for (i = 0; i < 3; i++) {
				Vector<3> row = opengl_rotation[i];
				for (j = 0; j < 3; j++) {
					numbers[16 + 3 + i*3 + j] = row[j];
				}
			}

			// Adjust
			numbers[28] = dRX;
			numbers[29] = dRY;
			numbers[30] = dRZ;
			numbers[31] = dPX;
			numbers[32] = dPY;
			numbers[33] = dPZ;

			valid = 1;
			Net::get_instance()->send_bytes(&valid, 1);
			Net::get_instance()->send_bytes((char *) numbers, (28 + 3 + 3)*sizeof(float));
		} else {
			// Notify that the pose is not valid any more
			valid = 0;
			Net::get_instance()->send_bytes(&valid, 1);
		}

		// mGLWindow.GetMousePoseUpdate();
		string sCaption;
		if(bDrawMap)
			sCaption = mpMapViewer->GetMessageForUser();
		else
			sCaption = mpTracker->GetMessageForUser();
		mGLWindow.DrawCaption(sCaption);
		mGLWindow.DrawMenus();
		mGLWindow.swap_buffers();
		mGLWindow.HandlePendingEvents();
	}
}

void System::GUICommandCallBack(void *ptr, string sCommand, string sParams)
{
	if (sCommand == "quit" || sCommand == "exit")
		static_cast<System*>(ptr)->mbDone = true;

	// Let the user manually adjust the ratation
	if (sCommand == "KeyPress") {
		if (sParams == "x") {
			dRX -= 1;
		} else if (sParams == "c") {
			dRX += 1;
		} else if (sParams == "y") {
			dRY -= 1;
		} else if (sParams == "u") {
			dRY += 1;
		} else if (sParams == "s") {
			dRZ -= 1;
		} else if (sParams == "d") {
			dRZ += 1;
		}

		if (sParams == "i") {
			dPX -= 1;
		} else if (sParams == "o") {
			dPX += 1;
		} else if (sParams == "j") {
			dPY -= 1;
		} else if (sParams == "k") {
			dPY += 1;
		} else if (sParams == "n") {
			dPZ -= 1;
		} else if (sParams == "m") {
			dPZ += 1;
		}

		cout << "dRX = " << dRX << ", dRY = " << dRY << ", dRZ = " << dRZ << "\n";
		cout << "dPX = " << dPX << ", dPY = " << dPY << ", dPZ = " << dPZ << "\n" << "\n";
		cout.flush();
	}
}
