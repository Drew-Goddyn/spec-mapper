require "json"
require "pathname"
require "fileutils"

class SpecMapper
  attr_reader :spec_paths, :described_paths, :metadata, :spec_map

  def initialize(spec_path: "~/Clio/themis/components/manage/spec", described_path: "~/Clio/themis/components/manage")
    @spec_paths = Dir[File.expand_path("#{spec_path}/**/*_spec.rb")]
    @described_paths = Dir[File.expand_path("#{described_path}/**/*.*rb")]
    @metadata = {
      total: spec_paths.count,
      integration_specs: 0,
      matched: 0,
      unmatched: 0,
      correct: 0,
     }
    @spec_map = map_specs
  end

  def dump
    output = { metadata: metadata, paths: spec_map }
    json_output_path = File.expand_path("spec_paths.json")
    File.open(json_output_path, "w") do |f|
      f << JSON.pretty_generate(output)
    end
    json_output_path
  end

  def move_matched_specs
    puts "#{metadata[:total]} total specs scanned..."
    puts "#{metadata[:integration_specs]} are disregarded due to being integration specs..."
    puts "#{metadata[:total] - metadata[:integration_specs] } are unit specs..."
    puts "#{metadata[:correct]} unit specs are already in correct location..."
    puts "#{metadata[:matched]} specs were succesffully matched and moved..."
    puts "#{metadata[:unmatched]} unit specs couldn't be matched..."

    spec_map[:matched_paths].each do |paths|
      FileUtils.mkdir_p(Pathname(File.expand_path(paths[:expected_spec_path])).parent)
      FileUtils.mv(File.expand_path(paths[:current_spec_path]), File.expand_path(paths[:expected_spec_path]))
    end
  end

  private

  def map_specs
    matched_paths = []
    unmatched_paths = []
    correct_paths = []
    integration_paths = []
    spec_paths.each do |current_spec_path|
      described_path = find_described_path_for(current_spec_path)
      if described_path.nil?
        if unit_spec?(current_spec_path)
          metadata[:unmatched] += 1
          unmatched_paths << current_spec_path
        else
          metadata[:integration_specs] += 1
          integration_paths << current_spec_path
        end
        next
      end

      expected_spec_path = convert_to_spec_path(described_path)

      if current_spec_path == expected_spec_path
        metadata[:correct] += 1
        correct_paths << current_spec_path
        next
      end

      matched_paths << { current_spec_path: current_spec_path, described_path: described_path, expected_spec_path: expected_spec_path }
    end

    metadata[:matched] = matched_paths.count
    { matched_paths: matched_paths, unmatched_paths: unmatched_paths, correct_paths: correct_paths, integration_paths: integration_paths }
  end

  def find_described_path_for(spec_path)
    described_path = convert_to_described_path(spec_path)
    match_path(described_path)
  end

  def match_path(path)
    return path if file_exists_at_path?(path)

    possible_paths = match_filename(path)
    possible_paths = match_path_elements(path, possible_paths)
    possible_paths.min_by { |path| path.split("/").size }
  end

  def match_filename(path)
    filename = Pathname(path).basename.to_s
    described_paths.select { |path| Pathname(path).basename.to_s == filename }
  end

  def match_path_elements(path, possible_paths)
    path_elements = path.split("/")
    possible_paths.select { |possible_path| path_elements.all? { |element| possible_path =~ /#{element}/ } }
  end

  def convert_to_described_path(spec_path)
    if spec_path.end_with?(".erb_spec.rb")
      spec_path = spec_path.chomp("_spec.rb")
    else
      spec_path = spec_path.sub(/_spec.rb$/, ".rb")
    end

    spec_path.sub(/\/spec/, "")
  end

  def convert_to_spec_path(described_path)
    if described_path.end_with?(".erb")
      described_path = described_path.sub(/.erb$/, ".erb_spec.rb")
    else
      described_path = described_path.sub(/.rb$/,"_spec.rb")
    end

    described_path.sub(/(^.*components\/manage)(\/app|\/spec)?/, '\1/spec')
  end

  def unit_spec?(spec_path)
    File.readlines(spec_path).any? { |line| line =~ /describe\s*[A-Z]/ }
  end

  def file_exists_at_path?(path)
    File.exist?(path)
  end
end

if ARGV[0] == "dump"
  SpecMapper.new.dump
else
  SpecMapper.new.move_matched_specs
end
