#include "MeasureWidget.h"

#include "TouchPoint.h"
#include "TouchTrace.h"

#include "SecondStudy_iPadApp.h"

#include "Logger.h"

#include <set>

#import "EPSSampler.h"

using namespace ci;
using namespace ci::app;
using namespace std;

SecondStudy::MeasureWidget::MeasureWidget() : Widget() {
	_scale = 1.0f;
	_position = vec2(0.0f, 0.0f);
	_angle = 0.0f;
    _measureSize = pair<int, int>(5, 8);
	_noteBox = Rectf(0.0f, 0.0f, 30.0f, 30.0f);
	_boundingBox = Rectf(0.0f, 0.0f, _noteBox.getWidth() * _measureSize.second, _noteBox.getHeight() * _measureSize.first);
	_boundingBox -= _boundingBox.getSize() / 2.0f;
	
	_playIcon = Rectf(0.0f, 0.0f, _noteBox.getWidth()-10, _noteBox.getHeight()-10);
	_playIcon += _boundingBox.getUpperLeft() - vec2(0.0f, _noteBox.getHeight());

	_inletIcon = Rectf(0.0f, 0.0f, _noteBox.getWidth(), _noteBox.getHeight());
	_inletIcon += vec2(-_inletIcon.getWidth()+10.0f, _boundingBox.getCenter().y);
	
	_outletIcon = Rectf(0.0f, 0.0f, _noteBox.getWidth(), _noteBox.getHeight());
	_outletIcon += vec2(-_boundingBox.getWidth()-10.0f, _boundingBox.getCenter().y);
	
	_cursorOffset = vec2(0.0f, 0.0f);
	_cursor = Rectf(vec2(0.0f, 0.0f), vec2(_noteBox.getWidth(), 10.0f));
	_cursor += _boundingBox.getLowerLeft();
	
	// C major pentatonic
	_midiNotes.push_back(81);
	_midiNotes.push_back(79);
	_midiNotes.push_back(76);
	_midiNotes.push_back(74);
	_midiNotes.push_back(72);
	_midiNotes.push_back(69);
	_midiNotes.push_back(67);
	_midiNotes.push_back(64);
	_midiNotes.push_back(62);
	_midiNotes.push_back(60);

	notes = vector<vector<bool>>(1, vector<bool>(1, false));
	
	isPlaying = false;
}

SecondStudy::MeasureWidget::MeasureWidget(vec2 center, int rows, int columns) : Widget(),
_measureSize(pair<int, int>(columns, rows)) {
	
    _scale = 1.0f;
	_angle = 0.0f;
	_position = center;
	_noteBox = Rectf(0.0f, 0.0f, 30.0f, 30.0f);
	_boundingBox = Rectf(0.0f, 0.0f, _noteBox.getWidth() * columns, _noteBox.getHeight() * rows);
	_boundingBox -= _boundingBox.getSize() / 2.0f;
	
	_playIcon = Rectf(0.0f, 0.0f, _noteBox.getWidth(), _noteBox.getHeight());
	_playIcon += _boundingBox.getUpperLeft() - vec2(0.0f, _noteBox.getHeight() + 10.0f);
	_playColorBg = ColorAf(ColorModel::CM_HSV, 90.0f/360.0f, 0.88f, 0.5f);
	_playColorFg = ColorAf(ColorModel::CM_HSV, 90.0f/360.0f, 0.88f, 0.75f);
	_stopColorBg = ColorAf(ColorModel::CM_HSV, 30.0f/360.0f, 0.88f, 0.5f);
	_stopColorFg = ColorAf(ColorModel::CM_HSV, 30.0f/360.0f, 0.88f, 0.75f);

	_inletIcon = Rectf(0.0f, 0.0f, _noteBox.getWidth(), _noteBox.getHeight());
	_inletIcon += vec2(_boundingBox.getUpperLeft().x - _inletIcon.getWidth() + 10.0f, -_inletIcon.getWidth()/2.0f);
	_inletColor = ColorAf(ColorModel::CM_HSV, 210.0f/360.0f, 0.88f, 1.0f);

	_outletIcon = Rectf(0.0f, 0.0f, _noteBox.getWidth(), _noteBox.getHeight());
	_outletIcon += vec2(_boundingBox.getUpperRight().x - 10.0f, -_outletIcon.getWidth()/2.0f);
	_outletColor = ColorAf(ColorModel::CM_HSV, 30.0f/360.0f, 0.88f, 1.0f);

	_cursorOffset = vec2(0.0f, 0.0f);
	_cursor = Rectf(vec2(0.0f, 0.0f), vec2(_noteBox.getWidth(), 5.0f));
	_cursor += _boundingBox.getLowerLeft();

	_noteOnTex = gl::Texture::create(loadImage(loadAsset("note-on.png")));
	_noteOffTex = gl::Texture::create(loadImage(loadAsset("note-off.png")));

	// C major pentatonic
	_midiNotes.push_back(81);
	_midiNotes.push_back(79);
	_midiNotes.push_back(76);
	_midiNotes.push_back(74);
	_midiNotes.push_back(72);
	_midiNotes.push_back(69);
	_midiNotes.push_back(67);
	_midiNotes.push_back(64);
	_midiNotes.push_back(62);
	_midiNotes.push_back(60);
	
	notes = vector<vector<bool>>(columns, vector<bool>(rows, false));
	
	isPlaying = false;

	_noteBoxShader = gl::getStockShader(gl::ShaderDef().color());
	_noteBoxBatch = gl::Batch::create(geom::Rect().rect(_noteBox).colors(ColorAf::white(), ColorAf::white(), ColorAf::white(), ColorAf::white()), _noteBoxShader);
}

