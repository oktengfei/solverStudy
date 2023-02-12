function [ prunedMsckfState, deletedCamStates ] = pruneStates( msckfState )
%�������ܣ��ֱ�õ�MSCKF����Ҫ��������ɾ����״̬��Э����
%
%����ֵ��
%      prunedMsckfState��MSCKF����Ҫ��������״̬��Э����
%      deletedCamStates��MSCKF����Ҫ��ɾ����״̬��Э����
%����ֵ��
%      msckfState��msckfδɾ��ǰ״̬

%PRUNESTATES Prunes any states that have no tracked features and updates
%covariances
    
    prunedMsckfState.imuState = msckfState.imuState;
    prunedMsckfState.imuCovar = msckfState.imuCovar;
    
    %Find all camStates with no tracked landmarks    
    %�ҵ�����������Ϊ�յ����״̬����ӵ�ɾ���б�deleteIdx��
    deleteIdx = [];
    for c_i = 1:length(msckfState.camStates)
        if isempty(msckfState.camStates{c_i}.trackedFeatureIds)
            deleteIdx(end+1) = c_i;
        end
    end
    
    %Prune the damn states!
    
    %����1��ɾ��msckf����Ҫɾ����״̬
    %ȡ��msckf��Ҫɾ�������״̬
    deletedCamStates = msckfState.camStates(deleteIdx);
    %��msckf��ɾ����Ҫɾ�������״̬
    prunedMsckfState.camStates = removeCells(msckfState.camStates, deleteIdx);
    
    %Э������������Э���������
    statesIdx = 1:size(msckfState.camCovar,1);
    %keepCovarMask���ڱ��Ҫ������Э������
    keepCovarMask = true(1, numel(statesIdx));
    for dIdx = deleteIdx
        %Э������Ҫɾ������Ϊfalse
        keepCovarMask(6*dIdx - 5:6*dIdx) = false(6,1);
    end
    
    %��Э������Ӧλ�ñ����Ƿ���״̬������Ϊtrue��ɾ��Ϊfalse
    keepCovarIdx = statesIdx(keepCovarMask);
    deleteCovarIdx = statesIdx(~keepCovarMask);

    %����2��ɾ��msckf����Ҫɾ����Э����
    %�õ���Ҫ��������Э���IMU-IMUЭ����ȫ������
    %�õ�camera-cameraЭ������������Ҫ�������Ĳ���
    prunedMsckfState.camCovar = msckfState.camCovar(keepCovarIdx, keepCovarIdx);
    %Keep rows, prune columns of upper right covariance matrix
    %�õ�imu-cameraЭ������������Ҫ�������Ĳ���
    prunedMsckfState.imuCamCovar = msckfState.imuCamCovar(:, keepCovarIdx);
    %�õ�camera-cameraЭ����������Ҫɾ���Ĳ���
    deletedCamCovar = msckfState.camCovar(deleteCovarIdx, deleteCovarIdx);
    %�õ�Ҫɾ����camera-cameraЭ����Խ��ߵ�Ԫ�ؾ�����deletedCamSigma
    deletedCamSigma = sqrt(diag(deletedCamCovar));
    
    % Grab the variances of the deleted states for plotting
    %�õ�Ҫɾ�������״̬��Ӧ��Э�������Խ���Ԫ�صľ���������ͼ�ã�
    for c_i = 1:size(deletedCamStates, 2)
        deletedCamStates{c_i}.sigma = deletedCamSigma(6*c_i - 5 : 6*c_i);
    end
end

