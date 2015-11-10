precision lowp float;

//uniform vec2 gridSize;
//varying vec2 TexCoord0;

void main(void) {
//	vec2 offset = vec2(0.25, 0.25);
//	vec2 f = (pow(gridSize, vec2(2.0, 2.0)) + offset) / gridSize;
//	vec2 m = mod(f * TexCoord0, vec2(1.0, 1.0));
//
//	vec2 og = offset/gridSize;
//	vec2 o = step(m, og); //1.0-smoothstep(m+og, m, m);
//	gl_FragColor = vec4(o.x + o.y);
	gl_FragColor = vec4(1, 1, 1, 0.25);
}