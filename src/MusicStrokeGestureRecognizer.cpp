#include "MusicStrokeGestureRecognizer.h"

#include "TouchPoint.h"
#include "TouchTrace.h"
#include "MusicStrokeGesture.h"

#include "Widget.h"
#include "MeasureWidget.h"

#include "SecondStudy_iPadApp.h"

using namespace ci;
using namespace ci::app;
using namespace std;

SecondStudy::MusicStrokeGestureRecognizer::MusicStrokeGestureRecognizer(shared_ptr<list<shared_ptr<Gesture>>> gestures, shared_ptr<mutex> mtx) {
	_gestures = gestures;
	_gesturesMutex = mtx;
}

void SecondStudy::MusicStrokeGestureRecognizer::processGroup(list<shared_ptr<TouchTrace>> group) {
	if(group.size() == 1) {
		auto trace = group.front();
		auto theApp = static_cast<TheApp*>(App::get());
		TouchPoint a = trace->touchPoints.front();
		TouchPoint b = trace->touchPoints.back();
		
		vec2 bp = b.getPos();
		
		unsigned long startWid = trace->widgetId;
		unsigned long endWid = -1;
		theApp->widgetsMutex().lock();
		for(auto w : theApp->widgets()) {
			if(w->hit(bp)) {
				if(dynamic_pointer_cast<MeasureWidget>(w)) {
					endWid = w->id();
					break;
				}
			}
		}
		theApp->widgetsMutex().unlock();
		
		if(startWid == endWid) {
			shared_ptr<MusicStrokeGesture> g = make_shared<MusicStrokeGesture>(TouchTrace(*trace), startWid);
			_gesturesMutex->lock();
			_gestures->push_back(g);
			_gesturesMutex->unlock();
		}
	}
}