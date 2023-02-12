function imuState_prop = propagateImuState(imuState_k, measurements_k)
%�������ܣ�����IMU����ֵ����IMU��״̬����Ԫ�� ��������ƫ���ٶ���ƫ λ�ã�
%
%����ֵ��
%      imuState_prop��IMU���ֵ�״̬�����º�Ľ��
%����ֵ��
%      imuState_k����һ�ε�IMU״̬
%      measurements_k������IMU����ֵ

% prop == propagated to k+1

    C_IG = quatToRotMat(imuState_k.q_IG);
    
    % Rotation state
    %IMU�������ǲ���ֵ��ȥ����ƫ�����ֵõ���������psi = (w-bias)*dt
    psi = (measurements_k.omega - imuState_k.b_g) * measurements_k.dT;
    %�������ǲ����Ľ��ٶȸ�����Ԫ��
    %��|q1|    |q1|      �� 0    wz  -wy  wx ||q1|  
    %��|q2| := |q2| + 1/2��-wz   0    wx  wy ||q2|dt
    %��|q3|    |q3|      �� wy  -wx   0   wz ||q3|
    %��|q0|    |q0|      ��-wx  -wy  -wz   0 ||q0|
    imuState_prop.q_IG = imuState_k.q_IG + 0.5 * omegaMat(psi) * imuState_k.q_IG;
%     diffRot = axisAngleToRotMat(psi);
%     C_IG_prop = diffRot * C_IG;
%     imuState_prop.q_IG = rotMatToQuat(C_IG_prop);
    
    %Unit length quaternion
    %��һ����Ԫ��
    imuState_prop.q_IG = imuState_prop.q_IG/norm(imuState_prop.q_IG);
    
    % Bias states
    %��������ƫ���ٶ���ƫ�ĸ��¾���Ϊ��λ����
    imuState_prop.b_g = imuState_k.b_g;
    imuState_prop.b_v = imuState_k.b_v;
    
    % Translation state
    %IMU�в������ٶ�ͨ�����ָ���λ�ã�λ��Ϊglobal����ϵ��
    d = (measurements_k.v - imuState_k.b_v) * measurements_k.dT;
    imuState_prop.p_I_G = C_IG' * d + imuState_k.p_I_G;
    
end