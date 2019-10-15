// On shadertoy.com, set iChannel0 to the texture "Grey Noise Medium"

precision highp float;

#define PI  3.141592654
#define TAU (2.0*PI)

#define TOLERANCE       0.001
#define MAX_ITER        100
#define MIN_DISTANCE    0.1
#define MAX_DISTANCE    30.0

const vec3 skyCol1 = vec3(0.35, 0.45, 0.6);
const vec3 skyCol2 = vec3(0.4, 0.7, 1.0);
const vec3 skyCol3 = pow(skyCol1, vec3(0.25));
const vec3 sunCol1 =  vec3(1.0,0.5,0.4);
const vec3 sunCol2 =  vec3(1.0,0.8,0.7);

void rot(inout vec2 p, in float a)
{
  float c = cos(a);
  float s = sin(a);
  
  p = vec2(p.x*c + p.y*s, -p.x*s + p.y*c);
}

float rand(in vec2 co)
{
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 hash(in vec2 p)
{
  p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
  return fract(sin(p)*18.5453);
}

vec4 voronoi(in vec2 x)
{
  vec2 n = floor(x);
  vec2 f = fract(x);

  vec4 m = vec4(8.0);
  for(int j=-1; j<=1; j++)
  for(int i=-1; i<=1; i++)
  {
    vec2  g = vec2(float(i), float(j));
    vec2  o = hash(n + g);
    vec2  r = g - f + o;
    float d = dot(r, r);
    if(d<m.x)
    {
      m = vec4(d, o.x + o.y, r);
    }
  }

  return vec4(sqrt(m.x), m.yzw);
}

float globalHeight(float f, vec2 op)
{
    return (f *0.9 + (0.5 + 0.5 * cos(op.y *0.1)) * 0.4 - 0.3) * (0.7 + 0.3 *sin((0.5 + 0.25 * (1.0 + sin(op.y))) * op.x - 1.5));
}

float heightFunction(vec2 p)
{
    vec2 op = p;
    p += 0.02;
    p *= 0.0025;
    float f = 0.0;
    float amplitude = 1.0;
    float period = 1.0;
        
    for (int i = 0; i < 7; i++)
    {
        f += amplitude * texture(iChannel0, period * p).x;
        rot(p, 1.0);
        amplitude *= 0.5;
        period *= 2.0;
    }
    
    return globalHeight(f, op);
}

float heightFunctionLo(vec2 p)
{
    vec2 op = p;
    p += 0.02;
    p *= 0.0025;
    float f = 0.0;
    float amplitude = 1.0;
    float period = 1.0;
        
    for (int i = 0; i < 6; i++)
    {
        f += amplitude * texture(iChannel0, period * p).x;
        rot(p, 1.0);
        amplitude *= 0.5;
        period *= 2.0;
    }
    
    return globalHeight(f, op);
}

float heightFunctionHi(vec2 p)
{
    vec2 op = p;
    p += 0.02;
    p *= 0.0025;
    float f = 0.0;
    float amplitude = 1.0;
    float period = 1.0;
        
    for (int i = 0; i < 11; i++)
    {
        f += amplitude * texture(iChannel0, period * p).x;
        rot(p, 1.0);
        amplitude *= 0.5;
        period *= 2.0;
    }
    
    return globalHeight(f, op);
}

vec3 getNormal(in vec2 p, in float d)
{
  vec2 eps = vec2(0.004*d, 0);
  float dx = heightFunction(p - eps) - heightFunction(p + eps);
  float dy = 2.0f*eps.x;
  float dz = heightFunction(p - eps.yx) - heightFunction(p + eps.yx);
  return normalize(vec3(dx, dy, dz));
}

vec3 getNormalLo(in vec2 p, in float d)
{
  vec2 eps = vec2(0.004*d, 0);
  float dx = heightFunctionLo(p - eps) - heightFunctionLo(p + eps);
  float dy = 2.0f*eps.x;
  float dz = heightFunctionLo(p - eps.yx) - heightFunctionLo(p + eps.yx);
  return normalize(vec3(dx, dy, dz));
}

vec3 getNormalHi(in vec2 p, in float d)
{
  vec2 eps = vec2(0.004*d, 0);
  float dx = heightFunctionHi(p - eps) - heightFunctionHi(p + eps);
  float dy = 2.0f*eps.x;
  float dz = heightFunctionHi(p - eps.yx) - heightFunctionHi(p + eps.yx);
  return normalize(vec3(dx, dy, dz));
}

float march(in vec3 ro, in vec3 rd, out int max_iter)
{
  float dt = 0.1;
  float d = MIN_DISTANCE;

  for (int i = 0; i < MAX_ITER; ++i)
  {
    vec3 p = ro + d*rd;
    float h = heightFunction(p.xz);
    
    if (d > MAX_DISTANCE) 
    {
      max_iter = i;
      return MAX_DISTANCE;
    }

    float hd = p.y - h;

    if (hd < TOLERANCE)
    {
      return d;
    }

    dt = max(hd, TOLERANCE) + 0.001*d;
    d += dt;
  }
  
  max_iter = MAX_ITER;
  return MAX_DISTANCE;
}

vec3 sunDirection()
{
  const vec3 sunDirection = normalize(vec3(-1.0, 0.2, -1.0));
  vec3 sunDir = sunDirection;
  rot(sunDir.xz, 2.0);
  return sunDir;
}

vec3 skyColor(vec3 rd) {
  vec3 sunDir = sunDirection();
  float sunDot = max(dot(rd, sunDir), 0.0);
  vec3 final = vec3(0.0);
  float angle = atan(rd.y, length(rd.xz))*2.0/PI;

  final += mix(mix(skyCol1, skyCol2, max(0.0, angle)), skyCol3, clamp(-angle*2.0, 0.0, 1.0));
  final += 0.5*sunCol1*pow(sunDot, 30.0);
  final += 1.0*sunCol2*pow(sunDot, 600.0);
    
  return final;
}

float shadow(in vec3 ro, in vec3 rd, in float ll, in float mint)
{
  float t = mint;
  
  for (int i=0; i<24; ++i)
  {
    vec3 p = ro + t*rd;
    float h = heightFunction(p.xz);
    float d = (p.y - h);
    if (d < TOLERANCE) return 0.0;
    if (t > ll) return 1.0;
    t += max(0.1, 0.25*h);
  }
  
  return 1.0;
}

vec3 getColor(vec3 ro, vec3 rd)
{
    int max_iter;
    float d = march(ro, rd, max_iter);
    vec3 sandColor =  1.3 * vec3(0.68, 0.4, 0.3);
    vec3 surfaceColor = vec3(0.0);
    vec3 skyCol = skyColor(rd);
    
    if (d < MAX_DISTANCE)
    {
        vec3 p = ro + d * rd;
        
        // diffuse lighting
        vec3 sunDir = sunDirection();
        float seaHeight = 0.0;
        float dsea = (seaHeight - ro.y)/rd.y; 
        //vec3 amb = ambient(sunf, sunDir, rd); 
        if (d > dsea && dsea > 0.0)
        {
            vec3 normal = vec3(0.0, 1.0, 0.0);
            vec3 psea = ro + dsea * rd;
            
            // specular lighting
            vec3 refRay = reflect(rd,normal);
            vec3 refSkyColor = skyColor(refRay);
            float shad = shadow(psea, sunDir, 4.0, 0.5);
            
            return refSkyColor * shad * 0.125 + vec3(0.1, 0.2, 0.4);
        }
        else
        {
            // Mountain strata
            float bandings = mix(50.0, 100.0, 0.5 + 0.5*sin(length(p.y)*10.0));
            float bandingo = sin(length(p.xz) * 3.0);
            float bandingf = pow(0.5 + 0.5 * sin(p.y*bandings + bandingo), 0.25);
            float banding = mix(0.6, 1.0, bandingf);
        
            float heightLo = heightFunctionLo(p.xz + vec2(0.2));
            float heightHi = heightFunctionHi(p.xz);
            float heightRatio = heightHi / heightLo;
            
            vec3 normalLo = getNormalLo(p.xz, d);
            vec3 normal = getNormal(p.xz, d);
            vec3 normalHi = getNormalHi(p.xz, d);
            surfaceColor = sandColor * banding;
            float refFactor = 0.0;
                        
            float flatness = max(dot(normal, vec3(0.0, 1.0, 0.0)), 0.0);
            float flatnessFactor = pow(flatness, 7.0);
            
            // Fog
            float fogHeight = 0.2 + 0.2 * flatnessFactor;
            float dfog = (fogHeight - ro.y)/rd.y;
            float fogDepth = d > dfog && dfog > 0.0 ? d - dfog : 0.0;
            float fogFactor = exp(-fogDepth);
            
            vec4 treePattern = voronoi(p.xz * 50.0);
            vec4 patchPattern = voronoi(p.xz * 10.0);
        
            // Snow
            if (p.y > 0.7 + 0.1 * sin(p.x + p.z) - 0.3 * flatnessFactor)
            {
                surfaceColor = vec3(1.0);
                refFactor = 0.5;
                normal = normalLo;
            }
            else if (p.y < 0.3 + 0.1 * flatnessFactor)
            {
                // Trees
                surfaceColor = mix(vec3(0.2, 0.5, 0.0), vec3(0.5, 0.5, 0.0), patchPattern.y) * 1.3;
                surfaceColor *= 1.0 - treePattern.x * 0.75;
                vec3 normalOffset = vec3(treePattern.z, 0.0, treePattern.w);
                normal = normalize(normalLo - normalOffset);
            }
            else
            {
                normal = normalHi;
            }
        
            // specular lighting
            vec3 refRay = reflect(rd,normal);
            vec3 refSkyColor = skyColor(refRay);
        
            // shadows
            float shad = shadow(p, sunDir, 4.0, 0.25); // Look into this
            float dl = max(0.0, dot(normal, sunDir));
            float grad = mix(0.2, 1.0, shad * dl);   
            vec3 col = vec3(grad * surfaceColor +  shad * refFactor * refSkyColor) * pow(heightRatio, 3.0);
            
            col = mix(skyCol, col, fogFactor);
            
            col = mix(col, skyCol, d/MAX_DISTANCE);
        
            return col;
        }
    }
    else
    {
        return skyCol;
    }
}

vec3 eyePos(float t)
{
    return vec3(sin(t * 0.1), 1.4-0.0, -2.0 + t * 1.0);
}

vec3 getSample(in vec2 p, in float time)
{
  float off = 1.0*time;
  vec3 ro  = eyePos(time);
  vec3 la  = eyePos(time + 0.1) + vec3(0.0, -0.02,  0.0);
  vec3 ww = normalize(la - ro);
  vec3 uu = normalize(cross(vec3(0.0,1.0,0.0), ww));
  vec3 vv = normalize(cross(ww, uu));
  vec3 rd = normalize(p.x*uu + p.y*vv + 2.0*ww);
  vec3 col = getColor(ro, rd);
 
  return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
  vec2 p = fragCoord/iResolution.xy - vec2(0.5);
  p.x *= iResolution.x/iResolution.y;
    
  vec3 col = getSample(p, iTime);
  fragColor = vec4(col, 1.0);
}