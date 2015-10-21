#pragma once

#include <list>

using namespace ci;
using namespace std;

namespace SecondStudy {
	
	class TouchPoint;

	class TouchTrace {
		int _lifespan;
		
	public:
		enum class State {
			TOUCH_DOWN,
			TOUCH_MOVING,
			TOUCH_STILL,
			TOUCH_UP
		} state;
		
		list<TouchPoint> touchPoints;
		bool isVisible;
		unsigned long widgetId;

		TouchTrace();
		~TouchTrace();

		unsigned long getId();
		unsigned long getSessionId();
		vec2 currentPosition();
		vec2 previousPosition();

		int lifespan();
		bool isDead();
		void update();
		void resurrect();
		bool isOnWidget();

		// TODO State info should be added to the cursors
		void addCursorDown(TouchPoint p);
		void cursorMove(TouchPoint p);
		void addCursorUp(TouchPoint p);
	};

}