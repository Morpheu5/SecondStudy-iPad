#pragma once

#include "cinder/app/TouchEvent.h"

using namespace ci;
using namespace ci::app;

namespace SecondStudy {

	class TouchPoint : public TouchEvent::Touch {
	public:
		double timestamp;
	
		TouchPoint();
		TouchPoint(const TouchEvent::Touch& c);
	};
}