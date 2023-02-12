%% ============================Notation============================ %%
% X_sub_super
% q_ToFrom
% p_ofWhat_expressedInWhatFrame


%% =============================Setup============================== %%
clear;
close all;
clc;
addpath('utils');

tic
dataDir = '../datasets';

% fileName = 'dataset3';
% fileName = 'dataset3_fresh_10noisy';
% fileName = 'dataset3_fresh_10lessnoisy';
% fileName = 'dataset3_fresh_20lessnoisy';
% fileName = 'dataset3_fresh_40lessnoisy';
% fileName = 'dataset3_fresh_60lessnoisy';
% fileName = 'dataset3_fresh_80lessnoisy';
% fileName = 'dataset3_fresh_100lessnoisy';
% fileName = 'dataset3_fresh_500lessnoisy';
% fileName = '2011_09_26_drive_0035_sync_KLT';
% fileName = '2011_09_26_drive_0005_sync_KLT';
% fileName = '2011_09_30_drive_0020_sync_KLT';
% fileName = '2011_09_26_drive_0027_sync_KLT';
% fileName = '2011_09_30_drive_0020_sync_KLT'; kStart = 2; kEnd = 900;

% Good KITTI runs
 fileName = '2011_09_26_drive_0001_sync_KLT'; kStart = 2; kEnd = 98;
%fileName = '2011_09_26_drive_0036_sync_KLT'; kStart = 2; kEnd = 239;
% fileName = '2011_09_26_drive_0051_sync_KLT'; kStart = 2; kEnd = 114;
% fileName = '2011_09_26_drive_0095_sync_KLT'; kStart = 2; kEnd = 139;

%����1����������
load(sprintf('%s/%s.mat',dataDir,fileName));

% r_i_vk_i = p_vi_i;

%Dataset window bounds
% kStart = 2; kEnd = 177;
% kStart = 1215; kEnd = 1715;

%Set constant
%�ܹ�Ϊ4*frames*features���õ�������ĸ���
numLandmarks = size(y_k_j,3);

%Set up the camera parameters
%����ڲΣ�IMU������ı任 Camera = q_CI * IMU + p_C_I
camera.c_u      = cu;                   % Principal point [u pixels]
camera.c_v      = cv;                   % Principal point [v pixels]
camera.f_u      = fu;                   % Focal length [u pixels]
camera.f_v      = fv;                   % Focal length [v pixels]
camera.b        = b;                    % Stereo baseline [m]
camera.q_CI     = rotMatToQuat(C_c_v);  % 4x1 IMU-to-Camera rotation quaternion
camera.p_C_I    = rho_v_c_v;            % 3x1 Camera position in IMU frame

%Set up the noise parameters
%��ʼ�������������11�����ص㣬[Pleft_u, Pleft_v, Pright_u, Pright_v]
y_var = 11^2 * ones(1,4);               % pixel coord var 121
noiseParams.u_var_prime = y_var(1)/camera.f_u^2;
noiseParams.v_var_prime = y_var(2)/camera.f_v^2;

%����2����ʼ��imuԤ��Э����Ͳ���Э�������
%����2.1����ʼ������Э�������
%���ٶȲ���Э����
w_var = 4e-2 * ones(1,3);              % rot vel var0.04
%�ٶ�Э����
v_var = 4e-2 * ones(1,3);              % lin vel var
%��������ƫЭ����
dbg_var = 1e-6 * ones(1,3);            % gyro bias change var
%�ٶ���ƫЭ����
dbv_var = 1e-6 * ones(1,3);            % vel bias change var
%��������״̬���ĳ�ʼЭ�������
noiseParams.Q_imu = diag([w_var, dbg_var, v_var, dbv_var]);

%����2.2����ʼ��״̬��Ԥ��Э�������
q_var_init = 1e-6 * ones(1,3);         % init rot var
p_var_init = 1e-6 * ones(1,3);         % init pos var
bg_var_init = 1e-6 * ones(1,3);        % init gyro bias var
bv_var_init = 1e-6 * ones(1,3);        % init vel bias var
noiseParams.initialIMUCovar = diag([q_var_init, bg_var_init, bv_var_init, p_var_init]);
   
