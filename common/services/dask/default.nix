{
  pkgs,
  ...
}:

let
  dask-env = [
    pkgs.gcc-unwrapped # TODO: why?
    (pkgs.python3.withPackages (
      ps: with ps; [
        bokeh
        dask
        distributed
        ipykernel
        ipython
        lz4
        pyarrow
      ]
    ))
    pkgs.lz4
  ];
in
{
  imports = [
    ./dask-scheduler.nix
    ./dask-worker.nix
  ];

  _module.args = {
    inherit dask-env;
  };
}
