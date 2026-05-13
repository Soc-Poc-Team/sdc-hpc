{ pkgs, ... }:
pkgs.jupyter-kernel.create {
  definitions = {
    python312Kernel = (
      let
        env = pkgs.python312.withPackages (
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
            # tensorflow #error: tensorflow-2.13.0 not supported for interpreter python3.12
            # keras #error: tensorflow-2.13.0 not supported for interpreter python3.12
            #matplotlib
            scikit-learn
            skorch
            plotly
            pyarrow
            beautifulsoup4
          ]
        );
      in
      {
        displayName = "Python 3.12 small-data-cluster";
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
