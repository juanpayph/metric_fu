module MetricFu
  class MetricReek < Metric
    require_relative 'reek'
    require_relative 'reek_grapher'

    def name
      :reek
    end

    def default_run_options
      { :dirs_to_reek => MetricFu::Io::FileSystem.directory('code_dirs'),
                    :config_file_pattern => nil}
    end

    def has_graph?
      true
    end

    def enable
      super
    end

    def activate
      super
    end

  end
end
