#pragma once

#include "Gesture.h"

using namespace ci;

namespace SecondStudy {
	
	class TapGesture : public Gesture {
		vec2 _position;
		unsigned long _widgetId;
		
	public:
		TapGesture();
		TapGesture(const vec2& p, const unsigned long id);
		
		~TapGesture();
		
		const vec2& position() const;
		const bool isOnWidget();
		const unsigned long widgetId() const;
	};
}