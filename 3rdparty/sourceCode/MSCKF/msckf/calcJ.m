function J = calcJ(camera, imuState_k, camStates_k)
%�������ܣ��õ�Ҫ�����״̬�����λ�á������Ԫ������֮ǰ����״̬���ſ˱�

% �ο����ף���The Battle for Filter Supremacy: A Comparative Study of the
%    Multi-State Constraint Kalman Filter and the Sliding Window Filter��

% Jacobian of feature observations w.r.t. feature locations

    C_CI = quatToRotMat(camera.q_CI);
    C_IG = quatToRotMat(imuState_k.q_IG);
    
    %�ο����� ��ʽ10
    %��������λ������Ԫ������������״̬��ƫ�����ſ˱ȣ�
    % (camera_p_k+1 camera_q_k+1) = J * (imu_q_k, imu_b_w_k, imu_b_v_k, imu_p_k, camera_p_k, camera_q_k)
    J = zeros(6, 12 + 6*size(camStates_k,2));
    J(1:3,1:3) = C_CI;
    J(4:6,1:3) = crossMat(C_IG' * camera.p_C_I);
    J(4:6,10:12) = eye(3);

end