#include <iostream>
#include "cinder/app/RendererGl.h"
#include "SecondStudy_iPadApp.h"

#include "BoxWidget.h"
#include "MeasureWidget.h"

#include "TouchTrace.h"
#include "TouchPoint.h"

#include "TapGestureRecognizer.h"
#include "PinchGestureRecognizer.h"
#include "MusicStrokeGestureRecognizer.h"
#include "ConnectionGestureRecognizer.h"
#include "DisconnectionGestureRecognizer.h"
#include "LongTapGestureRecognizer.h"

#include "TapGesture.h"
#include "PinchGesture.h"
#include "MusicStrokeGesture.h"
#include "ConnectionGesture.h"
#include "DisconnectionGesture.h"
#include "LongTapGesture.h"

#import "EPSSampler.h"

using namespace std;
using namespace ci;
using namespace ci::app;
using namespace SecondStudy;

void SecondStudy::TheApp::setup() {
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	_gpContext = gl::Context::create(gl::Context::getCurrent());
	
	NSURL *presetUrl = [[NSBundle mainBundle] URLForResource:@"assets/Vibraphone" withExtension:@"aupreset"];
	sampler = [[EPSSampler alloc] initWithPresetURL:presetUrl];

	shared_ptr<MeasureWidget> measure = make_shared<MeasureWidget>(getWindowCenter(), 8, 8);
	_widgets.push_back(measure);

	list<shared_ptr<MeasureWidget>> sequence;
	sequence.push_back(measure);
	_sequences.push_back(sequence);

	_gesturesMutex = make_shared<mutex>();
	_gestures = make_shared<list<shared_ptr<Gesture>>>();
	
	_staticGRs.push_back(make_shared<TapGestureRecognizer>(_gestures, _gesturesMutex));
	_staticGRs.push_back(make_shared<MusicStrokeGestureRecognizer>(_gestures, _gesturesMutex));
	_staticGRs.push_back(make_shared<ConnectionGestureRecognizer>(_gestures, _gesturesMutex));
	_staticGRs.push_back(make_shared<DisconnectionGestureRecognizer>(_gestures, _gesturesMutex));
	_staticGRs.push_back(make_shared<LongTapGestureRecognizer>(_gestures, _gesturesMutex));
	
	_progressiveGRs.push_back(make_shared<PinchGestureRecognizer>(_gestures, _gesturesMutex));

	// At last, fire up the gesture engine...
	_gestureEngineShouldStop = false;
	_gestureEngine = thread(bind(&SecondStudy::TheApp::gestureEngine, this));
	// ... and the gesture processor.
	_gestureProcessorShouldStop = false;
	_gestureProcessor = thread(bind(&SecondStudy::TheApp::gestureProcessor, this));

	_go = false;
}

void SecondStudy::TheApp::shutdown() {
	_gestureEngineShouldStop = true;
	_gestureProcessorShouldStop = true;
	_gestureProcessor.join();
	_gestureEngine.join();
}

void SecondStudy::TheApp::update() {
	_sequencesMutex.lock();
	_sequences.remove_if( [](list<shared_ptr<MeasureWidget>> l) {
		return l.empty();
	});
	_sequencesMutex.unlock();
	
	_tracesMutex.lock();
	for(auto i = _traces.begin(); i != _traces.end(); ) {
		if(!i->second->isVisible && i->second->isDead()) {
			i = _traces.erase(i);
		} else {
			++i;
		}
	}
	_tracesMutex.unlock();
	
	_removedGroupsMutex.lock();
	_groupsMutex.lock();
	for(auto &g : _groups) {
		bool r = [g]() {
			for(auto t : g) { // if at least one trace is still alive, keep the group alive
				t->update();
				if(!t->isDead()) {
					return false;
				}
			}
			// if all traces are dead, mark the group for removal
			return true;
		}();
		if(r) {
			_removedGroups.push_back(g);
			g.clear();
		}
	}
	_groups.erase(remove_if(_groups.begin(), _groups.end(),
							[](list<shared_ptr<TouchTrace>> l) {
								return l.empty();
							}), _groups.end()); // This is not much intuitive, maybe. It has to do with re-sorting stuff in a range.
	_groupsMutex.unlock();
	_removedGroupsMutex.unlock();
}

