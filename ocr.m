function [ eq_chars ] = ocr(eq_opt, X_orig, chars) 
    %% Segment Equation Characters and Create Identifer

    % SEGMENTATION
    figNum = 1;
    
    eq_inv = ones(size(eq_opt)) - eq_opt;
    
    se = ones(3,3);
    exp = imerode(eq_inv, se);
    eq_edges = xor(exp, eq_inv);
    
    s = regionprops(eq_edges, 'Centroid');
    ch = regionprops(eq_edges, 'ConvexHull');
    bb = regionprops(eq_edges, 'BoundingBox');
    imgs = regionprops(eq_edges, 'Image');
    loc = cat(1, s.Centroid);
    boundingboxes = cat(1, bb.BoundingBox);
    boundingboxes = floor(boundingboxes);
    boundingboxes(:,3:4) = boundingboxes(:,3:4) + 1;
    
    idx = [];
    for i = 1:size(loc, 1)
        poly = cat(1, ch(i).ConvexHull);
        x = poly(:,1)';
        y = poly(:,2)';
        for j = 1:size(ch,1)
            poly = cat(1, ch(j).ConvexHull);
            x_ch = poly(:,1)';
            y_ch = poly(:,2)';
            if((sum(~inpolygon(x,y,x_ch,y_ch)) == 0) && i ~= j)
               
                BB_outer = boundingboxes(j,:);
                BB_inner = boundingboxes(i,:);
                BB_inner(1) = BB_inner(1) - BB_outer(1);
                BB_inner(2) = BB_inner(2) - BB_outer(2);
    
                outer = imgs(j).Image;
                up = sum(outer(1:BB_inner(2)+BB_inner(4), ...
                    BB_inner(1):(BB_inner(1)+BB_inner(3))),1);
                down = sum(outer(BB_inner(2):end,...
                    BB_inner(1):(BB_inner(1)+BB_inner(3))),1);
                left = sum(outer(BB_inner(2):(BB_inner(2)+BB_inner(4)),...
                    1:BB_inner(1)+BB_inner(3)),2);
                right = sum(outer(BB_inner(2):(BB_inner(2)+BB_inner(4)),...
                    BB_inner(1):end),2);
                
                if((sum(up(:)==0) + sum(down(:)==0) + sum(left(:)==0)...
                        + sum(right(:)==0)) == 0)
                    idx = [idx i];
                end
            end
        end
    end
    idx = unique(idx);
    if(~isempty(idx))
        for i = size(idx,2):-1:1
            loc(idx(i),:)=[];
            ch(idx(i))=[];
            boundingboxes(idx(i),:)=[];
            imgs(idx(i))=[];
        end
    end
    
    eq_chars(size(loc,1)).centroid = [];
    
    for i = 1 : size(loc,1)
        eq_chars(i).centroid = loc(i,:);
        eq_chars(i).boundingbox = boundingboxes(i,:);
        
        region = eq_inv(boundingboxes(i,2):boundingboxes(i,2)+boundingboxes(i,4),...
            boundingboxes(i,1):boundingboxes(i,1)+boundingboxes(i,3),:);
        objects = bwconncomp(region);
        if(size(objects.PixelIdxList,2) > 1)
            numPixels = cellfun(@numel,objects.PixelIdxList);
            [~,idx] = max(numPixels);
           region(:) = 1;
           region(objects.PixelIdxList{idx}) = 0;
           eq_chars(i).img = region;
        else
            eq_chars(i).img = eq_opt(boundingboxes(i,2):boundingboxes(i,2)+boundingboxes(i,4),...
            boundingboxes(i,1):boundingboxes(i,1)+boundingboxes(i,3),:);
        end
        
        % sqroot
        th_ratio = 1; % Threshold for ratio of wdith to height. 
        th_sol = .2;
        sqrt_ratio = 0.7812; % Determined from squareroot template
        ratio = boundingboxes(i,3) / boundingboxes(i,4);
        sol = regionprops(ones(size(eq_chars(i).img))-eq_chars(i).img,...
                'solidity');
        % If meets criteria for squareroot, crop image
        if(ratio > th_ratio && sol.Solidity < th_sol)
            new_w = round(boundingboxes(i,4) * sqrt_ratio);
            eq_chars(i).img = eq_chars(i).img(:,1:new_w);
            % Trim top part of squareroot off
            idx = find(~eq_chars(i).img(:,end));
            last = idx(end);
            eq_chars(i).img = eq_chars(i).img(last+1:end,:);
        end
    end
    
    figure(figNum);
    imshow(eq_edges);
    for i = 1:size(loc, 1) % Assumes same # centroid and convex hull
        % Plot centroids
        x = loc(i,1);
        y = loc(i,2);
        text(x, y, '*' ,'Color', 'yellow', 'FontSize', 14);
        % Plot Convex Hull
        poly = cat(1, ch(i).ConvexHull);
        x = poly(:,1)';
        y = poly(:,2)';
        hold on;
        plot([x x(1)],[y y(1)],'r-');
        hold off;
        rectangle('position',boundingboxes(i,:),'Edgecolor','g')
    end
    
    figure(figNum + 1);
    for i =1:size(eq_chars,2)
        dim = ceil(sqrt(size(eq_chars,2)));
        subplot(dim, dim,i);
        imshow(eq_chars(i).img);
        title(sprintf('%d',i));
    end

    for i = 1:length(eq_chars)
    eq_chars(i).ident = fn_createIdent(eq_chars(i).img); 
    end

    for i = 1:length(eq_chars)
        idx_matched = knnsearch(X_orig(:,1:length(chars(1).ident)),eq_chars(i).ident,'distance','cityblock');
        eq_chars(i).char = chars(X_orig(idx_matched,end)).char;
        
        figure(6);
        subplot(2,length(eq_chars),i);
        imshow(eq_chars(i).img);
        title('Input');
        subplot(2,length(eq_chars),i+length(eq_chars));
        imshow(chars(X_orig(idx_matched,end)).img);
        if(eq_chars(i).char(1) == '\')
            printChar = strcat('\',eq_chars(i).char);
        else
        printChar = eq_chars(i).char;
        end
        str = sprintf('Match: %s',printChar);
        title(str);
    end
end