#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import pymeshlab


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_mesh", type=str, help="input file")
    parser.add_argument("--padding", type=float, help="padding")
    parser.add_argument("--output_mesh", type=str, help="output file")
    args = parser.parse_args()

    ms = pymeshlab.MeshSet()
    ms.load_new_mesh(args.input_mesh)
    ms.generate_resampled_uniform_mesh(offset=pymeshlab.AbsoluteValue(args.padding), mergeclosevert=True)
    ms.save_current_mesh(args.output_mesh)

