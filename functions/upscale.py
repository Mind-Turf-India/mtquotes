
import sys
from PIL import Image
from basicsr.archs.rrdbnet_arch import RRDBNet
from realesrgan import RealESRGANer
import cv2
import numpy as np
import torch

def upscale(image_path, output_path):
    model = RRDBNet(num_in_ch=3, num_out_ch=3, num_feat=64,
                    num_block=23, num_grow_ch=32, scale=4)
    upsampler = RealESRGANer(
        scale=4,
        model_path='RealESRGAN_x4plus.pth',
        model=model,
        tile=0,
        tile_pad=10,
        pre_pad=0,
        half=False)

    img = cv2.imread(image_path, cv2.IMREAD_UNCHANGED)
    output, _ = upsampler.enhance(img, outscale=1)
    cv2.imwrite(output_path, output)

if __name__ == '__main__':
    img_in = sys.argv[1]
    img_out = sys.argv[2]
    upscale(img_in, img_out)
