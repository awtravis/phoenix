#define _USE_MATH_DEFINES
#include <cmath>
extern "C" double f_fc82225ec35409cc3de70f4bcbad95c20b779e29(const double *params, const double *immed, const double eps) {
double r, s[6];
s[0] = params[0];
s[1] = immed[0];
s[0] = s[1] - s[0];
s[1] = immed[1];
s[2] = params[0];
s[2] *= s[2];
s[3] = immed[2];
s[2] *= s[3];
s[1] += s[2];
s[2] = s[0];
s[3] = params[0];
s[2] *= s[3];
s[3] = immed[3];
s[2] *= s[3];
s[1] += s[2];
s[2] = params[0];
s[3] = s[2];
s[2] += s[3];
s[3] = immed[4];
s[2] = s[3] - s[2];
s[3] = immed[5];
s[4] = params[0];
s[3] *= s[4];
s[4] = immed[6];
s[5] = s[0];
s[4] *= s[5];
s[3] += s[4];
s[2] *= s[3];
s[1] += s[2];
return s[1]; }