void SecondStudy::MeasureWidget::draw() {
	// inlet:   0.118f, 0.565f, 1.0f, 1.0f
	// outlet:  0.882f, 0.435f, 0.0f, 1.0f
	// stop bg: 0.659f, 0.329f, 0.0f, 1.0f
	// stop fg: 0.882f, 0.435f, 0.0f, 1.0f
	// play bg: 0.329f, 0.659f, 0.0f, 1.0f
	// play fg: 0.435f, 0.882f, 0.0f, 1.0f

	gl::pushModelView();

	mat4 transform = translate(vec3(_position, 0)) * rotate(_angle, vec3(0,0,1));
	gl::multModelMatrix(transform);

	gl::color(0.118f, 0.565f, 1.0f, 1.0f);
	gl::drawSolidCircle(_inletIcon.getCenter(), _inletIcon.getWidth()/2.0f);

	gl::color(0.882f, 0.435f, 0.0f, 1.0f);
	gl::drawSolidCircle(_outletIcon.getCenter(), _outletIcon.getWidth()/2.0f);

	gl::color(1,1,1,0.333f);
	gl::drawSolidRect(_boundingBox);

	gl::color(1,1,10.667f);
	gl::lineWidth(2.0f);
	unsigned long cols = notes.size();
	unsigned long rows = notes[0].size();
	vec2 origin = _boundingBox.getUpperLeft();
	for(unsigned long col = 0; col < cols; col++) {
		for(unsigned long row = 0; row < rows; row++) {
			mat4 boxt = translate(vec3(origin, 0.0f)) * translate(vec3(col*30.0f, row*30.0f, 0.0f));
			gl::ScopedModelMatrix boxScopedMatrix;
			gl::multModelMatrix(boxt);
			if(notes[col][row]) {
				_noteBoxBatch->draw();
			}
		}
	}

	if(isPlaying) {
		gl::color(0.659f, 0.329f, 0.0f, 1.0f);
		gl::drawSolidRect(_playIcon);
		gl::color(0.882f, 0.435f, 0.0f, 1.0f);
		gl::drawSolidRect(Rectf(_playIcon.getUpperLeft() + vec2(7.5f, 7.5f), _playIcon.getLowerRight() - vec2(7.5f, 7.5f)));
	} else {
		gl::color(0.329f, 0.659f, 0.0f, 1.0f);
		gl::drawSolidRect(_playIcon);
		gl::color(0.435f, 0.882f, 0.0f, 1.0f);
		gl::drawSolidTriangle(_playIcon.getUpperLeft() + vec2(10.0f, 7.5f), _playIcon.getLowerLeft() + vec2(10.0f, -7.5f), _playIcon.getCenter() + vec2(10.0f, 0.0f));
	}

	gl::color(1.0f, 1.0f, 1.0f, 0.5f);
	gl::drawSolidRect(_cursor + _cursorOffset);

	gl::popModelView();
	gl::color(1,1,1);
}

bool SecondStudy::MeasureWidget::hit(vec2 p) {
	mat4 transform = translate(vec3(_position, 0.0f)) * rotate(_angle, vec3(0.0f, 0.0f, 1.0f));
	auto ttp = inverse(transform) * vec4(p, 0, 1);
	vec2 tp = vec2(ttp);
	return (_boundingBox * _scale).contains(tp)
			|| (_playIcon * _scale).contains(tp)
			|| (_inletIcon * _scale).contains(tp)
			|| (_outletIcon * _scale).contains(tp);
}

bool SecondStudy::MeasureWidget::hitInlet(vec2 p) {
	mat4 transform = translate(vec3(_position, 0)) * rotate(_angle, vec3(0,0,1));
	vec2 tp(inverse(transform) * vec4(p, 0, 1));
	return (_inletIcon * _scale).contains(tp);
}

