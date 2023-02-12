function [msckfState, featureTracks, trackedFeatureIds] = initializeMSCKF(firstImuState, firstMeasurements, camera, state_k, noiseParams)
%�������ܣ���ʼ��״̬����ʼ�����ٵ��������㣬��һ֡���е���������Ϊ����������
%
%����ֵ��
%      msckfState�������ĵ�״̬��IMU���״̬����һ�����λ��
%      featureTracks����¼���ٵ��������㣬��ʼ��ʱ�����е���������Ϊ�������ٵ���
%      trackedFeatureIds����¼���ٵ����������ID��
%����ֵ��
%      firstImuState��IMU��ʼ״̬
%      firstMeasurements����ʼ֡��state_k�������в������ݣ�
%                         [dt,y,omega,v],dt:ʱ���� y:���������������ϵ�µ�λ�� omega�ǻ�����ٶȲ���ֵ v�����ٶ�
%      camera����¼�������IMU֮��ı任��ϵ
%      state_k����¼��֡ID��
%      noiseParams�����ڳ�ʼ��Э�������

%INITIALIZEMSCKF Initialize the MSCKF with tracked features and ground
%truth


%Compute the first state
%firstImuState:1��b_g:��������ƫ
%              2��b_v:�ٶ���ƫ
%msckfState:1��imuState:imu״̬��p,q,b_g,b_v��
%           2��imuCovar:imu״̬����Э���� 
%           3��camCovar:�������Э����
%           4��imuCamCovar:imu�����֮���Э����
%           5��camStates:���״̬��p,q��
firstImuState.b_g = zeros(3,1);
firstImuState.b_v = zeros(3,1);
msckfState.imuState = firstImuState;
msckfState.imuCovar = noiseParams.initialIMUCovar;
msckfState.camCovar = [];
msckfState.imuCamCovar = [];
msckfState.camStates = {};

%�������ܣ�ͨ����ǰIMU��λ�˵õ���ǰ�����λ�ˣ����������λ�����㵽״̬���У���ȡ�ſ˱ȣ�������Э�������
msckfState = augmentState(msckfState, camera, state_k);

%Compute all of the relevant feature tracks
%��¼���и��ٵ��������������Լ�������ID�ţ���ʼ��ʱ�����е��������Լ�ID�Ŷ�ѹ�뵽featureTracks
featureTracks = {};
%��¼���и��ٵ���������ID�ţ���ʼ��ʱ��������������Ϊ�������ٵ���
trackedFeatureIds = [];

%������֡��state_k�����е�������
 for featureId = 1:size(firstMeasurements.y,2)
        %ȡ������������
        meas_k = firstMeasurements.y(:, featureId);
        %�����������Ч
        if ~isnan(meas_k(1,1))
                %Track new feature

                %����ṹ��track[featureId,�������������������]
                track.featureId = featureId;
                track.observations = meas_k;
                %����ṹ��featureTracks[track,featureId]
                featureTracks{end+1} = track;
                trackedFeatureIds(end+1) = featureId;
                %Add observation to current camera
                msckfState.camStates{end}.trackedFeatureIds(end+1) = featureId;
        end
 end
 
end

