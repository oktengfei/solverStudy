function [errorVec] = imuError(kState, kMinus1State, imuMeasurement, deltaT)
%�������ܣ� ����kStateʱ��ͨ��IMUԤ��״̬���Ż�״̬��֮������
% error_imu = ||IMU_propagation - state||
%
%����ֵ��
%      errorVec���������[ƽ������ת���]
%����ֵ��
%      kState�� ��ǰ֡״̬
%      kMinus1State�� ��һ֡״̬
%      imuMeasurement�� IMU����ֵ
%      deltaT����֡��ʱ����
%IMUERROR Compute the 6x1 error vector associated with interoceptive measurement

%��IMU���ٶȲ����ĵ�����֡����̬��΢С�������� psiVec = w * dt
psiVec = imuMeasurement.omega*deltaT;
%��һ����̬��΢С�������� psiVec/norm(psiVec)
psiMag = norm(psiVec);
%��IMU�ٶȲ���ֵ�õ�����֡��λ������ distance = v * dt
d = imuMeasurement.v*deltaT;

%Compute rotational error (See Lecture8-10)
%����̬��΢С������������õ���ת����
Phi = cos(psiMag)*eye(3) + (1 - cos(psiMag))*(psiVec/psiMag)*(psiVec/psiMag)' - sin(psiMag)*crossMat(psiVec/psiMag);
%����1���õ�kStateʱ��Ԥ��ֵ��״̬��֮��Ĳв�
%R_kState_hat = Phi*kMinus1State.C_vi�õ�kStateʱ�̵���̬Ԥ��ֵ
%R_kState * R_kState_hat'�õ�kStateʱ��Ԥ��ֵ��״̬��֮��ĽǶȲв�
%���磺R2 = deltaR * R1����deltaR = R2 * R1'
%                                  |    1      -theta_z     theta_y |
%                                = | theta_z      1        -theta_x |
%                                  |-theta_y    theta_x        1    |
eRotMat = kState.C_vi*(Phi*kMinus1State.C_vi)';
eRot = [eRotMat(2,3); eRotMat(3,1); eRotMat(1,2)];

%Compute translational error
%����2���õ�kStateʱ��Ԥ��ֵ��״̬��֮���λ�Ʋв�
eTrans = kState.r_vi_i - (kMinus1State.r_vi_i + kMinus1State.C_vi'*d);

errorVec = [eTrans; eRot];
end

