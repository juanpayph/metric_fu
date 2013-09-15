module MetricFu
  class Loader
    # TODO: This class mostly serves to clean up the base MetricFu module,
    #   but needs further work

    attr_reader :loaded_files
    def initialize(lib_root)
      @lib_root = lib_root
      @loaded_files = []
    end

    def lib_require(base='',&block)
      paths = []
      base_path = File.join(@lib_root, base)
      Array((yield paths, base_path)).each do |path|
        file = File.join(base_path, *Array(path))
        require file
        if @loaded_files.include?(file)
          puts "!!!\tAlready loaded #{file}" if !!(ENV['MF_DEBUG'] =~ /true/i)
        else
          @loaded_files << file
        end
      end
    end

    # TODO: Reduce duplication of directory logic
    def create_dirs(klass)
      class << klass
        Array(yield).each do |dir|
          define_method("#{dir}_dir") do
            File.join(lib_dir,dir)
          end
          module_eval(%Q(def #{dir}_require(&block); lib_require('#{dir}', &block); end))
        end
      end
    end

    def create_artifact_subdirs(klass)
      class << klass
        Array(yield).each do |dir|
          define_method("#{dir.gsub(/[^A-Za-z0-9]/,'')}_dir") do
            File.join(artifact_dir,dir)
          end
        end
      end
    end

    def load_tasks(tasks_relative_path)
      load File.join(@lib_root, 'tasks', *Array(tasks_relative_path))
    end

    # Keep all setup in this method.  If it gets too big, that is a smell.
    def setup
      MetricFu.lib_require { 'configuration' }
      MetricFu.lib_require { 'metric' }
      # rake is required for
      # Rcov    : FileList
      # loading metric_fu.rake
      require 'rake'

      require 'yaml'
      require 'redcard'
      require 'multi_json'
      load_files
    end
    # The @configuration class variable holds a global type configuration
    # object for any parts of the system to use.
    # TODO Configuration should probably be a singleton class
    def configuration
      @configuration ||= MetricFu::Configuration.new
    end

    def graph
      @graph ||= MetricFu::Graph.new
    end

    # MetricFu.result memoizes access to a Result object, that will be
    # used throughout the lifecycle of the MetricFu app.
    def result
      @result ||= MetricFu::Result.new
    end
    def reset
      # TODO Don't like how this method needs to know
      # all of these class variables that are defined
      # in separate classes.
      # maybe config.reset_all
      @configuration = nil
      @graph         = nil
      @result        = nil
    end
    def load_files

      MetricFu.configure
      MetricFu.logging_require { 'mf_debugger' }
      Object.send(:include, MfDebugger)
      MfDebugger::Logger.debug_on = !!(ENV['MF_DEBUG'] =~ /true/i)
      #
      # require these first because others depend on them
      MetricFu.reporting_require { 'result' }
      MetricFu.metrics_require   { 'hotspots/hotspot' }
      MetricFu.metrics_require   { 'generator' }
      MetricFu.metrics_require   { 'graph' }
      MetricFu.reporting_require { 'graphs/grapher' }
      MetricFu.metrics_require   { 'hotspots/analysis/scoring_strategies' }

      Dir.glob(File.join(MetricFu.lib_dir, '*.rb')).
        reject{|file| file =~ /#{__FILE__}|ext.rb/}.
        each do |file|
          require file
      end
      # prevent the task from being run multiple times.
      unless Rake::Task.task_defined? "metrics:all"
        # Load the rakefile so users of the gem get the default metric_fu task
        MetricFu.tasks_load 'metric_fu.rake'
      end
      Dir.glob(File.join(MetricFu.data_structures_dir, '**/*.rb')).each do |file|
        require file
      end
      Dir.glob(File.join(MetricFu.logging_dir, '**/*.rb')).each do |file|
        require file
      end
      Dir.glob(File.join(MetricFu.errors_dir, '**/*.rb')).each do |file|
        require file
      end
      Dir.glob(File.join(MetricFu.metrics_dir, '**/*.rb')).each do |file|
        require(file) unless file =~ /init.rb/
      end
      Dir.glob(File.join(MetricFu.reporting_dir, '**/*.rb')).each do |file|
        require file
      end
      Dir.glob(File.join(MetricFu.formatter_dir, '**/*.rb')).each do |file|
        require file
      end
    end
  end
end