% MSCKF parameters
% ����MSCKF����
% ���������ٱ�����10֡����
msckfParams.minTrackLength = 10;        % Set to inf to dead-reckon only
msckfParams.maxTrackLength = Inf;      % Set to inf to wait for features to go out of view
msckfParams.maxGNCostNorm  = 1e-2;     % Set to inf to allow any triangulation, no matter how bad
msckfParams.minRCOND       = 1e-12;
msckfParams.doNullSpaceTrick = true;
msckfParams.doQRdecomp = true;


% IMU state for plotting etc. Structures indexed in a cell array
imuStates = cell(1,numel(t));
prunedStates = {};

% imuStates{k}.q_IG         4x1 Global to IMU rotation quaternion
% imuStates{k}.p_I_G        3x1 IMU Position in the Global frame
% imuStates{k}.b_g          3x1 Gyro bias
% imuStates{k}.b_v          3x1 Velocity bias
% imuStates{k}.covar        12x12 IMU state covariance

% We don't really need these outside of msckfState, do we?
% camState = cell(1,numel(t));
% camStates{k}.q_CG        4x1 Global to camera rotation quaternion
% camStates{k}.p_C_G       3x1 Camera Position in the Global frame
% camStates{k}.trackedFeatureIds  1xM List of feature ids that are currently being tracked from that camera state
% camStates{k}.state_k

%msckfState.imuState
%msckfState.imuCovar
%msckfState.camCovar
%msckfState.imuCamCovar
%msckfState.camStates


% Measurements as structures all indexed in a cell array
%diff����ͨ��΢��t�����õ�{0��dT1,dT2,dT3...}
dT = [0, diff(t)];
%�õ�����t��Ԫ�ظ���
measurements = cell(1,numel(t));
% groundTruthStates = cell(1,numel(t));
% groundTruthMap = rho_i_pj_i;

% Important: Because we're idealizing our pixel measurements and the
% idealized measurements could legitimately be -1, replace our invalid
% measurement flag with NaN
%����y_k_j������Ԫ�أ������������-1�����Ϊ�����
y_k_j(y_k_j == -1) = NaN;

%����3������������ݺͲο�ֵ��measurements��groundTruthStates
%measurements��[dt,y,omega,v],dt:ʱ���� y:���������������ϵ�µ�λ�� omega�ǻ�����ٶȲ���ֵ v�����ٶ�
%groundTruthStates:[imuState:q_IG,p_I_G
%                   camState:q_IG,p_I_G]
for state_k = kStart:kEnd 
    measurements{state_k}.dT    = dT(state_k);                      % sampling times
    %yΪ�����state_k֡���е������㣬yΪ2*featuresά�ľ���
    measurements{state_k}.y     = squeeze(y_k_j(1:2,state_k,:));    % left camera only ��άѹ���ɶ�ά�õ�һ֡��������
    %OmegaΪstate_k֡�����н��ٶȣ�omegaΪ3*1ά��������
    measurements{state_k}.omega = w_vk_vk_i(:,state_k);             % ang vel
    %vΪstate_k֡���������ٶȣ�vΪ3*1ά��������
    measurements{state_k}.v     = v_vk_vk_i(:,state_k);             % lin vel
    
    %Idealize measurements
    %�ж�state_k֡�������������Ƿ���Ч����ЧΪ1����ЧΪ0
    validMeas = ~isnan(measurements{state_k}.y(1,:));
    %����֡������Ч�������㣬��ͼ������ϵ��ͶӰ���������ϵ
    measurements{state_k}.y(1,validMeas) = (measurements{state_k}.y(1,validMeas) - camera.c_u)/camera.f_u;
    measurements{state_k}.y(2,validMeas) = (measurements{state_k}.y(2,validMeas) - camera.c_v)/camera.f_v;
    
    %Ground Truth
    %theta_vk_i����̬�ǲο�ֵ��globle��imu������̬��ת��Ϊ��ת������תΪ��Ԫ��
    q_IG = rotMatToQuat(axisAngleToRotMat(theta_vk_i(:,state_k)));
    %r_i_vk_i��λ�òο�ֵ,globle��imu
    p_I_G = r_i_vk_i(:,state_k);
    
    %����ο�ֵ�ṹ�壺[imuState:q_IG,p_I_G
    %                  camState:q_IG,p_I_G]
    groundTruthStates{state_k}.imuState.q_IG = q_IG;
    groundTruthStates{state_k}.imuState.p_I_G = p_I_G;
    
    % Compute camera pose from current IMU pose
    %�õ�globle��imu����ת������ת������C��ʾ
    C_IG = quatToRotMat(q_IG);
    %�õ�globle��camera����Ԫ���任
    q_CG = quatLeftComp(camera.q_CI) * q_IG;
    %�õ�globle��camera��λ�ñ任�����������������ϵ�µ�λ��
    p_C_G = p_I_G + C_IG' * camera.p_C_I;
    
    %����ο�ֵ�ṹ�壺[imuState:q_IG,p_I_G
    %                  camState:q_IG,p_I_G]
    groundTruthStates{state_k}.camState.q_CG = q_CG;
    groundTruthStates{state_k}.camState.p_C_G = p_C_G;
    
