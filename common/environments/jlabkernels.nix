{ pkgs, ... }:
pkgs.jupyter-kernel.create {
  definitions = {
    python313Kernel = (
      let
        env = pkgs.python313.withPackages (
          p: with p; [
            ipykernel
            dask-gateway
            numpy
            scipy
            pandas
            dask
            pip
            distributed
            torch
            torchvision
            scikit-learn
            plotly
            pyarrow
            beautifulsoup4
          ]
        );
      in
      {
        displayName = "Python 3.13 small-data-cluster";
        argv = [
          "${env.interpreter}"
          "-m"
          "ipykernel_launcher"
          "-f"
          "{connection_file}"
        ];
        language = "python";
        logo32 = "${env}/${env.sitePackages}/ipykernel/resources/logo-32x32.png";
        logo64 = "${env}/${env.sitePackages}/ipykernel/resources/logo-64x64.png";
      }
    );
  };
}
