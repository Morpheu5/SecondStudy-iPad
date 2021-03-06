#pragma once

#include "cinder/app/App.h"
#include "cinder/gl/gl.h"

//#import <objc/objc-runtime.h>

#define FPS 30

#ifdef __OBJC__
@class EPSSampler;
#else
typedef struct objc_object EPSSampler;
#endif

namespace SecondStudy {
	
	class Widget;
	class MeasureWidget;
	
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
		
		list<list<shared_ptr<MeasureWidget>>> _sequences;
		mutex _sequencesMutex;
		
		list<unsigned long> _measuresToRemove;
		
		void removeMeasures();
		/* ^^^^^^^^^^^^^^^^^^^^^^^^^^^ */
		
		thread _gestureEngine;
		bool _gestureEngineShouldStop;
		
		thread _gestureProcessor;
		bool _gestureProcessorShouldStop;
		
		bool _go;

		gl::ContextRef _gpContext;
		
		gl::BatchRef _lineBatch;

	public:
		void setup();
		void shutdown();
		void update();
		void draw();
		
		void gestureEngine();
		void gestureProcessor();
		
		void measureHasFinishedPlaying(unsigned long);
		void measureWantsToDisappear(unsigned long);
		
		virtual void touchesBegan( TouchEvent event);
		virtual void touchesMoved( TouchEvent event);
		virtual void touchesEnded( TouchEvent event);
		
		int findGroupForTrace(shared_ptr<TouchTrace> trace);
		
		int numberOfTraces() { return (int)_traces.size(); }
		
		list<shared_ptr<Widget>>& widgets() { return _widgets; }
		mutex& widgetsMutex() { return _widgetsMutex; }
		
		list<list<shared_ptr<MeasureWidget>>>& sequences() { return _sequences; }
		mutex& sequencesMutex() { return _sequencesMutex; }
		
		EPSSampler *sampler;
	};
	
}