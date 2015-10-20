#pragma once

#include "Gesture.h"

using namespace ci;

namespace SecondStudy {
	
	class PinchGesture : public Gesture {
		vec2 _position;
		vec2 _distanceDelta;
		float _zoomDelta;
        float _angleDelta;
		unsigned long _widgetId;
		
	public:
		PinchGesture();

		PinchGesture(const vec2& p, const vec2& dd, const float zd, const float ad, const unsigned long id);
		
		~PinchGesture();
		
		const vec2& position() const;
		const vec2& distanceDelta() const;
		const float zoomDelta() const;
        const float angleDelta() const;

		const bool isOnWidget();
		const unsigned long widgetId() const;
	};
}