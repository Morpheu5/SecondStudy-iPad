#pragma once

#include "cinder/app/AppCocoaTouch.h"
#include "cinder/gl/gl.h"

#define FPS 60

namespace SecondStudy {
	
	class Widget;
	class TouchTrace;
	
	class ProgressiveGestureRecognizer;
	class StaticGestureRecognizer;
	class Gesture;
	
	using namespace ci;
	using namespace ci::app;
	using namespace std;
	
	class TheApp : public AppCocoaTouch {
		/* This lot initializes itself */
		list<shared_ptr<SecondStudy::Widget>> _widgets;
		mutex _widgetsMutex;
		
		map<int, shared_ptr<TouchTrace>> _traces;
		mutex _tracesMutex;
		
		vector<list<shared_ptr<TouchTrace>>> _groups;
		mutex _groupsMutex;
		
		list<list<shared_ptr<TouchTrace>>> _removedGroups;
		mutex _removedGroupsMutex;
		
		vector<shared_ptr<ProgressiveGestureRecognizer>> _progressiveGRs;
		vector<shared_ptr<StaticGestureRecognizer>> _staticGRs;
		
		shared_ptr<list<shared_ptr<Gesture>>> _gestures;
		shared_ptr<mutex> _gesturesMutex;
		/* ^^^^^^^^^^^^^^^^^^^^^^^^^^^ */
		
		bool _go;
		
	public:
		void setup();
		void mouseDown( MouseEvent event );
		void update();
		void draw();
		
		virtual void touchesBegan( TouchEvent event);
		virtual void touchesMoved( TouchEvent event);
		virtual void touchesEnded( TouchEvent event);
		
		int findGroupForTrace(shared_ptr<TouchTrace> trace);
		
		int numberOfTraces() { return _traces.size(); }
	};
	
}