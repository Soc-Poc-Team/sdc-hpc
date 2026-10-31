{
  writeShellScriptBin,
  openssh,
  jq,
  sops,
  userConfig,
}:
let
  ssh-keygen = "${openssh}/bin/ssh-keygen";
  jqBin = "${jq}/bin/jq";
  sopsBin = "${sops}/bin/sops";
in
writeShellScriptBin "sdc-keygen" ''
  set -euo pipefail

  one_line=false
  write_sops=false

  while (( $# > 0 )); do
    case "$1" in
      -o|--one-line)
        one_line=true
        ;;
      -s|--sops)
        write_sops=true
        ;;
      --)
        shift
        break
        ;;
      *)
        printf 'Unknown option: %s\n' "$1" >&2
        exit 2
        ;;
    esac
    shift
  done

  if (( $# > 0 )); then
    printf 'Unexpected argument: %s\n' "$1" >&2
    exit 2
  fi

  generate_key() {
    # https://gist.github.com/kraftb/9918106?permalink_comment_id=4349155#gistcomment-4349155
    (exec 3>&1; ${ssh-keygen} -qt ed25519 -N "" -f /proc/self/fd/3 -C "root@headnode.${userConfig.tailscale.domain}" <<<y >/dev/null 2>&1) || {
      status=$?
      [[ "$status" -eq 255 ]] || return "$status"
    }
  }

  if "$write_sops"; then
    secrets_file="secrets/''${USER}.json"

    generate_key |
      ${jqBin} -Rs |
      ${sopsBin} set \
        --value-stdin \
        "$secrets_file" \
        '["headnode"]["private_ssh_key"]'
  elif "$one_line"; then
    generate_key | ${jqBin} -Rs
  else
    generate_key
  fi
''
