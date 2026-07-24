{ writeShellScriptBin, openssh }:
let
  ssh-keygen = "${openssh}/bin/ssh-keygen";
in
writeShellScriptBin "sdc-keygen" ''
  set -euo pipefail
  # https://gist.github.com/kraftb/9918106?permalink_comment_id=4349155#gistcomment-4349155
  (exec 3>&1 ; ${ssh-keygen} -qt ed25519 -N "" -f /proc/self/fd/3 <<<y >/dev/null 2>&1)
''
