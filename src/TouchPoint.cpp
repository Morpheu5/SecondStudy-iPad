#include "TouchPoint.h"

using namespace ci;

SecondStudy::TouchPoint::TouchPoint() {
	timestamp = app::getElapsedSeconds();
}

SecondStudy::TouchPoint::TouchPoint(const TouchEvent::Touch& c) : TouchEvent::Touch(c) {
	timestamp = app::getElapsedSeconds();
}