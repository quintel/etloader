class InstalledTechnology
  class ProfileCurve
    include Virtus.model

    attribute :curves, Hash
    attribute :range, Range

    def length
      cut_curves.values.compact.map(&:values).map(&:length).max || 1
    end

    def each
      if has_heat_pump_profiles?
        yield(cut_curves.keys.sort.join('_'), *curves.values)
      else
        cut_curves.each_pair.map do |curve_type, curve|
          yield(curve_type, curve)
        end
      end
    end

    def has_heat_pump_profiles?
      curves.keys.sort == %w(availability use)
    end

    private

    def cut_curves
      Hash[curves.map do |curve_type, curve|
        [curve_type, curve ? slice_curve(curve) : nil]
      end]
    end

    def slice_curve(curve)
      curve_range = (range ? range : 0...(curve.size / 52))

      curve[curve_range]
    end
  end
end
