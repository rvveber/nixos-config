#include <EGL/egl.h>
#include <GLES3/gl3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SIZE 128
#define PIXEL(x, y) (((y) * SIZE + (x)) * 4)

static void require(int condition, const char *message) {
    if (!condition) {
        fprintf(stderr, "%s\n", message);
        exit(1);
    }
}

static GLuint shader(GLenum type, const char **parts, int count) {
    GLuint id = glCreateShader(type);
    glShaderSource(id, count, parts, NULL);
    glCompileShader(id);
    GLint compiled;
    glGetShaderiv(id, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        char log[4096];
        glGetShaderInfoLog(id, sizeof(log), NULL, log);
        fprintf(stderr, "%s\n", log);
    }
    require(compiled, "Shader compilation failed");
    return id;
}

int main(int argc, char **argv) {
    require(argc == 2, "Expected shader path");
    FILE *file = fopen(argv[1], "rb");
    require(file != NULL, "Shader source unavailable");
    require(fseek(file, 0, SEEK_END) == 0, "Cannot seek shader");
    long length = ftell(file);
    require(length > 0, "Shader source is empty");
    rewind(file);
    char *body = calloc((size_t)length + 1, 1);
    require(body != NULL, "Allocation failed");
    require(fread(body, 1, (size_t)length, file) == (size_t)length, "Cannot read shader");
    fclose(file);

    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    require(eglInitialize(display, NULL, NULL), "EGL initialization failed");
    const EGLint attributes[] = {EGL_SURFACE_TYPE, EGL_PBUFFER_BIT, EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
        EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8, EGL_NONE};
    EGLConfig config;
    EGLint count;
    require(eglChooseConfig(display, attributes, &config, 1, &count) && count, "EGL configuration unavailable");
    const EGLint surfaceAttributes[] = {EGL_WIDTH, SIZE, EGL_HEIGHT, SIZE, EGL_NONE};
    EGLSurface surface = eglCreatePbufferSurface(display, config, surfaceAttributes);
    const EGLint contextAttributes[] = {EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE};
    EGLContext context = eglCreateContext(display, config, EGL_NO_CONTEXT, contextAttributes);
    require(eglMakeCurrent(display, surface, surface, context), "EGL context unavailable");

    const char *vertex = "#version 300 es\nlayout(location=0) in vec2 position; out vec2 uv;"
        "void main(){uv=position*0.5+0.5;gl_Position=vec4(position,0,1);}";
    const char *prefix = "#version 300 es\nprecision highp float;\nin vec2 uv;out vec4 result;"
        "uniform sampler2D tex;uniform float x_FadeIn;uniform vec2 x_CursorPos;uniform float x_Time;"
        "uniform vec2 x_WindowSize;uniform float x_MonitorScale;\n"
        "#define x_Tex tex\n#define x_TexCoord uv\n"
        "#define x_PixelPos (uv*x_WindowSize)\n";
    const char *sampling = "\nvec4 x_Texture(vec2 coord){\n"
        "#ifdef FHUD_PREFLIGHT\nreturn vec4(1.0);\n"
        "#elif USE_RGBA\nreturn texture(tex,coord);\n"
        "#else\nreturn vec4(texture(tex,coord).rgb,1.0);\n#endif\n"
        "}\nvec4 x_TextureOffset(vec2 offset){return x_Texture(uv-offset/x_WindowSize);}\n";
    const char *suffix = "\nvoid main(){\n"
        "#ifdef FHUD_PREFLIGHT\nresult=vec4(1.0);\n"
        "#elif USE_RGBA\nresult=texture(tex,uv);\n"
        "#else\nresult=vec4(texture(tex,uv).rgb,1.0);\n#endif\n"
        "windowShader(result);}";
    GLuint vertexShader = shader(GL_VERTEX_SHADER, &vertex, 1);
    GLuint vao, buffer, texture;
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    const GLfloat positions[] = {-1,-1, 1,-1, -1,1, 1,1};
    glBufferData(GL_ARRAY_BUFFER, sizeof(positions), positions, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(0);

    unsigned char input[SIZE * SIZE * 4], output[sizeof(input)];
    for (int y = 0; y < SIZE; y++) {
        for (int x = 0; x < SIZE; x++) {
            unsigned char *pixel = input + PIXEL(x, y);
            pixel[0] = 48; pixel[1] = 50; pixel[2] = 52; pixel[3] = 255;
            if ((x == 32 && y > 16 && y < 112) || (y == 64 && x > 16 && x < 112))
                pixel[0] = pixel[1] = pixel[2] = 255;
            if (x > 80 && x < 110 && y > 16 && y < 40) {
                pixel[0] = 230; pixel[1] = 20; pixel[2] = 30;
            }
            if (x > 80 && y > 90) {
                pixel[0] = 4; pixel[1] = 8; pixel[2] = 12; pixel[3] = 128;
            }
            if (x == 56 && y > 16 && y < 112)
                pixel[0] = pixel[1] = pixel[2] = 66;
            if (x == 72 && y > 72 && y < 82)
                pixel[0] = pixel[1] = pixel[2] = 230;
            if (x < 8 && y > 112)
                pixel[0] = pixel[1] = pixel[2] = pixel[3] = 0;
        }
    }
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, SIZE, SIZE, 0, GL_RGBA, GL_UNSIGNED_BYTE, input);
    glViewport(0, 0, SIZE, SIZE);

    for (int variant = 0; variant < 3; variant++) {
        const char *defines[] = {"#define FHUD_PREFLIGHT\n", "#define USE_RGBA 1\n", "#define USE_RGBA 0\n"};
        const char *parts[] = {prefix, defines[variant], sampling, body, suffix};
        GLuint fragment = shader(GL_FRAGMENT_SHADER, parts, 5);
        GLuint program = glCreateProgram();
        glAttachShader(program, vertexShader);
        glAttachShader(program, fragment);
        glLinkProgram(program);
        GLint linked;
        glGetProgramiv(program, GL_LINK_STATUS, &linked);
        require(linked, "Shader link failed");
        glUseProgram(program);
        glUniform2f(glGetUniformLocation(program, "x_WindowSize"), SIZE, SIZE);
        glUniform1f(glGetUniformLocation(program, "x_MonitorScale"), 1);
        require(glGetUniformLocation(program, "x_CursorPos") == -1, "Shader must release pointer-driven redraws");
        require(glGetUniformLocation(program, "x_Time") == -1, "Shader must settle without continuous redraws");
        require(glGetUniformLocation(program, "fhudAccent") == -1 &&
                glGetUniformLocation(program, "fhudStrength") == -1 &&
                glGetUniformLocation(program, "fhudDepth") == -1, "Theme values must compile without custom uniforms");
        if (variant == 0) {
            glDeleteProgram(program);
            glDeleteShader(fragment);
            continue;
        }
        for (int entry = 0; entry < 2; entry++) {
            glUniform1f(glGetUniformLocation(program, "x_FadeIn"), entry ? 0.4f : 1);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            glReadPixels(0, 0, SIZE, SIZE, GL_RGBA, GL_UNSIGNED_BYTE, output);
            require(glGetError() == GL_NO_ERROR, "Rendering failed");
            require(output[PIXEL(5,5) + 3] < 230 && output[PIXEL(5,5) + 3] > 190, "Neutral dark panels must become visibly translucent");
            require(output[PIXEL(5,5) + 1] > output[PIXEL(5,5)] + 12, "Neutral dark panels must acquire a visible selective tint");
            require(memcmp(input + PIXEL(95,25), output + PIXEL(95,25), 4) == 0, "Saturated surfaces must retain their color");
            require(memcmp(input + PIXEL(72,77), output + PIXEL(72,77), 4) == 0, "Short text strokes must remain sharp and opaque");
            require(memcmp(output + PIXEL(76,77), output + PIXEL(5,5), 4) == 0, "Short text strokes must not create displaced halos");
            if (variant == 1) {
                require(output[PIXEL(95,100) + 3] <= 128, "Existing transparency must be preserved");
                require(output[PIXEL(4,120) + 3] == 0, "Transparent pixels must stay transparent");
            }
            for (int i = 0; i < (int)sizeof(output); i += 4)
                require(output[i] <= output[i+3] && output[i+1] <= output[i+3] && output[i+2] <= output[i+3], "Output must remain premultiplied");
            if (entry)
                require(output[PIXEL(32,88)] < 245 && output[PIXEL(32,88)] > 150, "Entry blink must be bounded and visible");
            if (!entry) {
                require(memcmp(input, output, sizeof(input)) != 0, "Depth layer must affect detected edges");
                require(output[PIXEL(35,80) + 1] > output[PIXEL(5,5) + 1] + 15, "Depth layer must be spatially offset from its source edge");
                require(output[PIXEL(59,80) + 1] > output[PIXEL(5,5) + 1] + 15, "Low contrast dividers must produce a displaced depth layer");
                require(memcmp(input + PIXEL(32,88), output + PIXEL(32,88), 4) == 0, "Settled source lines must remain crisp");
            }
        }
        glDeleteProgram(program);
        glDeleteShader(fragment);
    }
    free(body);
    eglTerminate(display);
    puts("Shader render checks passed");
    return 0;
}
