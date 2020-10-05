# frozen_string_literal: true

require "bundler/gem_tasks"
require "bundler/audit/task"
require "rspec/core/rake_task"
require "standard/rake"

Bundler::Audit::Task.new
RSpec::Core::RakeTask.new(:spec)

desc "Run code quality checks"
task code_quality: %i[bundle:audit standard]

CLEAN.include("gen/**", "tmp/**")
task default: %i[code_quality spec]
