SET(CURRENT_PATH ${CMAKE_CURRENT_SOURCE_DIR})


# 1. 创建库
ADD_LIBRARY(3rdparty_lib INTERFACE)

# 2. 指定库依赖头文件路径
TARGET_INCLUDE_DIRECTORIES(3rdparty_lib INTERFACE
#   osqp
    ${CURRENT_PATH}/osqp/include/osqp/
#   qdldl, qdldl 为 osqp的一个默认linear solver, 这里单独提出来用于探究其原理
    ${CURRENT_PATH}/qdldl/include/
#   qpOASES
    ${CURRENT_PATH}/qpOASES/include/
#   eigen
    ${CURRENT_PATH}/eigen/include/eigen3/
)

# 3. 指定库依赖库
TARGET_LINK_LIBRARIES(3rdparty_lib INTERFACE
#   osqp
    ${CURRENT_PATH}/osqp/lib/libosqp.a
#   qdldl, qdldl 为 osqp的一个默认linear solver, 这里单独提出来用于探究其原理, 当没有这个时，需要引用 ${CURRENT_PATH}/osqp/lib/libqdldl.a 使osqp正常工作。
    ${CURRENT_PATH}/qdldl/lib/libqdldl.a
#   qpOASES
    ${CURRENT_PATH}/qpOASES/lib/libqpOASES.a

    dl
)

# 4. 指定编译宏，该宏用于防止eigen库异常。
TARGET_COMPILE_DEFINITIONS(3rdparty_lib INTERFACE EIGEN_DONT_ALIGN_STATICALLY)
