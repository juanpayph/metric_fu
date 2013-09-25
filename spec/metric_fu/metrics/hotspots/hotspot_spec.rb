require 'spec_helper'
MetricFu.metrics_require { 'hotspots/hotspot'  }
MetricFu.metrics_require { 'hotspots/hotspots' }

describe MetricFu::Hotspot do
  it "returns an array of of the analyzers that subclass it" do
    expected_analyzers = [ReekHotspot, RoodiHotspot,
      FlogHotspot, ChurnHotspot, SaikuroHotspot,
      FlayHotspot, StatsHotspot, RcovHotspot]

    MetricFu::Hotspot.analyzers.size.should == expected_analyzers.size
  end
end
