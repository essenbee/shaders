float dCircle(vec2 pos, float radius)
{
    return length(pos) - radius;
}

float dRoundBox(vec2 pos, float radius)
{
  pos = pos*pos;
  pos = pos*pos;
  float d8 = dot(pos, pos);
  return pow(d8, 1.0/8.0) - radius;
  
}

float dBox(vec2 pos, vec2 siz)
{
    pos = abs(pos);
    float dx = pos.x - siz.x;
    float dy = pos.y - siz.y;
    return max(dx, dy);
}

vec2 toPolarCoords(vec2 rectCoords)
{
    return vec2(length(rectCoords),atan(rectCoords.y, rectCoords.x));
}

vec2 toRectCoords(vec2 polarCoords)
{
    return vec2(polarCoords.x * cos(polarCoords.y), polarCoords.x * sin(polarCoords.y));
}

#define PI 3.141592654
#define TAU (2.0*PI)

// Repeat in two dimensions
vec2 pMod2(inout vec2 p, vec2 size) {
    vec2 c = floor((p + size*0.5)/size);
    p = mod(p + size*0.5,size) - size*0.5;
    return c;
}

float dF2(vec2 pos)
{
 vec2 pp = toPolarCoords(pos);
  float a = TAU/30.0;
  float np = pp.y/a;
  pp.y = mod(pp.y, a);
  float m2 = mod(np, 2.0);
  if (m2 > 1.0)
  {
    pp.y = a - pp.y;
  }

    pp.y += iTime;
    pos = toRectCoords(pp);
  
     pMod2(pos, vec2(0.5));

    float d1 = dCircle(pos, 0.1);

    float d3 = dBox(pos - vec2(0.1), vec2(0.1, 0.1));
    float d = min(d1, d3);
    return d;
}

float dF(vec2 pos)
{
    //pos = abs(pos);
    vec2 pPos = toPolarCoords(pos);
    pPos.y = mod(pPos.y, TAU/7.0);
    pPos.y += iTime;
    
   // pPos.x *= 1.0 + pos.y;
    pos = toRectCoords(pPos);
    pMod2(pos, vec2(0.5));

    float d1 = dCircle(pos, 0.1);

    float d3 = dBox(pos - vec2(0.1), vec2(0.1, 0.1));
    float d = min(d1, d3);
    return d;
}

void rotate(inout vec2 pos, float angle)
{
  float c = cos(angle);
  float s = sin(angle);
  pos = vec2(c*pos.x + s*pos.y, -s*pos.x + c*pos.y);
    
}

vec3 postProcess (vec3 col, vec2 pos)
{
    rotate(pos, iTime);
    col = clamp(col, 0.0, 1.0);
    return pow(col, vec3(abs(pos.x), abs(pos.y), length(pos)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy - vec2(0.5);
    uv.x *= iResolution.x/iResolution.y;
    
    float d = dF2(uv);
    
    
    vec3 col = vec3(0);
    
    float md = mod(d, 0.1);
    float nd = abs(d / 0.1);
    
    if (abs(md) < 0.01)
    {
        if (d < 0.0)
        {
            col = vec3(1, 0.3 ,0.15)/ nd;
        }
        else
        {
            col = vec3(0.3, 1, 0.15) / nd;
        }
    }
    
    if (abs(d) < 0.02)
    {
        col = vec3(1);
    }

    fragColor = vec4(postProcess(col, uv),1.0);
}