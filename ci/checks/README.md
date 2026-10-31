# Checks Directory

This directory contains `.check.sh` scripts that analyze the SDC repository.

Each script is executed as a separate job in the `check` stage of the CI
pipeline.

A check that exits with a non-zero status causes the pipeline to fail. Exit with
status code `2` to report a warning while allowing the pipeline to continue.

Scripts are executed with the repository root as their working directory.

The first comment line after the shebang, when present, is used as the job name.
