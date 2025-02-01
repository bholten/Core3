require 'json'
require 'set'

ALL_CREATURES_FILE = "all_creatures.json"
MISSING_CREATURES_FILE = "missing_creatures.json"

BASE_PATHS = {
  lairs: 'bin/scripts/mobile/lair/creature_lair',
  dynamic_spawns: 'bin/scripts/mobile/lair/creature_dynamic',
  zones: 'bin/scripts/mobile/spawn',
  missions: 'bin/scripts/mobile/spawn/destroy_missions',
  screenplays: 'bin/scripts/screenplays'
}.freeze

FILE_PATHS = {}
FILE_LOADED = {}

def traverse_files!(base)
  FILE_PATHS[base] ||= Dir.glob("#{base}/**/*").select { |file| File.file?(file) }
end

def load_file!(path)
  FILE_LOADED[path] ||= File.read(path)  
end

def find_references!(base, regexp)
  traverse_files!(base).each_with_object(Set.new) do |file, results|
    loaded_file = load_file!(file)
    if loaded_file.match?(regexp)
      results << File.basename(file, ".lua")
    end
  end
end

def base_path(type, planet)
  # TODO planet is ignored for now. They seem to
  # define creatures on one planet and use them on
  # others -- e.g.
  # corellia/acicular_defender
  # but used only in Talus.
  # This makes things horrifically inefficient
  
  # "#{BASE_PATHS[type]}/#{planet}"
  "#{BASE_PATHS[type]}"
end

def all_creatures
  results = []
  base = "bin/scripts/mobile"

  Dir.glob("#{base}/**/*").each do |file|
    next unless File.file?(file)

    relative_path = file.sub("#{base}/", "")
    parts = relative_path.split(File::SEPARATOR)

    if parts.size > 1
      subfolder = parts[0]
      file_name = parts[1..].join(File::SEPARATOR).sub(/\..+$/, '')
      results << { planet: subfolder, creature: file_name }
    end
  end

  results
end

def creature_lairs(creature_hash)
  planet = creature_hash[:planet]
  creature = creature_hash[:creature]
  return creature_hash.merge(lairs: Set.new) if planet.nil? || creature.nil?

  base = base_path(:lairs, planet)
  regexp = /#{Regexp.quote(creature)}/
  creature_hash.merge(lairs: find_references!(base, regexp))
end

def creature_dynamics(creature_hash)
  planet = creature_hash[:planet]
  creature = creature_hash[:creature]
  return creature_hash.merge(dynamic_spawns: Set.new) if planet.nil? || creature.nil?

  base = base_path(:dynamic_spawns, planet)
  regexp = /#{Regexp.quote(creature)}/
  creature_hash.merge(dynamic_spawns: find_references!(base, regexp))
end

def creature_zones(creature_hash)
  planet = creature_hash[:planet]
  spawns = creature_hash[:dynamic_spawns] || Set.new
  lairs = creature_hash[:lairs] || Set.new
  return creature_hash.merge(zones: Set.new) if planet.nil? || (spawns.empty? && lairs.empty?)

  base = base_path(:zones, planet)

  results = (lairs.to_a + spawns.to_a).flat_map do |item|
    regexp = /#{Regexp.quote(item)}/
    find_references!(base, regexp).to_a
  end

  creature_hash.merge(zones: results.flatten.to_set)
end

def creature_missions(creature_hash)
  spawns = creature_hash[:dynamic_spawns] || Set.new
  lairs = creature_hash[:lairs] || Set.new
  return creature_hash.merge(missions: Set.new) if spawns.empty? && lairs.empty?
  
  base = BASE_PATHS[:missions]

  results = (lairs.to_a + spawns.to_a).flat_map do |item|
    regexp = /#{Regexp.quote(item)}/
    find_references!(base, regexp).to_a
  end

  creature_hash.merge(missions: results.flatten.to_set)
end

def creature_static_spawns(creature_hash)
  creature = creature_hash[:creature]
  return creature_hash.merge(static_spawns: Set.new) if creature.nil?
  
  base = BASE_PATHS[:screenplays]
  regexp = /#{Regexp.quote(creature)}/
  creature_hash.merge(static_spawns: find_references!(base, regexp))  
end

def creature_data
  planets = %w[corellia dathomir endor lok naboo rori talus tatooine yavin4]
  
  all_creatures.map do |creature|
    next if creature.nil? # TODO figure out why nil is coming through
    next unless planets.include?(creature[:planet])
    
    creature
      .then { |c| creature_lairs(c) }
      .then { |c| creature_dynamics(c) }
      .then { |c| creature_zones(c) }
      .then { |c| creature_missions(c) }
      .then { |c| creature_static_spawns(c) }
  end.compact
end

def missing_creatures
  creature_data.select do |creature|
    creature[:static_spawns].empty? and creature[:zones].empty? and creature[:missions].empty?
  end
end

def all_creatures_dump!
  File.write(ALL_CREATURES_FILE, JSON.pretty_generate(all_creatures_parsed))
end

def missing_creatures_dump!
  mc = missing_creatures.map { |c| c[:creature] }
  File.write(MISSING_CREATURES_FILE, JSON.pretty_generate(mc))
end

