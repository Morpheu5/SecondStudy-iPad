#pragma once

#include "cinder/gl/Texture.h"
#include "Widget.h"
#include "cinder/Timeline.h"

using namespace ci;
using namespace std;

#define MEASUREWIDGET_NOTELENGTH 0.25f

namespace SecondStudy {
	
	class TouchTrace;
    
	class MeasureWidget : public Widget {
		Rectf _noteBox;
		Rectf _boundingBox;
		
		Rectf _playIcon;
		ColorAf _playColorBg, _playColorFg;
		ColorAf _stopColorBg, _stopColorFg;

		Rectf _inletIcon;
		ColorAf _inletColor;

		Rectf _outletIcon;
		ColorAf _outletColor;
		
		Rectf _cursor;
		Anim<vec2> _cursorOffset;

		gl::TextureRef _noteOnTex;
		gl::TextureRef _noteOffTex;
		
		CueRef _cue;

        pair<int, int> _measureSize;
		
		vector<int> _midiNotes;
		
		void playNote(int n);
		void finishedPlaying();

	public:
		vector<vector<bool>> notes;
		mutex notesMutex;
		
		bool isPlaying;
		
		MeasureWidget();
		MeasureWidget(vec2 center, int rows, int columns);
        
		void draw();
		bool hit(vec2 p);
		void tap(vec2 p);
		void moveBy(vec2 v);
        void zoomBy(float s);
        void rotateBy(float a);
		
		bool hitInlet(vec2 p);
		bool hitOutlet(vec2 p);
		
		const pair<int, int>& measureSize() const { return _measureSize; }
		const Rectf& inletIcon() const { return _inletIcon; }
		const Rectf& outletIcon() const { return _outletIcon; }
		
		void toggle(pair<int, int> note);
		void processStroke(const TouchTrace trace);
		
		void play();
		void stop();
	};
}