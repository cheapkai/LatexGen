function cen_mmt = Centr_Moment(image,mask,p,q)
if ~exist('mask','var')
    mask = ones(size(image,1),size(image,2)); %if mask is not spcified, select the whole image
end

image = double(image);

%moments necessary to compute components of centroid
m10=0; 
m01=0;
m00=0;
for i=1:1:size(mask,1)
    for j=1:1:size(mask,2)
        if mask(i,j) == 1
            m10 = m10 + (double((image(i,j))*(i^1)*(j^0)));
            m01 = m01 + (double((image(i,j))*(i^0)*(j^1)));
            m00 = m00 + (double((image(i,j))*(i^0)*(j^0)));
        end
    end
end

%components of centroid
x_cen = floor(m10/m00);
y_cen = floor(m01/m00);

cen_mmt =0;

for i=1:1:size(mask,1)
    for j=1:1:size(mask,2)
        if mask(i,j) == 1
            cen_mmt = cen_mmt + (double(image(i,j))*((i-x_cen)^p)*((j-y_cen)^q)); %calculating central moment
        end
    end
end
