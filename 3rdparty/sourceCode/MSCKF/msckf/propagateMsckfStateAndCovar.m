function msckfState_prop = propagateMsckfStateAndCovar(msckfState, measurements_k, noiseParams)
%�������ܣ�msckfԤ����£�����״̬��������Э�������
%����ֵ��
%      msckfState_prop�����º��״̬��
%����ֵ��
%      msckfState������ǰ��״̬��
%      measurements_k������ֵ��IMU���ٶ���IMU�ٶȣ�
%      noiseParams������

    % Jacobians
    Q_imu = noiseParams.Q_imu;
    %����1�����״̬ת�ƾ��󣨶�״̬���󵼣�
    F = calcF(msckfState.imuState, measurements_k);
    %����2�����״���������¾��󣨶��������ֵ��󵼣�
    G = calcG(msckfState.imuState);

    %Propagate State
    %����3������IMU����ֵ����IMU��״̬����Ԫ�� ��������ƫ���ٶ���ƫ λ�ã�
    msckfState_prop.imuState = propagateImuState(msckfState.imuState, measurements_k);

    % State Transition Matrix
    %ע�⣡ ״̬ת��Э����ĸ��¾�����ʱ���й�
    Phi = eye(size(F,1)) + F * measurements_k.dT; % Leutenegger 2013
    
    % IMU-IMU Covariance
%     msckfState_prop.imuCovar = msckfState.imuCovar + ...
%                                 ( F * msckfState.imuCovar ...
%                                 + msckfState.imuCovar * F' ...
%                                 + G * Q_imu * G' ) ...
%                                         * measurements_k.dT;

    %����4������Э���������IMU-IMU�鲿��
    %imuCover := P * imuCover * P' + G * Q_imu * G'
    %notation! ����Э����ĸ��¾�����ʱ���й�
    msckfState_prop.imuCovar = Phi * msckfState.imuCovar * Phi' ...
                                + G * Q_imu * G' * measurements_k.dT; % Leutenegger 2013
    
    % Enforce PSD-ness
    %����5��ǿ��Э�����Ϊ�Գƾ������Խ���Ԫ��ȡ����ֵ���ǶԽ���Ԫ�ضԳ�Ԫ��ȡƽ��ֵ
    msckfState_prop.imuCovar = enforcePSD(msckfState_prop.imuCovar);
                                    
    % Camera-Camera Covariance
    %����6������Э���������Camera-Camera�鲿�֣�����
    msckfState_prop.camCovar = msckfState.camCovar;
    
    % IMU-Camera Covariance
    %����7������Э���������IMU-Camera�鲿��
    %imuCamCovar := P * imuCamCovar
    msckfState_prop.imuCamCovar = Phi * msckfState.imuCamCovar;
    msckfState_prop.camStates = msckfState.camStates;
end