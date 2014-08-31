#include <iostream>
#include "SecondStudy_iPadApp.h"

#include "BoxWidget.h"

using namespace std;
using namespace ci;
using namespace ci::app;
using namespace SecondStudy;

void SecondStudy_iPadApp::setup() {
	shared_ptr<BoxWidget> box = make_shared<BoxWidget>(getWindowCenter());
	_widgets.push_back(box);
}

void SecondStudy_iPadApp::mouseDown( MouseEvent event ) {
}

void SecondStudy_iPadApp::update() {
}

void SecondStudy_iPadApp::draw() {
	// clear out the window with black
	gl::clear( Color( 1, 1, 0 ) );
	
	gl::pushModelView();
	_widgetsMutex.lock();
	for(auto w : _widgets) {
		w->draw();
	}
	_widgetsMutex.unlock();
	gl::popModelView();
}

void SecondStudy_iPadApp::touchesBegan(cinder::app::TouchEvent event) {
	
}

void SecondStudy_iPadApp::touchesMoved(cinder::app::TouchEvent event) {
	
}

void SecondStudy_iPadApp::touchesEnded(cinder::app::TouchEvent event) {
	
}

CINDER_APP_COCOA_TOUCH( SecondStudy_iPadApp, RendererGl )
