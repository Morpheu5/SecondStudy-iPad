#include "DisconnectionGestureRecognizer.h"

#include "TouchPoint.h"
#include "TouchTrace.h"
#include "DisconnectionGesture.h"

#include "Widget.h"
#include "MeasureWidget.h"

#include "SecondStudy_iPadApp.h"

using namespace ci;
using namespace ci::app;
using namespace std;

SecondStudy::DisconnectionGestureRecognizer::DisconnectionGestureRecognizer(shared_ptr<list<shared_ptr<Gesture>>> gestures, shared_ptr<mutex> mtx) {
	_gestures = gestures;
	_gesturesMutex = mtx;
}

void SecondStudy::DisconnectionGestureRecognizer::processGroup(list<shared_ptr<TouchTrace>> group) {
	if(group.size() == 1) {
		auto trace = group.front();
		auto theApp = static_cast<TheApp*>(App::get());
		TouchPoint ap = trace->touchPoints.front();
		TouchPoint bp = trace->touchPoints.back();
		
		vec2 a = ap.getPos();
		vec2 b = bp.getPos();
		
		theApp->sequencesMutex().lock();
		
		for(auto sit = theApp->sequences().begin(); sit != theApp->sequences().end(); ++sit) {
			if(sit->size() > 1) {
				for(auto wit = sit->begin(); wit != prev(sit->end()); ++wit) {
					vec3 fwpos = vec3((*wit)->position(), 0);
					float fwang = (*wit)->angle();
					vec3 twpos = vec3((*next(wit))->position(), 0);
					float twang = (*next(wit))->angle();
					
					vec4 olpos = vec4((*wit)->outletIcon().getCenter(), 0, 1);
					vec4 ilpos = vec4((*next(wit))->inletIcon().getCenter(), 0, 1);
					
					mat4 fwt = translate(fwpos) * rotate(fwang, vec3(0,0,1));
					vec2 c = vec2(fwt * olpos);
					
					mat4 twt = translate(twpos) * rotate(twang, vec3(0,0,1));
					vec2 d = vec2(twt * ilpos);
					
					float A1 = (a.y - b.y) / (a.x - b.x);
					float A2 = (c.y - d.y) / (c.x - d.x);
					float b1 = a.y - A1 * a.x;
					float b2 = c.y - A2 * c.x;
					
					if(abs(A1 - A2) > FLT_EPSILON) {
						float px = (b2 - b1) / (A1 - A2);
						vec2 p(px, A1 * px + b1);
						
						// Now, to see if p is contained within both bounding boxes...
						Rectf ab(min(a.x, b.x), min(a.y, b.y), max(a.x, b.x), max(a.y, b.y));
						Rectf cd(min(c.x, d.x), min(c.y, d.y), max(c.x, d.x), max(c.y, d.y));
						if(ab.contains(p) && cd.contains(p)) {
							shared_ptr<DisconnectionGesture> g = make_shared<DisconnectionGesture>((*wit)->id(), (*next(wit))->id());
							_gesturesMutex->lock();
							_gestures->push_back(g);
							_gesturesMutex->unlock();
						}
					}
				}
			}
		}
		
		theApp->sequencesMutex().unlock();
	}
}