void SecondStudy::TheApp::draw() {
	// clear out the window with black
	gl::clear(Colorf(0.0f, 0.0f, 0.0f));

	gl::pushModelView();
	gl::lineWidth(4.0f);
	gl::color(1.0f, 1.0f, 1.0f, 1.0f);
	_sequencesMutex.lock();
	for(auto& s : _sequences) {
		if(s.size() > 1) {
			for(auto it = s.begin(); it != prev(s.end()); ++it) {
				shared_ptr<MeasureWidget> a = *it;
				shared_ptr<MeasureWidget> b = *(next(it));
				
				mat4 at = translate(vec3(a->position(), 0)) * rotate(a->angle(), vec3(0,0,1));
				vec2 ap = vec2(at * vec4(a->outletIcon().getCenter(), 0, 1));
				mat4 bt = translate(vec3(b->position(), 0)) * rotate(b->angle(), vec3(0,0,1));
				vec2 bp = vec2(bt * vec4(b->inletIcon().getCenter(), 0, 1));
				
				gl::drawLine(ap, bp);
			}
		}
	}
	_sequencesMutex.unlock();
	gl::lineWidth(2.0f);

	_widgetsMutex.lock();
	for(auto w : _widgets) {
		w->draw();
	}
	_widgetsMutex.unlock();
	gl::popModelView();

	// Let's draw the traces as they are being created
	gl::lineWidth(2.0f);
	_tracesMutex.lock();
	for(auto trace : _traces) {
		if(trace.second->isVisible) {
			gl::color(1.0f, 1.0f, 1.0f, 0.25f);
			gl::drawSolidCircle(trace.second->currentPosition(), 8.0f);
		} else {
			gl::color(1.0f, 1.0f, 1.0f, trace.second->lifespan()/40.0f);
		}

		int n = min((size_t)10, trace.second->touchPoints.size());
		if(trace.second->touchPoints.size() > 1) {
			for(auto cursorIt = prev(trace.second->touchPoints.begin(), n);
				cursorIt != prev(trace.second->touchPoints.end());
				++cursorIt) {
				gl::drawLine(cursorIt->getPos(), next(cursorIt)->getPos());
			}
		}
	}
	_tracesMutex.unlock();
}

void SecondStudy::TheApp::gestureEngine() {
	while(!_gestureEngineShouldStop) {
		// PROGRESSIVEs can be dealt with using a signal. For now I'll keep the thing in the methods below
		this_thread::sleep_for(chrono::milliseconds((long long)floor(100.0f / FPS)));
		// STATIC
		list<shared_ptr<TouchTrace>> group;
		_removedGroupsMutex.lock();
		if(_removedGroups.size() > 0) {
			group = _removedGroups.front();
			_removedGroups.pop_front();
		}
		_removedGroupsMutex.unlock();
		
		if(group.size() > 0) {
			for(auto sgr : _staticGRs) {
				sgr->processGroup(group);
			}
		}
	}
}