end


%Struct used to keep track of features
%��¼׷�ٵ��������������ڲ�ͬ����еĹ۲��Լ�����ID�� 
featureTracks = {};
trackedFeatureIds = [];

% featureTracks = {track1, track2, ...}
% track.featureId 
% track.observations



%% ==========================Initial State======================== %%
%Use ground truth for first state and initialize feature tracks with
%feature observations
%Use ground truth for the first state

%����4����ʼ��MSCKF
%����4.1����ȡ��һ����Ԫ���ο�ֵ��ΪIMU״̬�ĳ�ʼֵ
firstImuState.q_IG = rotMatToQuat(axisAngleToRotMat(theta_vk_i(:,kStart)));
%����4.2����ȡ��һ��λ�òο�ֵ��Ϊλ�ó�ʼֵ
firstImuState.p_I_G = r_i_vk_i(:,kStart);
% firstImuState.q_IG = [0;0;0;1];
% firstImuState.q_IG = rotMatToQuat(rotx(90));
% firstImuState.p_I_G = [0;0;0];

%����4.3����ʼ��msckf��״̬��Ŀǰֻ��IMU��״̬����ʼ�����ٵ��������㣬��һ֡���е���������Ϊ����������
[msckfState, featureTracks, trackedFeatureIds] = initializeMSCKF(firstImuState, measurements{kStart}, camera, kStart, noiseParams);
%��MSCKF״̬�и���IMU����ʷ״̬���������״̬���¶�Ӧʱ��imu��λ��״̬
imuStates = updateStateHistory(imuStates, msckfState, camera, kStart);
%��ͼ����ʹ��
msckfState_imuOnly{kStart} = msckfState;

%% ============================MAIN LOOP========================== %%

numFeatureTracksResidualized = 0;
map = [];

