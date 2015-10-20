#include "TouchPoint.h"

using namespace ci;

SecondStudy::TouchPoint::TouchPoint() {
	timestamp = app::getElapsedSeconds();
}

SecondStudy::TouchPoint::TouchPoint(const TouchEvent::Touch c) {
	_id = c.getId();
	_position = c.getPos();
	timestamp = app::getElapsedSeconds();
}