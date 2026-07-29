{
  pkgs,
  packages,
  docsRoot ? "docs",
  outputRoot ? "build/docs",
}:
# Maybe we should expose the renderd docs as a nix package itself rather then doing it like this
pkgs.writeShellApplication {
  name = "render-docs";

  runtimeInputs = packages;

  text = ''
    set -euo pipefail

    docs_root="''${DOCS_ROOT:-${docsRoot}}"
    output_root="''${OUTPUT_ROOT:-${outputRoot}}"
    defaults_file="$docs_root/defaults.yaml"

    if [[ ! -d "$docs_root" ]]; then
      echo "Documentation directory not found: $docs_root" >&2
      exit 1
    fi

    if [[ ! -f "$defaults_file" ]]; then
      echo "Pandoc defaults file not found: $defaults_file" >&2
      exit 1
    fi

    mkdir -p "$output_root"

    render_directory() {
      local source_directory="$1"
      local document_name
      local output_file
      local metadata_file
      local resource_path
      local -a markdown_files
      local -a pandoc_options

      document_name="$(basename "$source_directory")"
      output_file="$output_root/$document_name.pdf"
      metadata_file="$source_directory/metadata.yaml"
      resource_path="$source_directory:$docs_root:."

      mapfile -d $'\0' markdown_files < <(
        find "$source_directory" \
          -type f \
          -name '*.md' \
          -print0 |
          sort -z
      )

      if [[ "''${#markdown_files[@]}" -eq 0 ]]; then
        echo "Skipping $source_directory: no Markdown files found" >&2
        return
      fi

      pandoc_options=(
        "--defaults=$defaults_file"
        "--resource-path=$resource_path"
        "--output=$output_file"
      )

      if [[ -f "$metadata_file" ]]; then
        pandoc_options+=("--metadata-file=$metadata_file")
      fi

      echo "Rendering $output_file"

      pandoc \
        "''${pandoc_options[@]}" \
        "''${markdown_files[@]}"
    }

    if [[ "$#" -gt 0 ]]; then
      for document in "$@"; do
        source_directory="$docs_root/$document"

        if [[ ! -d "$source_directory" ]]; then
          echo "Documentation set not found: $source_directory" >&2
          exit 1
        fi

        render_directory "$source_directory"
      done
    else
      while IFS= read -r -d $'\0' source_directory; do
        render_directory "$source_directory"
      done < <(
        find "$docs_root" \
          -mindepth 1 \
          -maxdepth 1 \
          -type d \
          -print0 |
          sort -z
      )
    fi
  '';
}