%��������֡��ÿһ֡ͼ���Ӧһ��imu���ݣ�
for state_k = kStart:(kEnd-1)
    fprintf('state_k = %4d\n', state_k);
    
    %% ==========================STATE PROPAGATION======================== %%
    %ò��Ĭ��IMU��Cameraͬ������
    %Propagate state and covariance
    %����5��msckfԤ����£�����״̬��������Э�������
    msckfState = propagateMsckfStateAndCovar(msckfState, measurements{state_k}, noiseParams);
    %msckfԤ����£�����״̬��������Э������󣬵���msckfState_imuOnly״̬����ֻ��IMU��״̬�����ڶԱȲ��ԣ�
    msckfState_imuOnly{state_k+1} = propagateMsckfStateAndCovar(msckfState_imuOnly{state_k}, measurements{state_k}, noiseParams);
    %Add camera pose to msckfState
    %����6��msckf״̬�������������״̬�������ſ˱ȣ�����Э������󣬲�����Э�������
    msckfState = augmentState(msckfState, camera, state_k+1);
    %% ==========================FEATURE TRACKING======================== %%
    % Add observations to the feature tracks, or initialize a new one
    % If an observation is -1, add the track to featureTracksToResidualize
    featureTracksToResidualize = {};
    
    %����7��������ǰ֡���������㣬����featureTracks
    %˵����msckf����featureTracks��¼��Ŀǰ�����ٵ��������㡣
    %       featureTracks�а���ÿ��������ID�͹۲�ֵ�����������ܹ۲⵽����������������ϵ�µ�������꣩
           
    %������֡���е�������
    for featureId = 1:numLandmarks
        %IMPORTANT: state_k + 1 not state_k
        %ȡһ�����������꣨������Ϊ�������ϵ�����Ѿ�����ͶӰ���꣩
        meas_k = measurements{state_k+1}.y(:, featureId);
        
        %�жϸ��������Ƿ���Ч
        outOfView = isnan(meas_k(1,1));
        
        %����7.1��������ǰ֡���������㣬�ж��Ƿ�����featureTracks
        if ismember(featureId, trackedFeatureIds)

            %����7.2�����������������Ұ��Χ�ڣ������������������ϵ�µ����������ӵ�featureTracks�ж�Ӧ�����Ĺ۲��С�
            if ~outOfView
                %Append observation and append id to cam states
                %�����������Լ�ID����ӵ�featureTracks
                %trackedFeatureIds��¼�˸��ٵ���������ID��featureTracks��¼�˸��ٵ�������������
                featureTracks{trackedFeatureIds == featureId}.observations(:, end+1) = meas_k;
                
                %Add observation to current camera
                %�����ٵ���������ID����ӵ����״̬������trackedFeatureIds��
                %�����״ֻ̬����λ�ú���Ԫ��������ͬ�����¼���ٵ���������������ԣ�
                msckfState.camStates{end}.trackedFeatureIds(end+1) = featureId;
            end
            
            %����7.3������������㳬����Ұ��Χ�����ܹ��۲⵽�������������Ŀ��������ֵ
            %ȡ����������Ԫ��������+������ID+���ٵ�������������״̬��
            track = featureTracks{trackedFeatureIds == featureId};
            
            %�������������Ұ��Χ�ڻ���������Ĺ۲��������趨������ֵ�����жϸ��������Ƿ��㹻��
            %�򽫹۲⵽������������ȡ�������Ż�
            if outOfView ...
                    || size(track.observations, 2) >= msckfParams.maxTrackLength ...
                    || state_k+1 == kEnd
                                
                %Feature is not in view, remove from the tracked features
                %���������״̬���޳��������㣬�����漰�������״̬��ӵ�״̬���Ż��б���
                %updatedMsckfState��״̬���Ż��б�msckf״̬��
                %featCamStates�����Ż������״̬��������۲�������㳬����Ұ���ڱ��۲⵽��
                %camStateIndices�����Ż����������
                [msckfState, camStates, camStateIndices] = removeTrackedFeature(msckfState, featureId);
                
                %Add the track, with all of its camStates, to the
                %residualized list
                %���Ż������״̬������С���ٳ��ȣ�10����������ӵ��б��������Ż���featureTracksToResidualize��
                if length(camStates) >= msckfParams.minTrackLength
                    track.camStates = camStates;
                    track.camStateIndices = camStateIndices;
                    featureTracksToResidualize{end+1} = track;
                end
               
                %Remove the track
                %����ʹ��������������featureTracks���޳���������
                featureTracks = featureTracks(trackedFeatureIds ~= featureId);
                %����ʹ��������������trackedFeatureIds���޳���������ID
                trackedFeatureIds(trackedFeatureIds == featureId) = []; 
            end
        
        %����7.4�����ٵ��µ������㣨��������֮ǰû�б����ٵ�����������Ұ��Χ�ڣ���������������ӵ������������б�
        %ͬʱ���۲⵽��������������¼���������ѱ����ٵ�����ӵ����״̬�У�
        elseif ~outOfView && state_k+1 < kEnd % && ~ismember(featureId, trackedFeatureIds)
            %Track new feature
            track.featureId = featureId;
            track.observations = meas_k;
            featureTracks{end+1} = track;
            trackedFeatureIds(end+1) = featureId;

            %Add observation to current camera
            msckfState.camStates{end}.trackedFeatureIds(end+1) = featureId;
        end
    end
     
    %����8��MSCKF�������¡��������������Ż���������,����۲�ģ�ͣ���������ͶӰ��������MSCKF״̬
    %% ==========================FEATURE RESIDUAL CORRECTIONS======================== %%
    %��������Ż��������㣨��¼���ܹ۲⵽��Щ��������������Ϊ��
    if ~isempty(featureTracksToResidualize)
        H_o = [];
        r_o = [];
        R_o = [];
        %����8.1��ͨ�����������й۲���Ƴ����������3D�ռ�����λ��
        %�������������Ż���������
        for f_i = 1:length(featureTracksToResidualize)
            %ȡ������һ��������Ԫ(��������Ӧ�����й۲�)
            track = featureTracksToResidualize{f_i};     
            %Estimate feature 3D location through Gauss Newton inverse depth
            %optimization
            %ʹ������Ȳ���������ͶӰ�������ø�˹ţ���Ż��ķ�������������3D����p_f_G
            [p_f_G, Jcost, RCOND] = calcGNPosEst(track.camStates, track.observations, noiseParams);
            % Uncomment to use ground truth map instead
