#include "TouchTrace.h"

#include "TouchPoint.h"

#include "SecondStudy_iPadApp.h"

using namespace ci;
using namespace ci::app;

SecondStudy::TouchTrace::TouchTrace() {
	state = State::TOUCH_DOWN;
	isVisible = true;
	widgetId = 0;
	_lifespan = FPS/6;
}

SecondStudy::TouchTrace::~TouchTrace() {
	touchPoints.clear();
}

int SecondStudy::TouchTrace::getId() {
	return touchPoints.back().getId();
}

int SecondStudy::TouchTrace::getSessionId() {
	return touchPoints.back().getId();
}

Vec2f SecondStudy::TouchTrace::currentPosition() {
	return touchPoints.back().getPos();
}

Vec2f SecondStudy::TouchTrace::previousPosition() {
	if(touchPoints.size() > 1) {
		return prev(touchPoints.end(), 2)->getPos();
	} else {
		return currentPosition();
	}
}

int SecondStudy::TouchTrace::lifespan() {
	return _lifespan;
}

bool SecondStudy::TouchTrace::isDead() {
	return _lifespan == 0;
}

void SecondStudy::TouchTrace::update() {
	if(!isVisible) {
		_lifespan--;
	}
}

void SecondStudy::TouchTrace::resurrect() {
	_lifespan = FPS/6;
	isVisible = true;
}

bool SecondStudy::TouchTrace::isOnWidget() {
	return widgetId != 0;
}

// TODO State info should be added to the cursors
void SecondStudy::TouchTrace::addCursorDown(SecondStudy::TouchPoint p) {
	touchPoints.push_back(p);
	state = State::TOUCH_DOWN;
}

void SecondStudy::TouchTrace::cursorMove(SecondStudy::TouchPoint p) {
	touchPoints.push_back(p);
	UITouch *t = (UITouch *)p.getNative();
	if(t.phase == UITouchPhaseMoved) {
		state = State::TOUCH_MOVING;
	} else if(t.phase == UITouchPhaseStationary) {
		state = State::TOUCH_STILL;
	}
}

void SecondStudy::TouchTrace::addCursorUp(SecondStudy::TouchPoint p) {
	touchPoints.push_back(p);
	state = State::TOUCH_UP;
}