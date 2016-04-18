module GasAssetLists
  class NetworkSummary
    # Human names of each pressure level and the corresponding network layer.
    LEVELS = {
      'Endpoints ↔ 0.125 bar' => :local,
      '0.125 bar ↔ 4 bar'     => :four,
      '4 bar ↔ 8 bar'         => :eight,
      '8 bar ↔ 40 bar'        => :forty
    }

    def initialize(network)
      @network = network
    end

    def to_h
      LEVELS.map do |name, key|
        { pressure_level: name, stacked: summarize_component(key) }
      end
    end

    alias_method :as_json, :to_h

    private

    def summarize_component(key)
      summary =
        if key == :local
          summarize_level(@network.public_send(key))
        else
          summarize_connection(@network.public_send(key).children.first)
        end

      # Convert kW to kWh.
      summary.each_key { |key| summary[key] /= 4.0 }

      summary
    end

    # Internal: Given a Chain::Level, summarizes the loads on that component
    # throughout the year.
    #
    # Returns a hash.
    def summarize_level(level)
      summary = { loss: 0.0, feed_in: 0.0, consumption: 0.0 }

      each_frame do |frame|
        if (flow = level.output_at(frame)) > 0
          summary[:consumption] += flow
        else
          summary[:feed_in] += flow.abs
        end

        yield(frame, summary) if block_given?
      end

      summary
    end

    # Internal: Given a Chain::Connection, summarizes the loads on the
    # connection throughout the year.
    #
    # Returns a hash.
    def summarize_connection(connection)
      summary = summarize_level(connection)

      each_frame do |frame|
        summary[:loss] += connection.loss_at(frame)
      end

      summary
    end

    def each_frame
      return enum_for(:each_frame) unless block_given?

      # TODO This shouldn't be hard-coded, but presently the gas network does
      # not return a length, and the total gas demand - which does have a
      # length - is not exposed publicly.
      (0...35040).each { |frame| yield(frame) }
    end
  end # NetworkSummary
end
