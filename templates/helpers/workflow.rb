require "erb"
require "yaml"

@workflow_repo_dir = ENV.fetch("TEAM_WORKFLOWS_REPO_DIR")

def resolve_repo_file(relative_path)
  path = File.expand_path(relative_path, @workflow_repo_dir)
  File.exist?(path) ? path : nil
end

def render_partial(relative_path, locals = {})
  partial_path = resolve_repo_file(relative_path)
  raise "Missing partial: #{relative_path}" unless partial_path

  template = File.read(partial_path)
  context = binding
  locals.each { |key, value| context.local_variable_set(key, value) }
  ERB.new(template, trim_mode: "-", eoutvar: "_partial_erbout").result(context)
end

def include_script(relative_path, locals = {})
  script = render_partial(relative_path, locals)
  lines = script.lines.map(&:strip).reject(&:empty?)
  return "" if lines.empty?

  output = +""
  lines.each_with_index do |line, index|
    output << line
    next if index == lines.length - 1

    if line.match?(/(then|do|else|\{)\s*$/)
      output << " "
    else
      output << "; "
    end
  end

  output
end

def bash_single_quote(value)
  value.to_s.gsub("'", %q('"'"'))
end

def include_script_for_bash(relative_path, locals = {})
  bash_single_quote(include_script(relative_path, locals))
end

def include_yaml(relative_path, locals = {})
  render_partial(relative_path, locals)
end

def include_pre_window(name, locals = {})
  include_script_for_bash("templates/partials/pre_window/#{name}.sh.erb", locals)
end

def include_on_project_start(name, locals = {})
  include_script_for_bash("templates/partials/on_project_start/#{name}.sh.erb", locals)
end

def include_window(name, folder:, overrides: {})
  include_yaml("templates/partials/windows/#{name}.yml.erb", folder: folder, overrides: overrides)
end

def load_project_override(project_name)
  override_file = resolve_repo_file("developer/projects/#{project_name}.override.yml")
  return {} unless override_file

  data = YAML.safe_load(File.read(override_file), aliases: false)
  data.is_a?(Hash) ? data : {}
end

def read_project_override(project_name)
  override_file = resolve_repo_file("developer/projects/#{project_name}.override.yml")
  return "" unless override_file

  File.read(override_file)
end

def partial_override(override_data, key)
  return {} unless override_data.is_a?(Hash)

  partials = override_data["partials"]
  return {} unless partials.is_a?(Hash)

  value = partials[key]
  value.is_a?(Hash) ? value : {}
end

def render_extra_windows(override_data)
  windows = override_data.is_a?(Hash) ? override_data["windows"] : nil
  return "" unless windows.is_a?(Array) && !windows.empty?

  yaml = windows.to_yaml(line_width: -1).sub(/\A---\s*\n/, "")
  yaml.lines.map { |line| "  #{line}" }.join
end