void SecondStudy::TheApp::gestureProcessor() {
	while(!_gestureProcessorShouldStop) {
		this_thread::sleep_for(chrono::milliseconds((long long)floor(100.0f / FPS)));
		if(_gestures->size() > 0) {
			_gesturesMutex->lock();
			// This may very well be leaking stuff around. 'Tis no good.
			shared_ptr<Gesture> unknownGesture = _gestures->front();
			_gestures->pop_front();
			_gesturesMutex->unlock();
			
			if(dynamic_pointer_cast<TapGesture>(unknownGesture)) {
				shared_ptr<TapGesture> tap = dynamic_pointer_cast<TapGesture>(unknownGesture);
				if(tap->isOnWidget()) {
					_widgetsMutex.lock();
					auto wIt = find_if(_widgets.begin(), _widgets.end(),
									   [&, this](shared_ptr<Widget> w) {
										   return w->id() == tap->widgetId();
									   });
					if(wIt != _widgets.end()) {
						auto w = *wIt;
						w->tap(tap->position());
					}
					_widgetsMutex.unlock();
				}
			}
			
			if(dynamic_pointer_cast<PinchGesture>(unknownGesture)) {
				shared_ptr<PinchGesture> pinch = dynamic_pointer_cast<PinchGesture>(unknownGesture);
				if(pinch->isOnWidget()) {
					_widgetsMutex.lock();
					auto wIt = find_if(_widgets.begin(), _widgets.end(),
									   [&, this](shared_ptr<Widget> w) {
										   return w->id() == pinch->widgetId();
									   });
					if(wIt != _widgets.end()) {
						auto w = *wIt;
						w->moveBy(pinch->distanceDelta());
                        w->zoomBy(pinch->zoomDelta());
                        w->rotateBy(pinch->angleDelta());
					}
					_widgetsMutex.unlock();
				}
			}
			
			if(dynamic_pointer_cast<MusicStrokeGesture>(unknownGesture)) {
				shared_ptr<MusicStrokeGesture> stroke = static_pointer_cast<MusicStrokeGesture>(unknownGesture);
				shared_ptr<MeasureWidget> measure = nullptr;
				_widgetsMutex.lock();
				shared_ptr<Widget> w = *find_if(_widgets.begin(), _widgets.end(),
												[&, this] (shared_ptr<Widget> w) {
													return w->id() == stroke->widgetId();
												});
				if(w != nullptr) {
					measure = dynamic_pointer_cast<MeasureWidget>(w);
				}
				_widgetsMutex.unlock();
				if(measure != nullptr) {
					measure->processStroke(stroke->stroke());
				}
			}
			
			if(dynamic_pointer_cast<ConnectionGesture>(unknownGesture)) {
				shared_ptr<ConnectionGesture> connection = dynamic_pointer_cast<ConnectionGesture>(unknownGesture);
				unsigned long fromWid = connection->fromWid();
				unsigned long toWid = connection->toWid();
				_sequencesMutex.lock();
				
				bool doTheSplice = true;
				list<list<shared_ptr<MeasureWidget>>>::iterator fsIt;
				list<shared_ptr<MeasureWidget>>::iterator fwIt;
				[&, this]() {
					for(auto sit = _sequences.begin(); sit != _sequences.end(); ++sit) {
						for(auto wit = sit->begin(); wit != sit->end(); ++wit) {
							if((*wit)->id() == fromWid) {
								// check if this precedes the destination in the same sequence
								for(auto i(wit); i != sit->begin(); --i) {
									if((*i)->id() == toWid) {
										doTheSplice = false;
										return;
									}
								}
								// cover head case
								if(sit->front()->id() == toWid) {
									doTheSplice = false;
									return;
								}
								fsIt = sit;
								fwIt = wit;
								return;
							}
						}
					}
				}();
				
				if(doTheSplice) {
					list<list<shared_ptr<MeasureWidget>>>::iterator tsIt;
					list<shared_ptr<MeasureWidget>>::iterator twIt;
					[&,this]() {
						for(auto sit = _sequences.begin(); sit != _sequences.end(); ++sit) {
							for(auto wit = sit->begin(); wit != sit->end(); ++wit) {
								if((*wit)->id() == toWid) {
									tsIt = sit;
									twIt = wit;
									return;
								}
							}
						}
					}();
					
					tsIt->splice(twIt, *fsIt, fsIt->begin(), next(fwIt));
				}
				_sequencesMutex.unlock();
			}
			
			if(dynamic_pointer_cast<DisconnectionGesture>(unknownGesture)) {
				shared_ptr<DisconnectionGesture> disc = dynamic_pointer_cast<DisconnectionGesture>(unknownGesture);
				unsigned long fromWid = disc->fromWid();
				unsigned long toWid = disc->toWid();
				bool log = false;
				_sequencesMutex.lock();
				[&,this]() {
					for(auto sit = _sequences.begin(); sit != _sequences.end(); ++sit) {
						for(auto wit = sit->begin(); wit != sit->end(); ++wit) {
							if((*wit)->id() == fromWid && (*next(wit))->id() == toWid) {
								list<shared_ptr<MeasureWidget>> newSeq(next(wit), sit->end());
								_sequences.push_back(newSeq);
								sit->erase(next(wit), sit->end());
								log = true;
								return;
							}
						}
					}
				}();
				_sequencesMutex.unlock();
			}
			
			if(dynamic_pointer_cast<LongTapGesture>(unknownGesture)) {
				shared_ptr<LongTapGesture> longtap = dynamic_pointer_cast<LongTapGesture>(unknownGesture);
				if(!longtap->isOnWidget()) {
					_widgetsMutex.lock();
					vec2 p = longtap->position();
					_gpContext->makeCurrent();
					auto w = make_shared<MeasureWidget>(p, 8, 8);
//					vec2 c = getWindowCenter();
//					float a = atan2(p.y-c.y, p.x-c.x);
//					w->angle(a - M_PI_2);
					_widgets.push_back(w);
					_widgetsMutex.unlock();
					
					_sequencesMutex.lock();
					list<shared_ptr<MeasureWidget>> s;
					s.push_back(w);
					_sequences.push_back(s);
					_sequencesMutex.unlock();
				}
			}
		}
	}
}

