#!/usr/bin/env bash
# Validate GitHub workflow YAML and embedded shell run blocks.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if (( $# == 0 )); then
  set -- .github/workflows/build.yml .github/workflows/release.yml
fi

if command -v actionlint >/dev/null 2>&1; then
  actionlint "$@"
  echo "ACTIONLINT OK"
else
  echo "SKIP: actionlint not available"
fi

ruby -ryaml -rtempfile - "$@" <<'RUBY'
ARGV.each do |workflow|
  data = YAML.load_file(workflow)
  puts "YAML OK: #{workflow}"

  data.fetch("jobs").each do |job_name, job|
    Array(job["steps"]).each_with_index do |step, index|
      run = step["run"]
      next unless run

      Tempfile.create(["gha-run-", ".sh"]) do |file|
        file.write(run)
        file.flush
        ok = system("bash", "-n", file.path)
        raise "bash -n failed for #{workflow} job #{job_name} step #{index + 1}" unless ok
      end

      puts "RUN SHELL OK: #{workflow} job #{job_name} step #{index + 1}"
    end
  end
end
RUBY
