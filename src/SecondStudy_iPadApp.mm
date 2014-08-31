#include <iostream>
#include "SecondStudy_iPadApp.h"

#include "BoxWidget.h"
#include "TouchTrace.h"
#include "TouchPoint.h"

#include "TapGestureRecognizer.h"
#include "PinchGestureRecognizer.h"
#include "MusicStrokeGestureRecognizer.h"
#include "ConnectionGestureRecognizer.h"
#include "DisconnectionGestureRecognizer.h"
#include "LongTapGestureRecognizer.h"

#include "TapGesture.h"
#include "PinchGesture.h"
#include "MusicStrokeGesture.h"
#include "ConnectionGesture.h"
#include "DisconnectionGesture.h"
#include "LongTapGesture.h"

using namespace std;
using namespace ci;
using namespace ci::app;
using namespace SecondStudy;

void SecondStudy::TheApp::setup() {
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	auto renderer = std::static_pointer_cast<RendererGl>(getRenderer());
//	renderer->setAntiAliasing(0);
	
	setFrameRate(FPS);

	shared_ptr<BoxWidget> box = make_shared<BoxWidget>(getWindowCenter());
	_widgets.push_back(box);
	_go = false;
}

void SecondStudy::TheApp::mouseDown( MouseEvent event ) {
}

void SecondStudy::TheApp::update() {
}

void SecondStudy::TheApp::draw() {
	// clear out the window with black
	gl::clear( Color( 0, 0, 0 ) );
	
	gl::pushModelView();
	_widgetsMutex.lock();
	for(auto w : _widgets) {
		w->draw();
	}
	_widgetsMutex.unlock();
	gl::popModelView();
	
	// Let's draw the traces as they are being created
	_tracesMutex.lock();
	_groupsMutex.lock();
	for(int i = 0; i < _groups.size(); i++) {
		for(auto trace : _groups[i]) {
			if(trace->isVisible) {
				gl::color(1.0f, 1.0f, 1.0f, 0.25f);
			} else {
				float c = (trace->lifespan() / 10.0f) * 0.25f;
				gl::color(1.0f, 1.0f, 1.0f, c);
			}
			if(trace->touchPoints.size() > 1) {
				for(auto cursorIt = trace->touchPoints.begin(); cursorIt != prev(trace->touchPoints.end()); ++cursorIt) {
					Vec2f a = cursorIt->getPos();
					Vec2f b = next(cursorIt)->getPos();
					gl::lineWidth(2.0f);
					gl::drawLine(a, b);
				}
			}
			if(trace->isVisible) {
				gl::drawSolidCircle(trace->currentPosition(), 8.0f);
				gl::drawSolidCircle(trace->currentPosition(), 50.0f);
			} else {
				gl::drawSolidCircle(trace->currentPosition(), 4.0f);
			}
		}
	}
	_groupsMutex.unlock();
	_tracesMutex.unlock();
}

