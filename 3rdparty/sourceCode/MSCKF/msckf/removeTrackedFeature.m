function  [updatedMsckfState, featCamStates, camStateIndices] = removeTrackedFeature(msckfState, featureId)
%�������ܣ����������״̬���޳��������㣨��֤���۲⵽�ĸ��������㹻�ã��������漰�������״̬��ӵ�״̬���Ż��б���
%�����״ֻ̬����λ�ú���Ԫ��������ͬ�����¼���ٵ���������������ԣ�
%����ֵ��
%      updatedMsckfState��״̬���Ż��б�msckf״̬��
%      featCamStates�����Ż������״̬��������۲�������㳬����Ұ���ڱ��۲⵽������������������״̬���ޣ���
%      camStateIndices�����Ż����������
%����ֵ��
%      msckfState��msckf״̬
%      featureId��Ҫ�޳�������ID

%REMOVETRACKEDFEATURE Remove tracked feature from camStates and extract all
%camera states that include it

    updatedCamStates = msckfState.camStates;
    featCamStates = {};
    camStateIndices = [];
    %����msckf�����״̬
    for c_i = 1:length(updatedCamStates)
        %���״̬�м�¼�˸��ٵ��������㣬�ж�Ҫ�޳����������Ƿ�������
        featIdx = find(featureId == updatedCamStates{c_i}.trackedFeatureIds);
        %���Ҫ�޳����������Ƿ��ڵ�ǰ���׷�ٵ��������б��У������޳�����Ϊ�գ�
        %�������״̬��ӵ����Ż���״̬�б���
        if ~isempty(featIdx)
            updatedCamStates{c_i}.trackedFeatureIds(featIdx) = [];
            camStateIndices(end + 1) = c_i;
            featCamStates{end +1} = updatedCamStates{c_i};
        end
    end
    
    updatedMsckfState = msckfState;
    updatedMsckfState.camStates = updatedCamStates;
end

