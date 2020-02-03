/*
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

var canvas;
var gl;

var verticesBuffer;
var verticesTextureCoordBuffer;
var verticesNormalBuffer;
var verticesIndexBuffer;
var image;
var texture0;

var width;
var height;

var shaderProgram;
var vertexPositionAttribute;
var vertexNormalAttribute;
var textureCoordAttribute;

const maxWidth = 1920;
const msPerFrame = 1000.0/60.0;

function now() {
  return (new Date).getTime();
}

let startTime = now();

function start() {
  const innerWidth    = window.innerWidth;
  const innerHeight   = window.innerHeight;
  const actualWidth   = Math.round(Math.min(maxWidth, innerWidth));
  const actualHeight  = Math.round(innerHeight*actualWidth/innerWidth);

  canvas = document.getElementById("glcanvas");
  width  = actualWidth;
  height = actualHeight;

  canvas.width  = actualWidth;
  canvas.height = actualHeight;

  initWebGL(canvas);      // Initialize the GL context

  // Only continue if WebGL is available and working

  if (gl) {
    gl.clearColor(0.0, 0.0, 0.0, 1.0);  // Clear to black, fully opaque
    gl.clearDepth(1.0);                 // Clear everything
    gl.enable(gl.DEPTH_TEST);           // Enable depth testing
    gl.depthFunc(gl.LEQUAL);            // Near things obscure far things

    // Initialize the shaders; this is where all the lighting for the
    // vertices and so forth is established.

    initShaders();

    // Here's where we call the routine that builds all the objects
    // we'll be drawing.

    initBuffers();

    // Next, load and set up the textures we'll be using.

    texture0 = createTexture("image0");

    startTime = now();

    // Set up to draw the scene periodically.

    setTimeout(drawScene, msPerFrame);
  }
}

function initWebGL() {
  gl = null;

  try {
    gl = canvas.getContext("experimental-webgl");
  }
  catch(e) {
  }

  // If we don't have a GL context, give up now

  if (!gl) {
    alert("Unable to initialize WebGL. Your browser may not support it.");
  }
}

//
// initBuffers
//
function initBuffers() {

  verticesBuffer = gl.createBuffer();

  gl.bindBuffer(gl.ARRAY_BUFFER, verticesBuffer);

  const vertices = [
    // Front face
    -1.0, -1.0,  1.0,
     1.0, -1.0,  1.0,
     1.0,  1.0,  1.0,
    -1.0,  1.0,  1.0,
  ];

  // Now pass the list of vertices into WebGL to build the shape. We
  // do this by creating a Float32Array from the JavaScript array,
  // then use it to fill the current vertex buffer.

  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);

  // Set up the normals for the vertices, so that we can compute lighting.

  verticesNormalBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, verticesNormalBuffer);

  const vertexNormals = [
    // Front
     0.0,  0.0,  1.0,
     0.0,  0.0,  1.0,
     0.0,  0.0,  1.0,
     0.0,  0.0,  1.0,
  ];

  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertexNormals),
                gl.STATIC_DRAW);

  verticesTextureCoordBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, verticesTextureCoordBuffer);

  const textureCoordinates = [
    // Front
    0.0,  0.0,
    1.0,  0.0,
    1.0,  1.0,
    0.0,  1.0,
  ];

  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(textureCoordinates),
                gl.STATIC_DRAW);

  // Build the element array buffer; this specifies the indices
  // into the vertex array for each face's vertices.

  verticesIndexBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, verticesIndexBuffer);

  // This array defines each face as two triangles, using the
  // indices into the vertex array to specify each triangle's
  // position.

  const vertexIndices = [
    0,  1,  2,      0,  2,  3    // front
  ]

  // Now send the element array to GL

  gl.bufferData(gl.ELEMENT_ARRAY_BUFFER,
      new Uint16Array(vertexIndices), gl.STATIC_DRAW);
}

function createTexture(id) {
  const image = document.getElementById(id);

  // create new texture
  const texture = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, texture);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);

  handleTextureLoaded(image, texture)

  return texture;
}

function handleTextureLoaded(image, texture) {
  gl.bindTexture(gl.TEXTURE_2D, texture);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  //gl.generateMipmap(gl.TEXTURE_2D);
  gl.bindTexture(gl.TEXTURE_2D, null);
}

function bindTexture(uniform, texture, i) {
  gl.activeTexture(gl.TEXTURE0 + i);
  gl.bindTexture(gl.TEXTURE_2D, texture);
  gl.uniform1i(gl.getUniformLocation(shaderProgram, uniform), i);
}

function drawScene() {
  const before = now();
  const iTime = (before - startTime) / 1000.0;

  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

  gl.bindBuffer(gl.ARRAY_BUFFER, verticesBuffer);
  gl.vertexAttribPointer(vertexPositionAttribute, 3, gl.FLOAT, false, 0, 0);

  gl.bindBuffer(gl.ARRAY_BUFFER, verticesTextureCoordBuffer);
  gl.vertexAttribPointer(textureCoordAttribute, 2, gl.FLOAT, false, 0, 0);

  gl.bindBuffer(gl.ARRAY_BUFFER, verticesNormalBuffer);
  gl.vertexAttribPointer(vertexNormalAttribute, 3, gl.FLOAT, false, 0, 0);

  bindTexture("iChannel0", texture0, 0);

  gl.uniform2f(gl.getUniformLocation(shaderProgram, "iResolution"), width, height);
  gl.uniform1f(gl.getUniformLocation(shaderProgram, "iTime"), iTime);

  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, verticesIndexBuffer);
  gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_SHORT, 0);

  const after = now();

  const diff = after - before;
  const wait = diff > msPerFrame - 1.0 ? 1.0 : msPerFrame - diff;

  setTimeout(drawScene, wait);
}

function initShaders() {
  const fragmentShader  = getShader(gl, "shader-fs");
  const vertexShader    = getShader(gl, "shader-vs");

  shaderProgram = gl.createProgram();
  gl.attachShader(shaderProgram, vertexShader);
  gl.attachShader(shaderProgram, fragmentShader);
  gl.linkProgram(shaderProgram);

  if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
    alert("Unable to initialize the shader program.");
  }

  gl.useProgram(shaderProgram);

  vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition");
  gl.enableVertexAttribArray(vertexPositionAttribute);

  textureCoordAttribute = gl.getAttribLocation(shaderProgram, "aTextureCoord");
  gl.enableVertexAttribArray(textureCoordAttribute);

  vertexNormalAttribute = gl.getAttribLocation(shaderProgram, "aVertexNormal");
  gl.enableVertexAttribArray(vertexNormalAttribute);
}

function getShader(gl, id) {
  const shaderScript = document.getElementById(id);

  if (!shaderScript) {
    return null;
  }

  var theSource    = "";
  var currentChild = shaderScript.firstChild;

  while(currentChild) {
    if (currentChild.nodeType == 3) {
      theSource += currentChild.textContent;
    }

    currentChild = currentChild.nextSibling;
  }

  var shader;

  if (shaderScript.type == "x-shader/x-fragment") {
    shader = gl.createShader(gl.FRAGMENT_SHADER);
  } else if (shaderScript.type == "x-shader/x-vertex") {
    shader = gl.createShader(gl.VERTEX_SHADER);
  } else {
    return null;  // Unknown shader type
  }

  gl.shaderSource(shader, theSource);

  gl.compileShader(shader);

  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    alert("An error occurred compiling the shaders: " + gl.getShaderInfoLog(shader));
    return null;
  }

  return shader;
}