%              p_f_G = groundTruthMap(:, track.featureId); Jcost = 0; RCOND = 1;
%              p_f_C = triangulate(squeeze(y_k_j(:, track.camStates{1}.state_k, track.featureId)), camera); Jcost = 0; RCOND = 1;
            %��ȡ���ٵ�����������������
            nObs = size(track.observations,2);
            %����������ͶӰ���ƽ����ÿ�������ͶӰ���
            JcostNorm = Jcost / nObs^2;
            fprintf('Jcost = %f | JcostNorm = %f | RCOND = %f\n',...
                Jcost, JcostNorm,RCOND);
            
            %ͶӰ���̫�󣬻��ߵ���ʱHessian�������治�ɿ�
            if JcostNorm > msckfParams.maxGNCostNorm ...
                    || RCOND < msckfParams.minRCOND
%                     || norm(p_f_G) > 50
                
                break;
            else
                %��3D����뵽��ͼ
                map(:,end+1) = p_f_G;
                numFeatureTracksResidualized = numFeatureTracksResidualized + 1;
                fprintf('Using new feature track with %d observations. Total track count = %d.\n',...
                    nObs, numFeatureTracksResidualized);
            end
            %����8.2��ͨ������3D���������ƥ��������֮�����ͶӰ�в��۲�ģ�ͣ�������ͶӰ����MSCKF״̬�����ſ˱Ⱦ������� 
            %Calculate residual and Hoj
            %�����Ż�������3D���������ƥ��������֮�����ͶӰ�в�
            [r_j] = calcResidual(p_f_G, track.camStates, track.observations);
            %������ͶӰ�в������������2*camState,2*camState����С����
            R_j = diag(repmat([noiseParams.u_var_prime, noiseParams.v_var_prime], [1, numel(r_j)/2]));
            %������ͶӰ����MSCKF״̬�����ſ˱Ⱦ���MSCKF�۲�ģ�ͣ�
            [H_o_j, A_j, H_x_j] = calcHoj(p_f_G, msckfState, track.camStateIndices);

            % Stacked residuals and friends
            %�ж��Ƿ�Ҫ����ͶӰ�����������H_f_j����ռ�任�������calcHoj������󲿷�
            if msckfParams.doNullSpaceTrick
                %����H����
                H_o = [H_o; H_o_j];

                if ~isempty(A_j)
                    r_o_j = A_j' * r_j;
                    r_o = [r_o ; r_o_j];

                    R_o_j = A_j' * R_j * A_j;
                    R_o(end+1 : end+size(R_o_j,1), end+1 : end+size(R_o_j,2)) = R_o_j;
                end
                
            else
                H_o = [H_o; H_x_j];
                r_o = [r_o; r_j];
                R_o(end+1 : end+size(R_j,1), end+1 : end+size(R_j,2)) = R_j;
            end
        end
        
        if ~isempty(r_o)
            % Put residuals into their final update-worthy form
            if msckfParams.doQRdecomp
                %QR�ֽ�H_o���󣬲����޳�Q�е����У��Լ�R�ж�Ӧ����
                [T_H, Q_1] = calcTH(H_o);
                %error = H * x + n  (�۲�ģ�ͣ�nΪ����Э����)
                %      = Q_1 * T_H * x + n
                %==> Q_1' * error = Q_1' * Q_1 * T_H * x + Q_1' * n * Q_1
                %                 = T_H * x + Q_1' * n * Q_1
                r_n = Q_1' * r_o;
                R_n = Q_1' * R_o * Q_1;
            else
                T_H = H_o;
                r_n = r_o;
                R_n = R_o;
            end           
            %����8.3�����㿨�������棬�������״̬
            % Build MSCKF covariance matrix
            P = [msckfState.imuCovar, msckfState.imuCamCovar;
                   msckfState.imuCamCovar', msckfState.camCovar];

            % Calculate Kalman gain
            K = (P*T_H') / ( T_H*P*T_H' + R_n );

            % State correction
            deltaX = K * r_n;
            %����8.4���������״̬����MSCKF״̬��x_true := x_nominal + detx
            msckfState = updateState(msckfState, deltaX);

            % Covariance correction
            %����8.5��Э�����������
            tempMat = (eye(12 + 6*size(msckfState.camStates,2)) - K*T_H);
%             tempMat = (eye(12 + 6*size(msckfState.camStates,2)) - K*H_o);

            P_corrected = tempMat * P * tempMat' + K * R_n * K';

            msckfState.imuCovar = P_corrected(1:12,1:12);
            msckfState.camCovar = P_corrected(13:end,13:end);
            msckfState.imuCamCovar = P_corrected(1:12, 13:end);
           
%             figure(1); clf; imagesc(deltaX); axis equal; axis ij; colorbar;
%             drawnow;
            
        end
        
    end
    
        %% ==========================STATE HISTORY======================== %%
        %����9����ʷ״̬���¡���MSCKF״̬�и���IMU����ʷ״̬��ͨ�������״̬���¶�Ӧʱ��imu��λ��״̬
        imuStates = updateStateHistory(imuStates, msckfState, camera, state_k+1);
        
        
        %% ==========================STATE PRUNING======================== %%
        %����10��״̬�޳����޳�MSCKF����Ҫ��ɾ����״̬�Ͷ�Ӧ��Э��������
        %Remove any camera states with no tracked features
        %�ֱ�õ�MSCKF����Ҫ��������ɾ����״̬��Э����
        [msckfState, deletedCamStates] = pruneStates(msckfState);

        %����ɾ�������λ��
        if ~isempty(deletedCamStates)
            prunedStates(end+1:end+length(deletedCamStates)) = deletedCamStates;
        end    
        
%         if max(max(msckfState.imuCovar(1:12,1:12))) > 1
%             disp('omgbroken');
%         end
        
        plot_traj;
%     figure(1); imagesc(msckfState.imuCovar(1:12,1:12)); axis equal; axis ij; colorbar;
%     drawnow;
end %for state_K = ...

toc


%% ==========================PLOT ERRORS======================== %%
kNum = length(prunedStates);
p_C_G_est = NaN(3, kNum);
p_I_G_imu = NaN(3, kNum);
p_C_G_imu = NaN(3, kNum);
p_C_G_GT = NaN(3, kNum);
theta_CG_err = NaN(3,kNum);
theta_CG_err_imu = NaN(3,kNum);
err_sigma = NaN(6,kNum); % cam state is ordered as [rot, trans]
err_sigma_imu = NaN(6,kNum);
% 
tPlot = NaN(1, kNum);
% 
for k = 1:kNum
    state_k = prunedStates{k}.state_k;
    
    p_C_G_GT(:,k) = groundTruthStates{state_k}.camState.p_C_G;
    p_C_G_est(:,k) = prunedStates{k}.p_C_G;
    q_CG_est  = prunedStates{k}.q_CG;    
    
    theta_CG_err(:,k) = crossMatToVec( eye(3) ...
                    - quatToRotMat(q_CG_est) ...
                        * ( C_c_v * axisAngleToRotMat(theta_vk_i(:,kStart+k-1)) )' );
      
    err_sigma(:,k) = prunedStates{k}.sigma;
    imusig = sqrt(diag(msckfState_imuOnly{state_k}.imuCovar));
    err_sigma_imu(:,k) = imusig([1:3,10:12]);
    
    p_I_G_imu(:,k) = msckfState_imuOnly{state_k}.imuState.p_I_G;
    C_CG_est_imu = C_CI * quatToRotMat(msckfState_imuOnly{state_k}.imuState.q_IG);
    theta_CG_err_imu(:,k) = crossMatToVec( eye(3) ...
                    - C_CG_est_imu ...
                        * ( C_CI * axisAngleToRotMat(theta_vk_i(:,kStart+k-1)) )' );
                    
    tPlot(k) = t(state_k);
end

% p_I_G_GT = p_vi_i(:,kStart:kEnd);
p_I_G_GT = r_i_vk_i(:,kStart:kEnd);
p_C_G_GT = p_I_G_GT + repmat(rho_v_c_v,[1,size(p_I_G_GT,2)]);
p_C_G_imu = p_I_G_imu + repmat(rho_v_c_v,[1,size(p_I_G_imu,2)]);

rotLim = [-0.5 0.5];
transLim = [-0.5 0.5];

% Save estimates
msckf_trans_err = p_C_G_est - p_C_G_GT;
msckf_rot_err = theta_CG_err;
imu_trans_err = p_C_G_imu - p_C_G_GT;
imu_rot_err = theta_CG_err_imu;
save(sprintf('../KITTI Trials/msckf_%s', fileName));

armse_trans_msckf = mean(sqrt(sum(msckf_trans_err.^2, 1)/3));
armse_rot_msckf = mean(sqrt(sum(msckf_rot_err.^2, 1)/3));
final_trans_err_msckf = norm(msckf_trans_err(:,end));

armse_trans_imu = mean(sqrt(sum(imu_trans_err.^2, 1)/3));
armse_rot_imu = mean(sqrt(sum(imu_rot_err.^2, 1)/3));
final_trans_err_imu = norm(imu_trans_err(:,end));

fprintf('Trans ARMSE: IMU %f, MSCKF %f\n',armse_trans_imu, armse_trans_msckf);
fprintf('Rot ARMSE: IMU %f, MSCKF %f\n',armse_rot_imu, armse_rot_msckf);
fprintf('Final Trans Err: IMU %f, MSCKF %f\n',final_trans_err_imu, final_trans_err_msckf);

% Translation Errors
figure
subplot(3,1,1)
plot(tPlot, p_C_G_est(1,:) - p_C_G_GT(1,:), 'LineWidth', 2)
hold on
plot(tPlot, 3*err_sigma(4,:), '--r')
plot(tPlot, -3*err_sigma(4,:), '--r')
% ylim(transLim)
xlim([tPlot(1) tPlot(end)])
title('Translational Error')
ylabel('\delta r_x')


subplot(3,1,2)
plot(tPlot, p_C_G_est(2,:) - p_C_G_GT(2,:), 'LineWidth', 2)
hold on
plot(tPlot, 3*err_sigma(5,:), '--r')
plot(tPlot, -3*err_sigma(5,:), '--r')
% ylim(transLim)
xlim([tPlot(1) tPlot(end)])
ylabel('\delta r_y')

subplot(3,1,3)
plot(tPlot, p_C_G_est(3,:) - p_C_G_GT(3,:), 'LineWidth', 2)
hold on
plot(tPlot, 3*err_sigma(6,:), '--r')
plot(tPlot, -3*err_sigma(6,:), '--r')
% ylim(transLim)
xlim([tPlot(1) tPlot(end)])
ylabel('\delta r_z')
xlabel('t_k')

% Rotation Errors
figure
subplot(3,1,1)
plot(tPlot, theta_CG_err(1,:), 'LineWidth', 2)
hold on
plot(tPlot, 3*err_sigma(1,:), '--r')
plot(tPlot, -3*err_sigma(1,:), '--r')
ylim(rotLim)
xlim([tPlot(1) tPlot(end)])
title('Rotational Error')
ylabel('\delta \theta_x')


subplot(3,1,2)
plot(tPlot, theta_CG_err(2,:), 'LineWidth', 2)
hold on
plot(tPlot, 3*err_sigma(2,:), '--r')
plot(tPlot, -3*err_sigma(2,:), '--r')
ylim(rotLim)
xlim([tPlot(1) tPlot(end)])
ylabel('\delta \theta_y')

subplot(3,1,3)
plot(tPlot, theta_CG_err(3,:), 'LineWidth', 2)
hold on
plot(tPlot, 3*err_sigma(3,:), '--r')
plot(tPlot, -3*err_sigma(3,:), '--r')
ylim(rotLim)
xlim([tPlot(1) tPlot(end)])
ylabel('\delta \theta_z')
xlabel('t_k')