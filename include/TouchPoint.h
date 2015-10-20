#pragma once

#include "cinder/app/TouchEvent.h"

using namespace ci;
using namespace ci::app;

namespace SecondStudy {

	class TouchPoint {
		unsigned long _id;
		vec2 _position;
		
	public:
		double timestamp;
	
		TouchPoint();
		TouchPoint(const TouchEvent::Touch c);
		
		const unsigned long getId() const { return _id; }
		const vec2& getPos() const { return _position; }
	};
}