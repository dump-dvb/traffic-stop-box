{ pkgs, config, lib, ... }:
let
  jupyterUsers = [
    {
      username = "0xa";
      userPasswordFile = config.sops.secrets.hashed-password-0xa.path;
      isAdmin = true;
    }
  ];

  # move the secrets to the volume
  secret-setup = (lib.strings.concatStringsSep "\n" (builtins.map (u: "cp --force --dereference ${u.userPasswordFile} /var/lib/pw/") jupyterUsers));
in
{
  sops.secrets.hashed-password-0xa = { };

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
        "/var/lib/pw:/pw"
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
        in
        (import ./jupyter-container.nix {
          inherit pkgs lib jupyterUsers packages;
        });
      image = "stateful-jupyterlab";
    };
  };

  systemd.services.setup-docker-pws = {
    description = "copy the user passwords to docker volume";
    wantedBy = [ "jupyterlab-stateful.service" ];
    serviceConfig.type = "oneshot";
    script = secret-setup;
  };

}
