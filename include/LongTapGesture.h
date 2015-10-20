#pragma once

#include "Gesture.h"

using namespace ci;

namespace SecondStudy {
	
	class LongTapGesture : public Gesture {
		vec2 _position;
		unsigned long _widgetId;
		
	public:
		LongTapGesture();
		LongTapGesture(const vec2& p, const unsigned long id);
		
		~LongTapGesture();
		
		const vec2& position() const;
		const bool isOnWidget();
		const unsigned long widgetId() const;
	};
}