void SecondStudy::TheApp::touchesBegan(cinder::app::TouchEvent event) {
	for(auto touch : event.getTouches()) {
//		UITouch *nTouch = (UITouch *)touch.getNative();
		bool continued = false;
		int joined = -1;
		_tracesMutex.lock();
		for(auto pair : _traces) {
			auto trace = pair.second;
			if(!trace->isVisible && !trace->isDead() && trace->currentPosition().distance(touch.getPos()) <= 50.0f) {
				_traces[touch.getId()] = _traces[trace->getId()];
				joined = trace->getId(); // the old session id (therefore the old trace that has been resurrected)
				_traces[touch.getId()]->resurrect();
				_traces[touch.getId()]->cursorMove(touch);
				continued = true;
				break;
			}
		}
		if(continued) {
			if(joined > 0) {
				_traces.erase(joined);
			}
		} else {
			// This is a brand new trace, we have to do stuff!
			_traces[touch.getId()] = make_shared<TouchTrace>();
			_traces[touch.getId()]->addCursorDown(touch);
			
			// Check if it's on a widget
			_widgetsMutex.lock();
			// This is done in reverse order because I say so.
			for(auto it = _widgets.rbegin(); it != _widgets.rend(); ++it) {
				auto w = *it;
				if(w->hit(touch.getPos())) {
					_traces[touch.getId()]->widgetId = w->id();
					break;
				}
			}
			_widgetsMutex.unlock();
			
			_groupsMutex.lock();
			int g = findGroupForTrace(_traces[touch.getId()]);
			if(g == -1) {
				list<shared_ptr<TouchTrace>> l;
				l.push_back(_traces[touch.getId()]);
				_groups.push_back(l);
			} else {
				_groups[g].push_back(_traces[touch.getId()]);
			}
			_groupsMutex.unlock();
		}
		_tracesMutex.unlock();
		
		for(auto &g : _groups) {
			for(auto pgr : _progressiveGRs) {
				pgr->processGroup(g);
			}
		}
		
//		stringstream ss;
//		ss	<< "TheApp::cursorAdded "
//		<< "(x:" << cursor.getPos().x
//		<< " y:" << cursor.getPos().y
//		<< " session_id:" << cursor.getSessionId()
//		<< " widget_id:" << _traces[cursor.getSessionId()]->widgetId
//		<< " new_trace:" << (continued ? "n" : "y")
//		<< " joined_trace:" << joined
//		<< ")";
//		Logger::instance().log(ss.str());
	}
}

void SecondStudy::TheApp::touchesMoved(cinder::app::TouchEvent event) {
	for(auto touch : event.getTouches()) {
//		UITouch *nTouch = (UITouch *)touch.getNative();
		_go = true;
		_tracesMutex.lock();
		_traces[touch.getId()]->cursorMove(touch);
		_tracesMutex.unlock();
		
		for(auto &g : _groups) {
			for(auto pgr : _progressiveGRs) {
				pgr->processGroup(g);
			}
		}
		
//		stringstream ss;
//		ss	<< "TheApp::cursorUpdated "
//		<< "(x:" << cursor.getPos().x
//		<< " y:" << cursor.getPos().y
//		<< " session_id:" << cursor.getSessionId()
//		<< " widget_id:" << _traces[cursor.getSessionId()]->widgetId
//		<< ")";
//		Logger::instance().log(ss.str());
	}
}

void SecondStudy::TheApp::touchesEnded(cinder::app::TouchEvent event) {
	for(auto touch : event.getTouches()) {
//		UITouch *nTouch = (UITouch *)touch.getNative();
		_go = true;
		_tracesMutex.lock();
		_traces[touch.getId()]->addCursorUp(touch);
		_traces[touch.getId()]->isVisible = false;
		_tracesMutex.unlock();
		
		for(auto &g : _groups) {
			for(auto pgr : _progressiveGRs) {
				pgr->processGroup(g);
			}
		}
		
//		stringstream ss;
//		ss	<< "TheApp::cursorRemoved "
//		<< "(x:" << cursor.getPos().x
//		<< " y:" << cursor.getPos().y
//		<< " session_id:" << cursor.getSessionId()
//		<< " widget_id:" << _traces[cursor.getSessionId()]->widgetId
//		<< ")";
//		Logger::instance().log(ss.str());
	}
}

int SecondStudy::TheApp::findGroupForTrace(shared_ptr<TouchTrace> trace) {
	// First: group traces on the same widget
	for(int i = 0; i < _groups.size(); i++) {
		for(auto otherTrace : _groups[i]) {
			if(trace->widgetId == otherTrace->widgetId && otherTrace->widgetId != 0) {
				return i;
			}
		}
	}
	
	// Second: if that failed, group with nearby traces
	for(int i = 0; i < _groups.size(); i++) {
		auto traces = _groups[i];
		for(auto otherTrace : traces) {
			if(otherTrace->currentPosition().distance(trace->currentPosition()) < 50.0f) {
				return i;
			}
		}
	}
	
	// Last: if all previous grouping attempts failed, just give up
	return -1;
}

CINDER_APP_COCOA_TOUCH( SecondStudy::TheApp, RendererGl )
