function msckfState_aug = augmentState(msckfState, camera, state_k)
%�������ܣ�msckf״̬�������������״̬�������ſ˱ȣ�����Э������󣬲�����Э�������
%
%����ֵ��
%      msckfState_aug��������״̬��
%����ֵ��
%      msckfState������ǰ��״̬��
%      camera�������������IMU֮���λ�˹�ϵ
%      state_k����֡ID��

% Augments the MSCKF state with a new camera pose    

    %��imu״̬�е���Ԫ��ת��Ϊ��ת����globle��imu
    C_IG = quatToRotMat(msckfState.imuState.q_IG);
    
    % Compute camera pose from current IMU pose
    %����1����IMU�Լ�IMU��camera�Ĺ�����ϵ�õ������λ�ú���̬
    %�õ�global������ı任��Ԫ��
    q_CG = quatLeftComp(camera.q_CI) * msckfState.imuState.q_IG;
    %�õ��������������ϵ�µ�λ��
    p_C_G = msckfState.imuState.p_I_G + C_IG' * camera.p_C_I;

    % Build MSCKF covariance matrix
    %����2����������ǰ��Э�������
    % |imuЭ����      imu�����Э����|
    % |�����imuЭ����     ���Э����|
    P = [msckfState.imuCovar, msckfState.imuCamCovar;
        msckfState.imuCamCovar', msckfState.camCovar];
    
    % Camera state Jacobian
    %����3������״̬�Ժ���Ҫ�õ�����״̬�����λ�á������Ԫ������msckf״̬������ǰ�Ժ��״̬�����ſ˱�
    %camera�а�����camera��IMU֮��ı任��ϵ
    %msckfState.imuStateΪ״̬�е�IMU��ز���
    %msckfState.camStatesΪ״̬�е��������
    J = calcJ(camera, msckfState.imuState, msckfState.camStates);
    
    %����״̬�к�camera�йص�״̬������
    N = size(msckfState.camStates,2);
    
    %����4������������Э�������
    %����4.1����������״̬������״̬���ſ˱Ⱦ���
    tempMat = [eye(12+6*N); J];
    
    % Augment the MSCKF covariance matrix
    %����4.2��������������״̬������״̬��Э�������
    P_aug = tempMat * P * tempMat';
    
    % Break everything into appropriate structs
    %�õ�������״̬������
    %[֮ǰ��״̬��camState{N+1}]
    %camState[P_C_G,q_CG,state_k,trackedFeatureIds]
    msckfState_aug = msckfState;
    msckfState_aug.camStates{N+1}.p_C_G = p_C_G;
    msckfState_aug.camStates{N+1}.q_CG = q_CG;
    msckfState_aug.camStates{N+1}.state_k = state_k;
    msckfState_aug.camStates{N+1}.trackedFeatureIds = [];
    msckfState_aug.imuCovar = P_aug(1:12,1:12);
    msckfState_aug.camCovar = P_aug(13:end,13:end);
    msckfState_aug.imuCamCovar = P_aug(1:12, 13:end);
end