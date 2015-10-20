#include "BoxWidget.h"

using namespace ci;

SecondStudy::BoxWidget::BoxWidget() : SecondStudy::Widget() {
	_scale = 1.0f;
	_board = Rectf(-80.0f, -60.0f, 80.0f, 60.0f);
	_position = vec2(0.0f, 0.0f);
	_angle = 0.0f;
}

SecondStudy::BoxWidget::BoxWidget(vec2 center) : SecondStudy::Widget() {
	_scale = 1.0f;
	_board = Rectf(-80.0f, -60.0f, 80.0f, 60.0f);
	_angle = 0.0f;
	_position = center;
}

void SecondStudy::BoxWidget::draw() {
	gl::pushModelView();

	mat4 transform = translate(vec3(_position, 0)) * rotate(_angle, vec3(0,0,1));
	gl::multModelMatrix(transform);

	gl::color(1.0f, 1.0f, 1.0f, 0.25f);
	gl::drawSolidRect(_board * _scale);

	gl::color(1.0f, 1.0f, 1.0f, 1.0f);
	gl::lineWidth(_scale);
	gl::drawStrokedRect(_board * _scale);

	gl::popModelView();
}

bool SecondStudy::BoxWidget::hit(vec2 p) {
	mat4 transform = translate(vec3(_position, 0)) * rotate(_angle, vec3(0,0,1));

	vec2 tp = vec2(inverse(transform) * vec4(p, 0, 0));
	return (_board * _scale).contains(tp);
}

void SecondStudy::BoxWidget::tap(vec2 p) {
	//_scale += 0.1f;
}

void SecondStudy::BoxWidget::moveBy(vec2 v) {
	_position += v;
}

void SecondStudy::BoxWidget::zoomBy(float s) {
    // _scale += s;
}

void SecondStudy::BoxWidget::rotateBy(float a) {
    _angle += a;
}