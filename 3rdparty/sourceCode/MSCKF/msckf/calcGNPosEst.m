function [p_f_G, Jnew, RCOND] = calcGNPosEst(camStates, observations, noiseParams)
%�������ܣ�ʹ������Ȳ���������ͶӰ�������ø�˹ţ���Ż��ķ�������������3D����
%
%����ֵ��
%      p_f_G��global����ϵ��3x1��������
%      Jnew��chi2ָ�꣬��ʾ�в��С
%      RCOND������1-�������ĵ���
%����ֵ��
%      camStates��M�����״̬
%      observations����ǰ·����2XM�����������
%      noiseParams�� ͼ���������

%CALCGNPOSEST Calculate the position estimate of the feature using Gauss
%Newton optimization
%   INPUT:
%   observations: 2xM matrix of pixel values of the current landmark
%   camStates: Cell array of M structs of camera poses
%   camera: intrinsic calibration
%   OUTPUT:
%   p_f_G: 3x1 feature vector in the global frame

%K is not needed if we assume observations are not pixels but x' = (u -
%c_u)/f_u

%K = [camera.f_u 0 camera.c_u; 0 camera.f_v camera.c_v; 0 0 1];

%Get initial estimate through intersection
%Use the first 2 camStates
%ѡ���һ֡�����camStates{1}�������һ֡�����camStates{secondViewIdx}�������������ǻ��ָ�3D��
%��ȡ���״̬����
secondViewIdx = length(camStates);
%��õ�һ֡��������һ֮֡���λ�ˣ�2��1��
C_12 = quatToRotMat(camStates{1}.q_CG)*quatToRotMat(camStates{secondViewIdx}.q_CG)';
t_21_1 = quatToRotMat(camStates{1}.q_CG)*(camStates{secondViewIdx}.p_C_G - camStates{1}.p_C_G);
%���ǻ��ָ�3D��
p_f1_1_bar = triangulate(observations(:,1), observations(:,secondViewIdx),C_12, t_21_1);

%initialEst = quatToRotMat(camStates{1}.q_CG)'*p_f1_1_bar + camStates{1}.p_C_G;


%�ο�����1����The Battle for Filter Supremacy: A Comparative Study of the
%     Multi-State Constraint Kalman Filter and the Sliding Window Filter��

%�ο�����2����A Multi-State Constraint Kalman Filter
%     for Vision-aided Inertial Navigation��


xBar = p_f1_1_bar(1);
yBar = p_f1_1_bar(2);
zBar = p_f1_1_bar(3);
%������Ȳ�����3D��
alphaBar = xBar/zBar;
betaBar = yBar/zBar;
rhoBar = 1/zBar;

%xEstΪ�������ʽ��ʾ�Ĳ�������
xEst = [alphaBar; betaBar; rhoBar];
%��ȡ���״̬����
Cnum = length(camStates);

%Optimize
%���ø�˹ţ���Ż��Ĳ���������������
maxIter = 10;
Jprev = Inf;

