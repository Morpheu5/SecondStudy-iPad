#include "LongTapGestureRecognizer.h"

#include "TouchPoint.h"
#include "TouchTrace.h"
#include "LongTapGesture.h"

#include "SecondStudy_iPadApp.h"

using namespace ci;
using namespace ci::app;
using namespace std;

SecondStudy::LongTapGestureRecognizer::LongTapGestureRecognizer(shared_ptr<list<shared_ptr<Gesture>>> gestures, shared_ptr<mutex> mtx) {
	_gestures = gestures;
	_gesturesMutex = mtx;
}

void SecondStudy::LongTapGestureRecognizer::processGroup(list<shared_ptr<TouchTrace>> group) {
	if(group.size() == 1) {
		auto trace = group.front();
		TheApp *theApp = (TheApp *)App::get();
		TouchPoint a = trace->touchPoints.front();
		TouchPoint b = trace->touchPoints.back();
		
		Vec2f ap = a.getPos();
		Vec2f bp = b.getPos();
		
		if(ap.distance(bp) < 5.0f && b.timestamp - a.timestamp >= 0.5f) {
			shared_ptr<LongTapGesture> tap = make_shared<LongTapGesture>(bp, trace->widgetId);
			_gesturesMutex->lock();
			_gestures->push_back(tap);
			_gesturesMutex->unlock();
		}
	}
}