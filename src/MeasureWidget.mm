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

SecondStudy::MeasureWidget::MeasureWidget() : Widget() { }

SecondStudy::MeasureWidget::MeasureWidget(vec2 center, int rows, int columns) : Widget(),
_measureSize(pair<int, int>(columns, rows)) {
	// C major diatonic
	// CAREFUL: DO NOT push more than necessary
	_midiNotes.push_back(60);
	_midiNotes.push_back(62);
	_midiNotes.push_back(64);
	_midiNotes.push_back(65);
	_midiNotes.push_back(67);
	_midiNotes.push_back(69);
	_midiNotes.push_back(71);
	_midiNotes.push_back(72);
	reverse(_midiNotes.begin(), _midiNotes.end());

	notes = vector<int>((size_t)columns, -1);

    _scale = 1.0f;
	_angle = 0.0f;
	_position = center;
	_noteBox = Rectf(0.0f, 0.0f, 30.0f, 30.0f);
	_boundingBox = Rectf(0.0f, 0.0f, _noteBox.getWidth() * columns, _noteBox.getHeight() * rows);
	_boundingBox -= _boundingBox.getSize() / 2.0f;
	
	_playIcon = Rectf(0.0f, 0.0f, _noteBox.getWidth(), _noteBox.getHeight());
	_playIcon += _boundingBox.getUpperLeft() - vec2(0.0f, _noteBox.getHeight() + 10.0f);

	_inletIcon = Rectf(0.0f, 0.0f, _noteBox.getWidth(), _noteBox.getHeight());
	_inletIcon += vec2(_boundingBox.getUpperLeft().x - _inletIcon.getWidth() + 10.0f, -_inletIcon.getWidth()/2.0f);

	_outletIcon = Rectf(0.0f, 0.0f, _noteBox.getWidth(), _noteBox.getHeight());
	_outletIcon += vec2(_boundingBox.getUpperRight().x - 10.0f, -_outletIcon.getWidth()/2.0f);

	_clearIcon = Rectf(0.0f, 0.0f, _noteBox.getWidth(), _noteBox.getHeight());
	_clearIcon += _boundingBox.getUpperRight() + vec2(-_noteBox.getWidth(), -_noteBox.getHeight() - 10.0f);

	_cursorOffset = vec2(0.0f, 0.0f);
	_cursor = Rectf(vec2(0.0f, 0.0f), vec2(_noteBox.getWidth(), 5.0f));
	_cursor += _boundingBox.getLowerLeft();

	isPlaying = false;

	_noteBoxBatch = gl::Batch::create(geom::Rect().rect(_noteBox - _noteBox.getSize()/2.0f)
									  .colors(ColorAf::white(), ColorAf::white(), ColorAf::white(), ColorAf::white()),
									  gl::getStockShader(gl::ShaderDef().color()));

	_boardShader = gl::GlslProg::create(gl::GlslProg::Format().vertex(loadAsset("passthrough.vert")).fragment(loadAsset("grid.frag")));
	
	_boardBatch = gl::Batch::create(geom::Rect().rect(_boundingBox)
									.colors(ColorAf(1.0f, 1.0f, 1.0f, 0.333f), ColorAf(1.0f, 1.0f, 1.0f, 0.333f), ColorAf(1.0f, 1.0f, 1.0f, 0.333f), ColorAf(1.0f, 1.0f, 1.0f, 0.333f)),
									_boardShader);
	
	gl::VertBatch lines(GL_LINES);
	vec2 offset = _boundingBox.getUpperLeft();
	for(int x = 0; x < 9; ++x) {
		lines.color(ColorAf(1, 1, 1, 0.75));
		lines.vertex(vec2(x * _noteBox.getWidth(), -2.0f * offset.y) + offset);
		lines.vertex(vec2(x * _noteBox.getWidth(), 0.0f) + offset);
	}
	for(int y = 0; y < 9; ++y) {
		lines.color(ColorAf(1, 1, 1, 0.75));
		lines.vertex(vec2(-2.0f * offset.x, y * _noteBox.getHeight()) + offset);
		lines.vertex(vec2(0.0f, y * _noteBox.getWidth()) + offset);
	}
	_gridlinesBatch = gl::Batch::create(lines, gl::getStockShader(gl::ShaderDef().color()));

	_circleBatch = gl::Batch::create(geom::Circle().subdivisions(24).radius(_inletIcon.getWidth()/2.0f), gl::getStockShader(gl::ShaderDef().color()));

	_cursorBatch = gl::Batch::create(geom::Rect().rect(Rectf(0.0f, 0.0f, 30.0f, 5.0f))
									 .colors(ColorAf(1.0f, 1.0f, 1.0f, 0.5f), ColorAf(1.0f, 1.0f, 1.0f, 0.5f), ColorAf(1.0f, 1.0f, 1.0f, 0.5f), ColorAf(1.0f, 1.0f, 1.0f, 0.5f)),
									 gl::getStockShader(gl::ShaderDef().color()));

	_playIconBatch = gl::Batch::create(geom::Rect().rect(_playIcon)
									   .texCoords(vec2(0.0f, 0.0f), vec2(1.0f, 0.0f), vec2(1.0f, 1.0f), vec2(0.0f, 1.0f))
									   .colors(ColorAf::white(), ColorAf::white(), ColorAf::white(), ColorAf::white()),
									   gl::getStockShader(gl::ShaderDef().color().texture()));
	_clearIconBatch = gl::Batch::create(geom::Rect().rect(_clearIcon)
										.texCoords(vec2(0.0f, 0.0f), vec2(1.0f, 0.0f), vec2(1.0f, 1.0f), vec2(0.0f, 1.0f))
										.colors(ColorAf::white(), ColorAf::white(), ColorAf::white(), ColorAf::white()),
										gl::getStockShader(gl::ShaderDef().color().texture()));
	gl::Texture::Format f;
	f.loadTopDown();
	_playIconTex = gl::Texture::create(loadImage(loadAsset("play-icon.png")), f);
	_stopIconTex = gl::Texture::create(loadImage(loadAsset("stop-icon.png")), f);
	_clearIconTex = gl::Texture::create(loadImage(loadAsset("clear-icon.png")), f);
}

