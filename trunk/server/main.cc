// Copyright 2008 Isis Innovation Limited
// This is the main extry point for PTAM
#include <stdlib.h>
#include <iostream>
#include <gvars3/instances.h>
#include "System.h"

using namespace std;
using namespace GVars3;

// Adjustment
float dRX, dRY, dRZ;
float dPX = -23, dPY = -13, dPZ = 95;

int main()
{
	cout << "  Welcome to PTAM " << endl;
	cout << "  --------------- " << endl;
	cout << "  Parallel tracking and mapping for Small AR workspaces" << endl;
	cout << "  Copyright (C) Isis Innovation Limited 2008 " << endl;  
	cout << endl;
	cout << "  Parsing settings.cfg ...." << endl;
	GUI.LoadFile("data/settings.cfg");

	GUI.StartParserThread(); // Start parsing of the console input
	atexit(GUI.StopParserThread); 

	try
	{
		System s;
		s.Run();
	}
	catch(CVD::Exceptions::All e)
	{
		cout << endl;
		cout << "!! Failed to run system; got exception. " << endl;
		cout << "   Exception was: " << endl;
		cout << e.what << endl;
	}
}
