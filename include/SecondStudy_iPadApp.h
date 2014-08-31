#pragma once

#include "cinder/app/AppCocoaTouch.h"
#include "cinder/gl/gl.h"

namespace SecondStudy {
	
	class Widget;
	class BoxWidget;
	
	using namespace ci;
	using namespace ci::app;
	using namespace std;
	
	class SecondStudy_iPadApp : public AppCocoaTouch {

		list<shared_ptr<SecondStudy::Widget>> _widgets;
		mutex _widgetsMutex;
		
	public:
		void setup();
		void mouseDown( MouseEvent event );
		void update();
		void draw();
		
		virtual void touchesBegan( TouchEvent event);
		virtual void touchesMoved( TouchEvent event);
		virtual void touchesEnded( TouchEvent event);
	};
	
}