void SecondStudy::MeasureWidget::draw() {
	gl::ScopedModelMatrix giantMM;

	mat4 transform = translate(vec3(_position, 0)) * rotate(_angle, vec3(0.f, 0.f , 1.f));
	gl::multModelMatrix(transform);

	{	// INLET ICON
		gl::ScopedColor color(ColorAf(0.118f, 0.565f, 1.0f, 1.0f));
		gl::ScopedModelMatrix scopedMM;
		mat4 t = translate(vec3(_inletIcon.getCenter(), 0.0f));
		gl::multModelMatrix(t);
		_circleBatch->draw();
	}

	{	// OUTLET ICON
		gl::ScopedColor color(ColorAf(0.882f, 0.435f, 0.0f, 1.0f));
		gl::ScopedModelMatrix scopedMM;
		mat4 t = translate(vec3(_outletIcon.getCenter(), 0.0f));
		gl::multModelMatrix(t);
		_circleBatch->draw();
	}

	{	// BACKGROUND BOX
//		_boardShader->uniform("gridSize", vec2(8.0f, 8.0f));
		_boardBatch->draw();
	}
	
	{
		_gridlinesBatch->draw();
	}

	// NOTES
	vec2 origin = _boundingBox.getUpperLeft() + vec2(15.0f, 15.0f);
	for(size_t i = 0; i < notes.size(); i++) {
		if(notes[i] >= 0) {
			mat4 boxt = translate(vec3(origin.x + i*30.0f, origin.y + notes[i]*30.0f, 0.0f));
			gl::ScopedModelMatrix boxScopedMatrix;
			gl::multModelMatrix(boxt);
			_noteBoxBatch->draw();
		}
	}

	// PLAY/STOP ICON
	if(isPlaying) {
		gl::ScopedTextureBind tex(_stopIconTex);
		_playIconBatch->draw();
	} else {
		gl::ScopedTextureBind tex(_playIconTex);
		_playIconBatch->draw();
	}

	{	// CLEAR ICON
		gl::ScopedTextureBind sTex(_clearIconTex);
		_clearIconBatch->draw();
	}

	{	// PLAYHEAD
		gl::ScopedModelMatrix cursorMM;
		mat4 t = translate(vec3(_boundingBox.getLowerLeft() + _cursorOffset.value(), 0.0f));
		gl::multModelMatrix(t);
		_cursorBatch->draw();
	}

	gl::color(Color::white());
}

bool SecondStudy::MeasureWidget::hit(vec2 p) {
	mat4 transform = translate(vec3(_position, 0.0f)) * rotate(_angle, vec3(0.0f, 0.0f, 1.0f));
	auto ttp = inverse(transform) * vec4(p, 0, 1);
	vec2 tp = vec2(ttp);
	return (_boundingBox * _scale).contains(tp)
			|| (_playIcon * _scale).contains(tp)
			|| (_inletIcon * _scale).contains(tp)
			|| (_outletIcon * _scale).contains(tp)
			|| (_clearIcon * _scale).contains(tp);
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
	} else if((_clearIcon * _scale).contains(tp)) {
		for(size_t i = 0; i < notes.size(); i++) {
			notes[i] = -1;
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

	for(int i : _midiNotes) {
		[theApp->sampler stopPlayingNote:i];
	}
	if(notes[n] >= 0) {
		[theApp->sampler startPlayingNote:_midiNotes[notes[n]] withVelocity:0.5];
	}

//	osc::Message m;
//	m.setAddress("/playnote");
//	m.addIntArg(_midiNotes[i]);
//	theApp->sender()->sendMessage(m);
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
	if(note.first >= 0 && note.first < notes.size()) {
		if(notes[note.first] == -1) {
			notes[note.first] = note.second;
		} else if(notes[note.first] == note.second) {
			notes[note.first] = -1;
		} else {
			notes[note.first] = note.second;
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
			tp *= vec2(notes.size(), _midiNotes.size());// notes[0].size());
			ivec2 n = ivec2(tp);
			noteSet.insert(pair<int, int>(n.x, n.y));
		}
	}
	
	for(auto n : noteSet) {
		toggle(n);
	}
}