
#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PI 3.14159265359
uniform float time;

uniform vec2 resolution;
uniform sampler2D previous;
uniform sampler2D texture;
uniform float minVel= 0.01; 
uniform float maxVel = 0.5; 
uniform float offsetInc = 0.1;
uniform vec2 offset = vec2(1.0, 1.0);
uniform float lambda = 1.0;
uniform vec2 scale = vec2(1.0, 1.0);
uniform float threshold = 0.15;
uniform float intensity = 5.0;

in vec4 vertTexCoord;
in vec4 vertColor;
out vec4 fragColor;

vec4 packFlowAsColor(float fx ,float fy, vec2 scale){
	vec2 flowX = vec2(max(fx, 0.0), abs(min(fx, 0.0))) * scale.x;
	vec2 flowY = vec2(max(fy, 0.0), abs(min(fy, 0.0))) * scale.y;
	float dirY = 1.0;
	if(flowY.x > flowY.y){
		dirY = 0.9;
	}
	vec4 rgbaPacked = vec4(flowX.x, flowX.y, max(flowY.x, flowY.y), dirY);

	return rgbaPacked;
}

vec2 getFlowVector(float fx ,float fy, vec2 scale){
	vec2 flowX = vec2(max(fx, 0.0), abs(min(fx, 0.0))) * scale.x;
	vec2 flowY = vec2(max(fy, 0.0), abs(min(fy, 0.0))) * scale.y;
	float dirY = 1.0;
	if(flowY.x > flowY.y){
		dirY = -1.0;
	}
	//vec4 rgbaPacked = vec4(flowX.x, flowX.y, max(flowY.x, flowY.y), dirY);

	float x = flowX.x + flowX.y * -1.0;
	float y = max(flowY.x, flowY.y) * dirY;

	return vec2(x, y);
}

vec4 getGray(vec4 inputPix){
	float gray = dot(vec3(inputPix.x, inputPix.y, inputPix.z), vec3(0.3, 0.59, 0.11));
	return vec4(gray, gray, gray, 1.0);
}

vec4 getGrayTexture(sampler2D tex, vec2 texCoord){
	return getGray(texture2D(tex, texCoord));
}

vec4 getGradientAt(sampler2D current, sampler2D previous, vec2 texCoord, vec2 offset){
	vec4 gradient = getGrayTexture(previous, texCoord + offset) - getGrayTexture(previous, texCoord - offset);
	gradient += getGrayTexture(current, texCoord + offset) - getGrayTexture(current, texCoord - offset);
	return gradient;
}



void main()
{
	vec4 current = texture(texture, vertTexCoord.st);
	vec4 prev = texture(previous, vertTexCoord.st);
	
	vec2 offsetX = vec2(offset.x * offsetInc, 0.0);
	vec2 offsetY = vec2(0.0, offset.y * offsetInc);

	//Frame Differencing (dT)
	vec4 differencing = prev - current;
	float vel = (differencing.r + differencing.g + differencing.b)/3;
	float movement = smoothstep(minVel, maxVel, vel);
	vec4 newDifferencing = vec4(movement);
	//movement = pow(movement, 1.0);


	//Compute the gradient (movement Per Axis) (look alike sobel Operation)
	vec4 gradX = getGradientAt(texture, previous, vertTexCoord.st, offsetX);
	vec4 gradY = getGradientAt(texture, previous, vertTexCoord.st, offsetY);

	//Compute gradMagnitude
	vec4 gradMag = sqrt((gradX * gradX) + (gradY * gradY) + vec4(lambda));

	//compute Flow
	vec4 vx = newDifferencing * (gradX / gradMag);
	vec4 vy = newDifferencing * (gradY / gradMag);

	//vec4 flowCoded = packFlowAsColor(vx.r, vy.r, scale);
	vec2 flow = getFlowVector(vx.x, vy.x, vec2(intensity));
	float flowMag = length(flow.xy);

	float stepper = step(threshold, flowMag);
	flow.x = clamp(flow.x, -1.0, 1.0);
	flow.y = clamp(flow.y, -1.0, 1.0);

	vec2 st;
	vec2 texel = vec2(1.0) / resolution;
	st.x = vertTexCoord.x + flow.x * texel.x * intensity;
	st.y = vertTexCoord.y + flow.y * texel.y * intensity;

	//shift rgb
	vec2 shift = vec2(cos(flow.x * PI + time * 0.1), sin(flow.y * PI + time * 0.1)) * 0.0025;
	float r = texture(previous, st + shift).r;
	float g = texture(previous, st ).g;
	float b = texture(previous, st - shift).b;

	vec4 datamosh = texture(previous, st);
	datamosh.rgb = vec3(r, g, b) * stepper;

	vec4 color = texture(texture, vertTexCoord.st);
	
	fragColor =  color * (1.0 - stepper) + datamosh * stepper;;
}
