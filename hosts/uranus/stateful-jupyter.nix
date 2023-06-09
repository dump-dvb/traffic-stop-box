{ pkgs, lib, ... }:
{
  virtualisation.docker = {
    enable = true;
    # magic from marenz to make it work on ceph
    storageDriver = "devicemapper";
    extraOptions = "--storage-opt dm.basesize=40G --storage-opt dm.fs=xfs";
  };
  systemd.enableUnifiedCgroupHierarchy = false;

  # user to run the thing
  # jupyterlab container
  virtualisation.oci-containers = {
    backend = "docker";
    containers."jupyterlab-stateful" = {
      autoStart = true;
      ports = [ "8080:8080" ];
      volumes = [
        "/var/lib/jupyter-volume:/workdir"
        "/var/lib/root-home:/root"
        # "/var/lib/conda-persist:/opt/conda"
      ];
      imageFile =
        let
          packages = lib.concatStringsSep " " [
            # alphabetically `:sort`ed plz
            "geojson"
            "matplotlib"
            "numpy"
            "pandas"
            "pip"
            "psycopg"
            "scipy"
            "seaborn"
            "bitstring"
          ];
          jupyterUsers = [
            {
              username = "0xa";
              hashedPassword = "$y$j9T$vXyoscuYL2CUGnSXLBpw51$4TH60t.zpNwkb23jt/oEZSJDLxGaSni54sJxn1TXDfA"; # just a test, plz ignore
              isAdmin = true;
            }
          ];
        in
        (import ./jupyter-container.nix {
          inherit pkgs lib jupyterUsers packages;
        });
      image = "stateful-jupyterlab";
    };
  };

}