for optI = 1:maxIter
    %��ʼ���������E�����Ȩ�ؾ���W
    E = zeros(2*Cnum, 3);
    W = zeros(2*Cnum, 2*Cnum);
    errorVec = zeros(2*Cnum, 1);

    for iState = 1:Cnum
        %Form the weight matrix
        W((2*iState - 1):(2*iState),(2*iState - 1):(2*iState)) = diag([noiseParams.u_var_prime noiseParams.v_var_prime]);

        C_i1 = quatToRotMat(camStates{iState}.q_CG)*(quatToRotMat(camStates{1}.q_CG)');
        t_1i_i = quatToRotMat(camStates{iState}.q_CG)*(camStates{1}.p_C_G - camStates{iState}.p_C_G);
        

        %Form the error vector
        zHat = observations(:, iState);
        %�ο�����1����ʽ36
        %�ο�����2����ʽ32-��ʽ37
        % |h1|         |alpha|
        % |h2| = Ci1 * |beta | + rho * t_1i_i
        % |h3|         |  1  |
        % Ϊ���Ƶ����㣬��ô��
        % |h1|                             |alpha|
        % |h2| =(Ci1(:1),Ci1(:1),Ci1(:1))* |beta | + rho * t_1i_i
        % |h3|                             |  1  |
        h = C_i1*[alphaBar; betaBar; 1] + rhoBar*t_1i_i;

        %������ͶӰ���
        %�ο�����1����ʽ37
        %e = z - |h1/h3|
        %        |h2/h3|
        errorVec((2*iState - 1):(2*iState),1) = zHat - [h(1); h(2)]/h(3);

        %Form the Jacobian
        %������ͶӰ��������Ȳ���xEst���ſ˱Ⱦ���
        %�ο�����1����ʽ39
        %de/dh = |-1/h3     0      h1/h3^2|
        %        |0       -1/h3    h2/h3^2|
        %dh/d(alpha,beta,rho) = |C_i1(:,1)  C_i1(:,2)  t_li_i|
        
        %de/d(alpha,beta,rho) = (de/dh) * (dh/d(alpha,beta,rho))
        %                     = |-1/h3     0      h1/h3^2| * |C_i1(:,1)  C_i1(:,2)  t_li_i|
        %                       |0       -1/h3    h2/h3^2|
        %                                                    |C_i1(1,1)  C_i1(1,2)  t_li_i(1)|
        %                     = |-1/h3     0      h1/h3^2| * |C_i1(2,1)  C_i1(2,2)  t_li_i(2)|
        %                       |0       -1/h3    h2/h3^2|   |C_i1(3,1)  C_i1(3,2)  t_li_i(3)|
        dEdalpha = [-C_i1(1,1)/h(3) + (h(1)/h(3)^2)*C_i1(3,1); ...
                    -C_i1(2,1)/h(3) + (h(2)/h(3)^2)*C_i1(3,1)];

        dEdbeta =  [-C_i1(1,2)/h(3) + (h(1)/h(3)^2)*C_i1(3,2); ...
                    -C_i1(2,2)/h(3) + (h(2)/h(3)^2)*C_i1(3,2)];

        dEdrho =   [-t_1i_i(1)/h(3) + (h(1)/h(3)^2)*t_1i_i(3); ...
                    -t_1i_i(2)/h(3) + (h(2)/h(3)^2)*t_1i_i(3)];

        Eblock = [dEdalpha dEdbeta dEdrho];
        %���������������ͶӰ����������Ȳ������ſ˱Ⱦ���
        E((2*iState - 1):(2*iState), :) = Eblock;
    end
    
    %Calculate the cost function
    %������ۺ���(�����ж���ֹ����)��0.5 * error' * W^(-1) * error 
    Jnew = 0.5*errorVec'*(W\errorVec);
    %Solve!
    %����Ż���������E'*W^(-1)*E��* dx_star = -E'*W^(-1)*errorVec���õ����������xEst����
    EWE = E'*(W\E);
    %RCOND����ֵ�ӽ�1����ţ����ؽӽ�0�����
    RCOND = rcond(EWE);
    dx_star =  (EWE)\(-E'*(W\errorVec));
    
    xEst = xEst + dx_star;
    %��������½��̶ȣ������ж���ֹ�������½������ˣ�����Ϊ������������
    Jderiv = abs((Jnew - Jprev)/Jnew);
    
    Jprev = Jnew;

    if Jderiv < 0.01
        break;
    else
        alphaBar = xEst(1);
        betaBar = xEst(2);
        rhoBar = xEst(3);
    end
    
end

%���������ʽ��ʾ��3D��ת����ŷʽ����ϵ�µ�3D������
p_f_G = (1/xEst(3))*quatToRotMat(camStates{1}.q_CG)'*[xEst(1:2); 1] + camStates{1}.p_C_G; 

        %���ǻ��ָ�3D��
    function [p_f1_1] = triangulate(obs1, obs2, C_12, t_21_1)
    %obs1��obs2�����������ƥ�����������꣨�������ϵ��
    %C_12��t_21_1���������֮��ı任��ϵ
        
        % triangulate Triangulates 3D points from two sets of feature vectors and a
        % a frame-to-frame transformation

           %Calculate unit vectors
           %���������ϵ�������Ϊ�������[x,y,1]
           v_1 = [obs1;1];
           v_2 = [obs2;1];
           %��һ������
           v_1 = v_1/norm(v_1);
           v_2 = v_2/norm(v_2);

%            P_f1
%            / \
% t_c1_P_f1 /   \ t_c2_P_f1
%          /     \
%        c1-------c2
%             t
%
% p_f1_1����ʾ3D����P_f1��c1����ϵ������
% c1����ʾ��һ�����
% c2����ʾ�ڶ������
% t_21_1��c1��c2֮���������c1ָ��c2��c1����ϵ��
% v1��c1��3D��P_f1֮��ĵ�λ������c1ָ��P_f1��c1����ϵ������t_c1_P_f1 = v1 * scale1
% v2��c2��3D��P_f1֮��ĵ�λ������c2ָ��P_f1��c2����ϵ������t_c2_P_f1 = C_12 * ��v2 * scale2��

% t_c1_P_f1 - t_c2_P_f1 = t
%                   |scale1|
% ===>[v1 -C_12*v_2]|scale2| = t_21_1
%
           A = [v_1 -C_12*v_2];
           b = t_21_1;

           scalar_consts = A\b;
           p_f1_1 = scalar_consts(1)*v_1;
    end

end

