% clear
clf
clc

% ��� ����barDw����ĳߴ������������Ӧ��ϵ
rulerLengths = [23,45,18,18,36,14,14,28,12,24,24];
barLengths = [100 100 20 10 10 2 1 1 0.2 0.2 0.2];

% % ����UTF-8�����miu ����https://codepoints.net/
miu = native2unicode([hex2dec('CE') hex2dec('BC')],'UTF-8'); 
um_str = [' ', miu, 'm'];
barDw = {['100', um_str], ['100', um_str], ['20', um_str], ['10', um_str], ['10', um_str], ['2', um_str], ['1', um_str], ['1', um_str], '200 nm', '200 nm', '200 nm'};
 
% ͼ��·�� ·����Ҫ�����ư���50.tif 100.tif 200.tif ... 25600.tif �������ļ� ע�����ķ�б��
imgNameStr = 'D:\cbh_workspace\MatlabCode\Others\Zoom-In����\7month\UDT-1\';


% sift+ransac���� ���ȱ�֤������vl_sift��
preImg = imread([imgNameStr, num2str(25600), '.tif']);
preImg = imresize(preImg, 0.25);
n = 0;
for j=size(imgNameList, 2)-1:-1:1
    n = n+1;
    preImgs{n} = preImg;
    
    oriImg = imread([imgNameStr, num2str(imgNameList(j)), '.tif']);
    nowImg = oriImg(2049:6144,2049:6144);
    oriImg = imresize(oriImg, 0.25); % 2048��С
    nowImg = imresize(nowImg, 0.5); % 2048��С
    
    [fa1, da1] = vl_sift(single(preImg),'PeakThresh',4.5);
    [fa2, da2] = vl_sift(single(nowImg),'PeakThresh',4.5);
    [matches,~] = vl_ubcmatch(da1, da2, 3.5) ; 
    numMatches = size(matches,2); 
    if numMatches<4   
        matches_final = [];
        warning('too small');
        return;
    end
    X1 = fa1(1:2,matches(1,:)) ; 
    X1(3,:) = 1 ;   
    X2 = fa2(1:2,matches(2,:)) ;
    X2(3,:) = 1 ;
    clear H score ok ;   
    for t = 1:10000
        subset = vl_colsubset(1:numMatches, 4);
        A = [] ;
        for i = subset
            A = cat(1, A, kron(X1(:,i)', vl_hat(X2(:,i)))) ; 
        end
        [U,S,V] = svd(A) ;  
        H{t} = reshape(V(:,9),3,3) ;  
        X2_ = H{t} * X1 ;
        du = X2_(1,:)./X2_(3,:) - X2(1,:)./X2(3,:) ;
        dv = X2_(2,:)./X2_(3,:) - X2(2,:)./X2(3,:) ;
        ok{t} = (du.*du + dv.*dv) < 6*6 ;
        score(t) = sum(ok{t}) ;
    end
    [score, best] = max(score) ;
    ok = ok{best} ;
    matches_final = matches(:,ok);
    matchedPoints1 = fa1(1:2,matches_final(1,:))';
    matchedPoints2 = fa2(1:2,matches_final(2,:))';     
    tform = estimateGeometricTransform(matchedPoints2, matchedPoints1, 'affine');
    preImg = imtranslate(oriImg, [tform.T(3,1)/2 tform.T(3,2)/2], 'OutputView', 'same');
end
n = n+1;
preImgs{n} = preImg;

preImg = preImgs{10};
bigsize = 2048;
smallsize = 1024;

upleft = round(sqrt(exp(log(bigsize^2) : -(log(bigsize^2)-log(smallsize^2))/60 : log(smallsize^2))));

v = VideoWriter('draw3_7_test_4.avi', 'Motion JPEG AVI'); % �趨���ơ���ʽ
v.FrameRate = 25;
open(v)

% �ַ���ɫ
text_color = 'white';
% ��ɫ����Ӱ
if strcmp(text_color, 'white')
    reverse_text_color = 'black';
else
    reverse_text_color = 'white';
end

% scale bar ��ɫ
color = 'white';
isfirst = true;
for i=size(imgNameList, 2)-1:-1:1
    k = size(imgNameList, 2)-i;
    if k > 0 % �޸������k��������С�����ļ���ͼ�� ���ڼ�������������
        center = size(upleft, 2) / 2;
        fdbs = imgNameList(k) : (imgNameList(k+1)-imgNameList(k))/60 : imgNameList(k+1);

        % �����ߵĵ�λ�Ƿ���Ҫ����  ����¸����ȱȵ�ǰ�ĳ��ȳ� ��Ϊ��ͬһ����λ��
        if rulerLengths(k+1) > rulerLengths(k)
            aRLt = rulerLengths(k):(rulerLengths(k+1)-rulerLengths(k))/60:rulerLengths(k+1);
            b1fp = Inf;
        else
            % ����ǵȳ��� ����С�Ļ� ˵�������˵�λ�ı仯
            tmps = rulerLengths(k);
            tmpt = rulerLengths(k+1)*barLengths(k)/barLengths(k+1);
            tmpl = tmpt-tmps;
            tmpp = tmps:tmpl/60:tmpt;
            b1fp = find(tmpp>46, 1); % 46��������Ƶ�������scaleBar�ж�����ص�λ��
            tmpp(b1fp:end) = tmpp(b1fp:end) ./ (barLengths(k)/barLengths(k+1));
            aRLt = tmpp;
        end

        for j=2:size(upleft,2)
            tflame = preImg(1024+1-upleft(j)/2:1024+upleft(j)/2,...
                            1024+1-upleft(j)/2:1024+upleft(j)/2);
            rtf = imresize(tflame, [512 NaN]);
            rtf = rtf(41:512-40, 41:512-40);

            fdPosX = 330;
            fdPosY = 10;
            
            % �˴������� �ظ��Ĳ��־���Ϊ���ʵ��ļӴ����� ����ͬ��
            
            % �ӷŴ���
                % ��Ӱ
    %         rtf = insertText(rtf, [fdPosX+2 fdPosY],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',reverse_text_color);
    %         rtf = insertText(rtf, [fdPosX-2 fdPosY],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',reverse_text_color);
    %         rtf = insertText(rtf, [fdPosX fdPosY+2],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',reverse_text_color);
    %         rtf = insertText(rtf, [fdPosX fdPosY-2],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',reverse_text_color);
    %         
    %         rtf = insertText(rtf, [fdPosX+3 fdPosY-2],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',reverse_text_color);
    %         rtf = insertText(rtf, [fdPosX+3 fdPosY+3],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',reverse_text_color);
    %         rtf = insertText(rtf, [fdPosX-2 fdPosY-2],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',reverse_text_color);
    %         rtf = insertText(rtf, [fdPosX-2 fdPosY+3],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',reverse_text_color);
    %        
    %         rtf = insertText(rtf, [fdPosX+2 fdPosY-2],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',reverse_text_color);
    %         rtf = insertText(rtf, [fdPosX+2 fdPosY+2],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',reverse_text_color);
    %         rtf = insertText(rtf, [fdPosX-2 fdPosY-2],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',reverse_text_color);
    %         rtf = insertText(rtf, [fdPosX-2 fdPosY+2],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',reverse_text_color);

                % �Ӵֵĺ�ɫ����
                if isfirst
                     rtf = insertText(rtf, [fdPosX fdPosY], ...
                ['x ', num2str(200)], 'Font', 'Microsoft YaHei', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',text_color);
                else
            rtf = insertText(rtf, [fdPosX fdPosY], ...
                ['x ', num2str(floor(fdbs(j)))], 'Font', 'Microsoft YaHei', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',text_color);
                end
            %         rtf = insertText(rtf, [fdPosX fdPosY+1],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',text_color);
    %         rtf = insertText(rtf, [fdPosX+1 fdPosY],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',text_color);
    %         rtf = insertText(rtf, [fdPosX+1 fdPosY+1],... % �����λ��
    %             ['x ', num2str(floor(fdbs(j)))], 'Font', 'Arial', 'FontSize',20,'BoxColor','green','BoxOpacity',0,'TextColor',text_color);


            % ��scaleBar
    %         rtf = insertShape(rtf, 'FilledRectangle', [330 410 aRLt(j) 5], ...
    %             'Color', 'black', 'SmoothEdges', false, 'Opacity', 1);


            textPosX = 320;
            textPosY = 375;
            insertedText = barDw{k};
            if j >= b1fp
                insertedText = barDw{k+1};
            end

            % ��ɫ����Ӱ
            if strcmp(color, 'white')
                reverse_color = 'black';
            else
                reverse_color = 'white';
            end

    %         rtf = insertText(rtf, [textPosX+3 textPosY],...
    %                 insertedText,...
    %                 'Font', 'Arial', 'FontSize',18,'TextColor', reverse_color, 'BoxOpacity', 0);
    %         rtf = insertText(rtf, [textPosX-2 textPosY],...
    %                 insertedText,...
    %                 'Font', 'Arial', 'FontSize',18,'TextColor', reverse_color, 'BoxOpacity', 0);
    %         rtf = insertText(rtf, [textPosX textPosY+3],...
    %                 insertedText,...
    %                 'Font', 'Arial', 'FontSize',18,'TextColor', reverse_color, 'BoxOpacity', 0);
    %         rtf = insertText(rtf, [textPosX textPosY-2],...
    %                 insertedText,...
    %                 'Font', 'Arial', 'FontSize',18,'TextColor', reverse_color, 'BoxOpacity', 0);
    %         
    %         rtf = insertText(rtf, [textPosX+3 textPosY-2],...
    %                 insertedText,...
    %                 'Font', 'Arial', 'FontSize',18,'TextColor', reverse_color, 'BoxOpacity', 0);
    %         rtf = insertText(rtf, [textPosX+3 textPosY+3],...
    %                 insertedText,...
    %                 'Font', 'Arial', 'FontSize',18,'TextColor', reverse_color, 'BoxOpacity', 0);
    %         rtf = insertText(rtf, [textPosX-2 textPosY-2],...
    %                 insertedText,...
    %                 'Font', 'Arial', 'FontSize',18,'TextColor', reverse_color, 'BoxOpacity', 0);
    %         rtf = insertText(rtf, [textPosX+3 textPosY+3],...
    %                 insertedText,...
    %                 'Font', 'Arial', 'FontSize',18,'TextColor', reverse_color, 'BoxOpacity', 0);
    %         
    %             
    %         rtf = insertShape(rtf, 'Line',...
    %             [330-2 410 330+round(aRLt(j))+2 410],...
    %             'Color', reverse_color, 'SmoothEdges', false, 'Opacity', 1, 'LineWidth', 6);      



            rtf = insertText(rtf, [textPosX textPosY],...
                    insertedText,...
                    'Font', 'Microsoft YaHei', 'FontSize',18,'TextColor', color, 'BoxOpacity', 0);
    %         rtf = insertText(rtf, [textPosX textPosY+1],...
    %                 insertedText,...
    %                 'Font', 'Arial', 'FontSize',18,'TextColor', color, 'BoxOpacity', 0);
    %         rtf = insertText(rtf, [textPosX+1 textPosY],...
    %                 insertedText,...
    %                 'Font', 'Arial', 'FontSize',18,'TextColor', color, 'BoxOpacity', 0);
    %         rtf = insertText(rtf, [textPosX+1 textPosY+1],...
    %                 insertedText,...
    %                 'Font', 'Arial', 'FontSize',18,'TextColor', color, 'BoxOpacity', 0);

            rtf = insertShape(rtf, 'Line',...
                [330 410 330+round(aRLt(j)) 410],...
                'Color', color, 'SmoothEdges', false, 'Opacity', 1, 'LineWidth', 3);   

            imshow(rtf)

            if isfirst
                isfirst = false;
                for t=1:50
                    writeVideo(v, rtf);
                end
            else
                writeVideo(v, rtf)
            end

        end
    end
    preImg = preImgs{i};
end

for i=1:50
    writeVideo(v, rtf);
end

close(v);

