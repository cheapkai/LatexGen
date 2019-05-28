import numpy as np
from skimage.color import rgb2gray
from skimage.io import imshow, imread
import matplotlib.pyplot as plt
from skimage.util import img_as_ubyte, img_as_float, img_as_bool
from skimage.filters import threshold_otsu, threshold_local, rank, gaussian
from skimage.morphology import binary_closing, binary_opening, binary_erosion, binary_dilation
from skimage.morphology import remove_small_objects, remove_small_holes
from skimage.morphology import disk, square
from skimage.transform import hough_line, hough_line_peaks, probabilistic_hough_line, rotate
from skimage.feature import canny
import cv2
import math

def binarize(img):
    """
        Thresholds and binarizes the given image and returns the binarized image.
    """
    
    gray_img = img_as_ubyte(rgb2gray(img))
    height, width = gray_img.shape
    num_mid_gray = np.sum((gray_img < 240) & (gray_img > 15))
    if num_mid_gray < 0.1 * height * width:
        # Global Thresholding
        thresh = threshold_otsu(gray_img)
        bw_img = gray_img > thresh

    else:
        # Adaptive Thresholding
        if height * width >= 2000 * 1000:
            gray_img = cv2.GaussianBlur(gray_img, ksize=(11, 11), sigmaX=3, sigmaY=3)
                
        # Set the window size of the filter based on image dimensions
        win_size = int(round(min(height/60, width/60)))
        
        # Get the window mean of each pixel by filtering using an averaging filter
        window_means = rank.mean(gray_img, np.ones((win_size, win_size)))
        print gray_img.dtype
        
        # Remove the mean and threshold. Also inverts the image.
        demeaned = window_means.astype(np.float32) - gray_img.astype(np.float32) - 10
        demeaned[demeaned > 0] = 1.0
        demeaned[demeaned <= 0] = 0.0
        demeaned = img_as_float(demeaned)
        bw_img = img_as_ubyte(demeaned)

        # Remove small noise pixels.
        noise_size = int(0.0001 * height * width)
        bw_img = remove_small_objects(img_as_bool(bw_img), noise_size, connectivity=2)
        
        # Close gaps in edges
        bw_img = binary_closing(bw_img, square(4))
        
        # Fill small holes (less than 5% of area of image)
        hole_size = int(0.0005 * height * width)
        bw_img = remove_small_holes(img_as_bool(bw_img), area_threshold=hole_size)
        
        # Return image to original polarity.
        bw_img = ~bw_img

    bw_img = img_as_ubyte(bw_img)
    # plt.figure()
    # plt.imshow(bw_img, cmap="gray")
    # plt.show()
    return bw_img

def skew_correct(im):
    im = ~im
    edges = canny(im, sigma=7)

    h, theta, d = hough_line(edges)
    h, theta, d = hough_line_peaks(h, theta, d, min_distance=0, min_angle=0, num_peaks=4)
    
    theta = [int(round(math.degrees(t))) for t in theta]
    if len(list(set(theta))) == 4:    
        dominant_orientation = theta[0]
    else:
        dominant_orientation = max(theta, key = theta.count)

    # The dominant orientation will be detected as the complement of the
    # skewing angle. Subtract 90 degrees to get the deskewing angle.
    # (Subtracting from 90 gets the skewing angle. Deskewing angle is the
    # negative of that.)
    deskewing_angle = dominant_orientation - 90
    print deskewing_angle

    # Limit angle  to -45  to 45
    while abs(deskewing_angle) > 45: 
        deskewing_angle = deskewing_angle - (abs(deskewing_angle)/deskewing_angle) * 90

    print deskewing_angle
    # Perform the deskewing
    deskew_img = rotate(im, deskewing_angle, mode='constant', cval=0, preserve_range=True, clip=True)
    
    deskew_img = deskew_img.astype(np.uint8)
    deskew_img = img_as_ubyte(deskew_img)

    # deskew_img = gaussian(deskew_img, sigma=0.4)
    deskew_img[deskew_img > 0] = 255
    deskew_img = img_as_bool(deskew_img)
    # deskew_img = binary_closing(deskew_img, square(5))
    deskew_img = ~deskew_img
    return deskew_img

for i in range(1, 10):
    if i == 4:
        continue
    im = imread('./Images/eq'+ str(i) + '_hr.jpg')
    thresh_im = binarize(im)
    thresh_and_deskew_im = skew_correct(thresh_im)

    plt.figure()
    plt.imshow(thresh_and_deskew_im, cmap="gray")
    plt.axis('off')
    plt.savefig("./Cleaned/eq" + str(i) + ".png", bbox_inches='tight')
    # plt.show()