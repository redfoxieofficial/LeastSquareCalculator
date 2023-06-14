#include <iostream>

extern "C" double LsEpsilon;
extern "C" bool CalcLeastSquaresASM(const double* x, const double* y, int n, double* m, double* b);
bool CalcLeastSquaresCPP(const double* x, const double* y, int n, double* m, double* b);

int main()
{
	const int n = 6;
	double x[] = { 0,2,4,6,8,10 };
	double y[] = { 51.23,34.6,12.3,56.8,90.1, 103.4};

	double m1 = 0;
	double b1 = 0;
	CalcLeastSquaresASM(x, y, n, &m1, &b1);
	printf("%f", m1);

}

