#include <iostream>
#include "Eigen/Dense"
#include "osqp.h"
#include "qpOASES.hpp"


int main(int argc, char* argv[])
{
    // eigen test
    Eigen::Vector3d a(2,3,5);
    Eigen::Vector3d b(3,3,3);
    std::cout << "eigen: [" << a.cwiseProduct(b) << "]" << std::endl;

    // osqp test

    return 0;
}
