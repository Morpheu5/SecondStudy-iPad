#pragma once

#include "Widget.h"

using namespace ci;

namespace SecondStudy {

	class BoxWidget : public Widget {
		Rectf _board;

	public:
		BoxWidget();
		BoxWidget(vec2 center);

		void draw();
		bool hit(vec2 p);
		void tap(vec2 p);
		void moveBy(vec2 v);
        void zoomBy(float s);
        void rotateBy(float a);
	};
}