void SecondStudy::TheApp::measureHasFinishedPlaying(unsigned long id) {
	_sequencesMutex.lock();
	for(auto sit = _sequences.begin(); sit != _sequences.end(); ++sit) {
		for(auto wit = sit->begin(); wit != sit->end(); ++wit) {
			if((*wit)->id() == id && next(wit) != sit->end()) {
				(*next(wit))->play();
			} else if((*wit)->id() == id && next(wit) == sit->end()) {
				(*sit->begin())->play();
			}
		}
	}
	_sequencesMutex.unlock();
}

void SecondStudy::TheApp::touchesBegan(cinder::app::TouchEvent event) {
	_tracesMutex.lock();
	for(auto touch : event.getTouches()) {
		// This is a brand new trace, we have to do stuff!
		_traces[touch.getId()] = make_shared<TouchTrace>();
		_traces[touch.getId()]->addCursorDown(touch);
		
		// Check if it's on a widget
		_widgetsMutex.lock();
		// This is done in reverse order because I say so.
		for(auto it = _widgets.rbegin(); it != _widgets.rend(); ++it) {
			auto w = *it;
			if(w->hit(touch.getPos())) {
				_traces[touch.getId()]->widgetId = w->id();
				break;
			}
		}
		_widgetsMutex.unlock();
		
		_groupsMutex.lock();
		int g = findGroupForTrace(_traces[touch.getId()]);
		if(g == -1) {
			list<shared_ptr<TouchTrace>> l;
			l.push_back(_traces[touch.getId()]);
			_groups.push_back(l);
		} else {
			_groups[g].push_back(_traces[touch.getId()]);
		}
		_groupsMutex.unlock();
		
		for(auto &g : _groups) {
			for(auto pgr : _progressiveGRs) {
				pgr->processGroup(g);
			}
		}
	}
	_tracesMutex.unlock();
}

void SecondStudy::TheApp::touchesMoved(cinder::app::TouchEvent event) {
	for(auto touch : event.getTouches()) {
		_go = true;
		_tracesMutex.lock();
		_traces[touch.getId()]->cursorMove(touch);
		_tracesMutex.unlock();
		
		for(auto &g : _groups) {
			for(auto pgr : _progressiveGRs) {
				pgr->processGroup(g);
			}
		}
	}
}

void SecondStudy::TheApp::touchesEnded(cinder::app::TouchEvent event) {
	for(auto touch : event.getTouches()) {
		_go = true;
		_tracesMutex.lock();
		_traces[touch.getId()]->addCursorUp(touch);
		_traces[touch.getId()]->isVisible = false;
		_tracesMutex.unlock();
	}
}

int SecondStudy::TheApp::findGroupForTrace(shared_ptr<TouchTrace> trace) {
	// First: group traces on the same widget
	for(int i = 0; i < _groups.size(); i++) {
		for(auto otherTrace : _groups[i]) {
			if(trace->widgetId == otherTrace->widgetId && otherTrace->widgetId != 0) {
				return i;
			}
		}
	}
	return -1;
}

CINDER_APP( SecondStudy::TheApp, RendererGl(RendererGl::Options().msaa(2)),
[](App::Settings *settings){
	settings->setHighDensityDisplayEnabled(true);
//	settings->setFrameRate(FPS);
	settings->disableFrameRate();
});