from skimage.io import imshow, imread
import numpy as np
from numpy import sum, unique
import matplotlib.pyplot as plt
from matplotlib import path
from matplotlib.path import Path
from skimage.util import img_as_bool, img_as_ubyte, img_as_float64
from skimage.color import rgb2gray
from skimage.filters import threshold_otsu
from numpy import ones
from skimage.morphology import binary_erosion
from skimage.measure import label, regionprops
from math import floor
# Step 1: Character Segmentation
# This function simply creates an edge map of non-contiguous characters (same size as original) 
# and then finds the centroid, convex hull, and bounding boxes which are then used for extraction.
def segmentation(im_seg):

    im_seg_bool = img_as_bool(im_seg)
    im_inv = ~(im_seg_bool)
    plt.figure()
    plt.imshow(im_inv, cmap="gray")
    plt.show()

    se = ones((3,3))
    exp = binary_erosion(im_inv, se)
    eq_edges = exp ^ im_inv
    plt.figure()
    plt.imshow(eq_edges, cmap="gray")
    plt.show()

    lab = label(eq_edges, neighbors=8)
    reg = regionprops(lab)
    print len(reg)
    s = [item.centroid for item in reg]
    ch = [item.convex_image for item in reg]
    bb = [item.bbox for item in reg]
    imgs = [item.image for item in reg]
    bb = floor(bb)
    bb[:,2:4] = bb[:,2:4] + 1

    idx = []
    for i in len(s):
        x = ch[:i+1,1]
        y = ch[:i+1,2]
        for j in len(ch):
            x_ch = ch[:j+1,1]
            y_ch = ch[:j+1,1]
            
            p = Path([(x_ch, y_ch)])  # square with legs length 1 and bottom left corner at the origin
           
            if (sum(~ p.contains_points([(x,y)]) == 0)) and (i != j):
                BB_outer


img = imread("./Cleaned/eq1.png")
img = img_as_ubyte(rgb2gray(img))
segmentation(img)