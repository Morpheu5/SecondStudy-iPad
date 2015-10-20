#include "TapGestureRecognizer.h"

#include "TouchPoint.h"
#include "TouchTrace.h"
#include "TapGesture.h"

#include "SecondStudy_iPadApp.h"

using namespace ci;
using namespace ci::app;
using namespace std;

SecondStudy::TapGestureRecognizer::TapGestureRecognizer(shared_ptr<list<shared_ptr<Gesture>>> gestures, shared_ptr<mutex> mtx) {
	_gestures = gestures;
	_gesturesMutex = mtx;
}

void SecondStudy::TapGestureRecognizer::processGroup(list<shared_ptr<TouchTrace>> group) {
	if(group.size() == 1) {
		auto trace = group.front();
		TouchPoint a = trace->touchPoints.front();
		TouchPoint b = trace->touchPoints.back();

		vec2 ap = a.getPos();
		vec2 bp = b.getPos();

		if(distance(ap, bp) < 5.0f && b.timestamp - a.timestamp <= 0.25f) {
			shared_ptr<TapGesture> tap = make_shared<TapGesture>(bp, trace->widgetId);
			_gesturesMutex->lock();
			_gestures->push_back(tap);
			_gesturesMutex->unlock();
		}
	}
}