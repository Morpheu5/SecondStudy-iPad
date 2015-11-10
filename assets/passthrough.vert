uniform mat4 ciModelViewProjection;

attribute vec4 ciPosition;
attribute vec2 ciTexCoord0;

varying highp vec2 TexCoord0;

void main(void) {
	TexCoord0 = ciTexCoord0;
	gl_Position = ciModelViewProjection * ciPosition;
}