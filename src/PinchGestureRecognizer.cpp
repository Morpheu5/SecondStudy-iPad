#include "PinchGestureRecognizer.h"

#include "TouchPoint.h"
#include "TouchTrace.h"
#include "PinchGesture.h"

#include "SecondStudy_iPadApp.h"

using namespace ci;
using namespace ci::app;
using namespace std;

SecondStudy::PinchGestureRecognizer::PinchGestureRecognizer(shared_ptr<list<shared_ptr<Gesture>>> gestures, shared_ptr<mutex> mtx) {
	_gestures = gestures;
	_gesturesMutex = mtx;
}

void SecondStudy::PinchGestureRecognizer::processGroup(list<shared_ptr<TouchTrace>> group) {
	if(group.size() >= 2) {
        // Always take the first two, discard subsequents as they may be artifacts.
        // Anyway, they are worthless. The gesture requires two fingers.
		shared_ptr<TouchTrace> tA = group.front();
		shared_ptr<TouchTrace> tB = *(next(group.begin()));

		TheApp *theApp = (TheApp *)App::get();

        vec2 startA = tA->touchPoints.front().getPos();
		vec2 prevA = tA->previousPosition();
		vec2 currA = tA->currentPosition();
        vec2 startB = tB->touchPoints.front().getPos();
		vec2 prevB = tB->previousPosition();
		vec2 currB = tB->currentPosition();

		vec2 prevPos = (prevA + prevB) / 2.0f;
		vec2 currPos = (currA + currB) / 2.0f;

        // Divided by the number of traces. This is a silly workaround
		vec2 distanceDelta = (currPos - prevPos) / (float)theApp->numberOfTraces();

		float startD = distance(startA, startB);
        float prevD = distance(prevA, prevB);
		float currD = distance(currA, currB);
        
        float prevZD = (prevD / startD) / 2.0f;
        float currZD = (currD / startD) / 2.0f;

        float ZD = (currZD - prevZD);
        
		float zoomDelta = (ZD) / (float)theApp->numberOfTraces();
        
        float prevDX = prevB.x - prevA.x;
        float prevDY = prevB.y - prevA.y;
        float currDX = currB.x - currA.x;
        float currDY = currB.y - currA.y;
        
        float prevAngle = atan2(prevDY, prevDX);
        float currAngle = atan2(currDY, currDX);
        
        float angleDelta = (currAngle - prevAngle) / (float)theApp->numberOfTraces();

		shared_ptr<PinchGesture> pinch = make_shared<PinchGesture>(currPos, distanceDelta, zoomDelta, angleDelta, tA->widgetId);
		_gesturesMutex->lock();
		_gestures->push_back(pinch);
		_gesturesMutex->unlock();
	}
}