{
  writeShellScriptBin,
  openssh,
  jq,
}:
let
  ssh-keygen = "${openssh}/bin/ssh-keygen";
  jqBin = "${jq}/bin/jq";
in
writeShellScriptBin "sdc-keygen" ''
  set -euo pipefail

  one_line=false

  while (( $# > 0 )); do
    case "$1" in
      -o|--one-line)
        one_line=true
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
    (exec 3>&1; ${ssh-keygen} -qt ed25519 -N "" -f /proc/self/fd/3 <<<y >/dev/null 2>&1)
  }

  if "$one_line"; then
    generate_key | ${jqBin} -Rs
  else
    generate_key
  fi
''