bool SecondStudy::MeasureWidget::hitOutlet(vec2 p) {
	mat4 transform = translate(vec3(_position, 0)) * rotate(_angle, vec3(0,0,1));
	vec2 tp(inverse(transform) * vec4(p, 0, 1));
	return (_outletIcon * _scale).contains(tp);
}

void SecondStudy::MeasureWidget::tap(vec2 p) {
	mat4 transform = translate(vec3(_position, 0)) * rotate(_angle, vec3(0,0,1));
	vec2 tp(inverse(transform) * vec4(p, 0, 1));
	
	if((_playIcon * _scale).contains(tp)) {
		if(isPlaying) {
			stop();
		} else {
			play();
		}
	}
}

void SecondStudy::MeasureWidget::play() {
	app::timeline().apply(&_cursorOffset, vec2(0.0f, 0.0f), 0);
	app::timeline().appendTo(&_cursorOffset, vec2(_boundingBox.getWidth() * (1.0f - 1.0f/notes.size()), 0.0f), MEASUREWIDGET_NOTELENGTH*(notes.size()-1));
	app::timeline().appendTo(&_cursorOffset, vec2(0.0f, 0.0f), MEASUREWIDGET_NOTELENGTH, EaseInOutSine());
	
	for(int i = 0; i < notes.size(); i++) {
		_cue = app::timeline().add( bind(&MeasureWidget::playNote, this, i), app::timeline().getCurrentTime() + MEASUREWIDGET_NOTELENGTH*i);
	}
	_cue = app::timeline().add( bind(&MeasureWidget::finishedPlaying, this), app::timeline().getCurrentTime() + MEASUREWIDGET_NOTELENGTH*(notes.size()));
	_cue->setAutoRemove(true);
	_cue->setLoop(false);
	
	isPlaying = true;
}

void nop() { }

void SecondStudy::MeasureWidget::stop() {
	TheApp *theApp = (TheApp *)App::get();
	for(int i = 0; i < _midiNotes.size(); i++) {
		[theApp->sampler stopPlayingNote:_midiNotes[i]];
	}
	app::timeline().clear();
	app::timeline().apply(&_cursorOffset, vec2(0.0f, 0.0f), MEASUREWIDGET_NOTELENGTH, EaseInOutSine());
	_cue->create(nop);
	isPlaying = false;
}

void SecondStudy::MeasureWidget::playNote(int n) {
	TheApp *theApp = (TheApp *)App::get();
	
	for(int i = 0; i < notes[n].size(); i++) {
		if(notes[n][i]) {
			for(int i = 0; i < _midiNotes.size(); i++) {
				[theApp->sampler stopPlayingNote:_midiNotes[i]];
			}
			[theApp->sampler startPlayingNote:_midiNotes[i] withVelocity:1];
//			osc::Message m;
//			m.setAddress("/playnote");
//			m.addIntArg(_midiNotes[i]);
//			theApp->sender()->sendMessage(m);
		}
	}
}

void SecondStudy::MeasureWidget::finishedPlaying() {
	isPlaying = false;
	TheApp *theApp = (TheApp *)App::get();
	theApp->measureHasFinishedPlaying(_id);
}

void SecondStudy::MeasureWidget::moveBy(vec2 v) {
	_position += v;
}

void SecondStudy::MeasureWidget::zoomBy(float s) {
    // _scale += s;
}

void SecondStudy::MeasureWidget::rotateBy(float a) {
    _angle += a;
}

void SecondStudy::MeasureWidget::toggle(pair<int, int> note) {
	if(note.first >= 0 && note.first < notes.size() && note.second >= 0 && note.second < notes[0].size()) {
		if(notes[note.first][note.second]) {
			notes[note.first][note.second] = false;
		} else {
			for(auto a : notes[note.first]) {
				a = false;
			}
			notes[note.first][note.second] = true;
		}
	}
}

void SecondStudy::MeasureWidget::processStroke(const TouchTrace trace) {
	mat4 transform = translate(vec3(_position, 0)) * rotate(_angle, vec3(0,0,1));
	set<pair<int, int>> noteSet;
	for(auto& q : trace.touchPoints) {
		vec2 tp(inverse(transform) * vec4(q.getPos(), 0, 1));
		if((_boundingBox * _scale).contains(tp)) {
			tp += _boundingBox.getLowerRight();
			tp /= _boundingBox.getSize();
			tp *= vec2(notes.size(), notes[0].size());
			ivec2 n = ivec2(tp);
			noteSet.insert(pair<int, int>(n.x, n.y));
		}
	}
	
	for(auto n : noteSet) {
		toggle(n);
	}
}