import glob
import itertools
import operator
from pathlib import Path

import joblib
import mplbm_utils as mplbm
import numpy as np
import pyvista as pv
import vedo as vd

JOBLIB_CACHE = joblib.Memory(
    ".cache/joblib",
    verbose=1,
)


def get_velocity_files(tmp_folder):
    # Get all the density files
    vel_files_regex = rf"{tmp_folder}vtk_vel*.vti"
    vel_files = glob.glob(vel_files_regex)

    # Sort for correct order
    vel_files_list = sorted(vel_files)

    return vel_files_list


def visualize_medium(inputs):
    # input_folder = inputs["input output"]["input folder"]
    output_folder = inputs["input output"]["output folder"]
    nx = inputs["domain"]["domain size"]["nx"]
    ny = inputs["domain"]["domain size"]["ny"]
    nz = inputs["domain"]["domain size"]["nz"]
    n_slices = inputs["domain"]["inlet and outlet layers"]

    medium = pv.read(f"{output_folder}PorousMedium000001.vti")
    reshape_target = [nz, ny, nx + n_slices * 2]
    array_len = len(medium.get_array("tag"))
    print(dict(reshape_target=reshape_target, array_len=array_len, n_slices=n_slices))
    assert list(itertools.accumulate(reshape_target, operator.mul))[-1] == array_len
    grains = medium.get_array("tag").reshape(reshape_target)
    grains = grains[:, :, n_slices : nx + n_slices]
    grains = vd.Volume(grains).isosurface(0.5)

    return grains


def visualize_velocity(inputs, vel_file):
    nx = inputs["domain"]["domain size"]["nx"]
    ny = inputs["domain"]["domain size"]["ny"]
    nz = inputs["domain"]["domain size"]["nz"]
    n_slices = inputs["domain"]["inlet and outlet layers"]

    vel_mesh = pv.read(vel_file)
    print(vel_mesh.array_names)
    vel_mesh = vel_mesh.get_array("velocityNorm").reshape([nz, ny, nx + n_slices * 2])
    print(np.amax(vel_mesh), np.amin(vel_mesh))
    vel_mesh = vel_mesh[:, :, n_slices:nx]
    vel_thresholds = np.linspace(np.amin(vel_mesh), np.amax(vel_mesh), 20)
    vel = vd.Volume(vel_mesh).isosurface(vel_thresholds).decimate(0.1)

    return vel


def visualize_raw(inputs):
    # Get inputs
    raw_path = Path("input/").joinpath(inputs["geometry"]["file name"])
    assert raw_path.exists(), raw_path

    nx = inputs["domain"]["domain size"]["nx"]
    ny = inputs["domain"]["domain size"]["ny"]
    nz = inputs["domain"]["domain size"]["nz"]
    arr = np.fromfile(raw_path, dtype="uint8").reshape(nz, ny, nx, order="F")
    # arr = functools.reduce(
    #     lambda value, func: func(value),
    #     [
    #         functools.partial(np.flip, axis=2),
    #         functools.partial(np.flip, axis=),
    #         ],
    #     arr,
    # )
    # arr = np.flip(
    #     np.flip(np.fromfile(raw_path, dtype="uint8").reshape(nz, ny, nx), axis=2),
    #     axis=2,
    # )

    segmented_volume: vd.Mesh = vd.Volume(arr).isosurface().decimate(0.1)

    return segmented_volume


def main():
    # Get inputs
    input_file = "input.yml"
    inputs = mplbm.parse_input_file(input_file)  # Parse inputs
    # inputs["input output"][
    #     "simulation directory"
    # ] = os.getcwd()  # Store current working directory
    # inputs['domain']['inlet and outlet layers'] = 1
    # Get density files
    tmp_folder = inputs["input output"]["output folder"]
    vel_files_list = get_velocity_files(tmp_folder)

    index = -1  # Choose last simulation output

    # Setup plotter
    vp = vd.Plotter(axes=9, bg="w", bg2="w", size="auto", offscreen=False)

    # visualize raw
    raw = visualize_raw(inputs)
    vp.add(raw.lighting("glossy").phong().c("seashell").opacity(0.8))

    # visualize medium
    # grains = visualize_medium(inputs)
    # vp += grains.lighting('glossy').phong().c('seashell').opacity(0.2)

    # visualize velocity
    vel = visualize_velocity(inputs, vel_file=vel_files_list[index])
    vp.add(
        vel.cmap("turbo")
        .lighting("glossy")
        .opacity(0.6)
        .add_scalarbar("Velocity [LBM Units]")
    )  # .c('lightblue')

    # cam = dict(
    #     pos=(100.0, 100.0, 100.0),
    #     focalPoint=(0.0, 0.0, 0.0),
    #     viewup=(0.0, 0.0, 0.0),
    #     distance=0.0,
    #     clippingRange=(0.0, 0.0),
    # )
    # txt = vd.Text3D(__doc__, font="Bongas", s=350, c="red2", depth=0.05)
    # txt.pos(300, 300, 500)
    # vp.add(txt)

    # vp.show(axes=1)
    output_path_stem = Path(tmp_folder).joinpath(inputs["domain"]["geom name"])
    vp.export(output_path_stem.with_suffix(".x3d").as_posix(), binary=False)
    vp.export(output_path_stem.with_suffix(".npz").as_posix(), binary=False)
    # vp.show(camera=cam).screenshot(f'velocity_viz.png', scale=1)


if __name__ == "__main__":
    main()
