function [ identifier ] = fn_createIdent(char)
k = 8;
identifier = zeros(1,2*k+6);

char_inv = ones(size(char)) - char;

pad = 3;
% top
if(sum(char_inv(1,:)) == 0)
    char = [ones(pad,size(char,2)) ;char];
end
% bottom
if(sum(char_inv(end,:)) == 0)
    char = [char; ones(pad,size(char,2))];
end
% left
if(sum(char_inv(:,1)) == 0)
    char = [ones(size(char,1),pad) char];
end
% right
if(sum(char_inv(:,end)) == 0)
    char = [char ones(size(char,1),pad)];
end
% Recalculate for centroid
char_inv = ones(size(char)) - char;

N = sum(~char(:));
[y, x] = find(~char);

cent = regionprops(char_inv,'centroid');
cent = cat(1, cent.Centroid);
cent_x = cent(1);
cent_y = cent(2);

I = sum((x - cent_x).^2 + (y - cent_y).^2);
IN2 = I / N^2;
identifier(1) = IN2;

y = size(char,1);
x = size(char,2);
dr = max(max(x - cent_x,cent_x), max(y - cent_y,cent_y)) / (k+1);
[c, r] = meshgrid(1:x, 1:y);

tempcirc = char;

coding(k).circVec=[];
for i = 1:k
    rad = dr * i;
    C = xor(sqrt((c-cent_x).^2+(r-cent_y).^2)<=rad, ...
        sqrt((c-cent_x).^2+(r-cent_y).^2)<=(rad-1));
    cidx = find(C);
    vals = [cidx c(cidx)-cent_x r(cidx)-cent_y zeros(size(cidx,1),1)];
    [TH, ~] = cart2pol(vals(:,2), vals(:,3));
    vals(:,4) = TH;
    [~, order] = sort(vals(:,4));
    sortedvals = vals(order,:);
    circVec = char(sortedvals(:,1));
    
    tempcirc(C) = .5;
    
    circVec = imopen(circVec,ones(2,1));
    
    coding(i).circ = circVec;
    
    if(~isempty(circVec))
        cnt = strfind([1 1 circVec'],[0 0]);
        coding(i).count = length(cnt(diff([1 cnt])~=1));

        identifier(1+i) = coding(i).count;
        str = sprintf('%d',coding(i).count);

        circ = length(circVec);
        if(circVec(1) == 1 && circVec(end) == 1)
            idx = find(circVec==0,1,'last');
            circVec = [circVec(idx+1:end); circVec(1:idx)];
        end
        B = [0 circVec' 0]; % Pad with 0s for diff
        bgrd_len = find(diff(B)==-1) - find(diff(B)==1);
        if(coding(i).count < 1);
            d2 = 0;
            d1 = 0;
        else
            [d2, idx_d2] = max(bgrd_len);
            bgrd_len(idx_d2)=NaN;
            d1 = max(bgrd_len);
        end
        coding(i).ratio = (d2-d1) / circ;
        if(i > 1) % Only keep k-1 largest ratios
            if(~isnan(coding(i).ratio))
                identifier(k+i) = coding(i).ratio;
            end
        end
    end
end

eta_mat = SI_Moment(char_inv) ;

inv_moments(1) = eta_mat(3,1) + eta_mat(1,3);
inv_moments(2) = (eta_mat(3,1) - eta_mat(1,3))^2 + (4*eta_mat(2,2)^2);
inv_moments(3) = (eta_mat(4,1) - 3*eta_mat(2,3))^2 + (3*eta_mat(3,2) - eta_mat(1,4))^2;
inv_moments(4) = (eta_mat(4,1) + eta_mat(2,3))^2 + (eta_mat(3,1) + eta_mat(1,4))^2;
inv_moments(5) = (eta_mat(4,1) - 3*eta_mat(2,3))*(eta_mat(4,1) + eta_mat(2,3))*((eta_mat(4,1) + eta_mat(2,3))^2 - 3*((eta_mat(3,2) + eta_mat(1,4))^2)) + (3*(eta_mat(3,2) - eta_mat(1,4)))*(eta_mat(3,2) + eta_mat(1,4))*(3*(eta_mat(4,1) + eta_mat(2,3))^2 - (eta_mat(3,2) + eta_mat(1,4))^2);
inv_moments(6) = (eta_mat(3,1) - eta_mat(1,3))*((eta_mat(4,1)+eta_mat(2,3))^2 - (eta_mat(3,2)+ eta_mat(1,4))^2) + 4*eta_mat(2,2)*((eta_mat(4,1) + eta_mat(2,3))*(eta_mat(3,2) + eta_mat(1,4)));
inv_moments(7) = (3*eta_mat(3,2) - eta_mat(1,4))*(eta_mat(4,1) + eta_mat(2,3))*((eta_mat(4,1) + eta_mat(2,3))^2 - 3*(eta_mat(3,2)-eta_mat(1,4))^2) - (eta_mat(4,1) - 3*eta_mat(2,3))*(eta_mat(3,2) + eta_mat(1,4))*(3*(eta_mat(4,1) + eta_mat(2,3))^2 - (eta_mat(3,2) + eta_mat(1,4))^2);

identifier(2*k+1:end) = inv_moments(2:end);

end


