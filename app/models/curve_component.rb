module CurveComponent
  extend ActiveSupport::Concern

  included do
    validate :validate_curve_length
  end

  VALID_CSV_TYPES = ["data:text/csv", "text/csv", "text/plain",
                     "application/octet-stream", "application/vnd.ms-excel"]

  def as_json(*)
    super.merge('values' => network_curve.to_a)
  end

  # Public: Returns the Network::Curve which containing each of the load profile
  # values.
  def network_curve(range = nil, scaling = :original)
    cache_key = "profile.#{ id }.#{ curve_updated_at.to_s(:db) }.#{ range}.#{ scaling }"

    Rails.cache.fetch(cache_key) do
      values = File.foreach(curve.path(scaling)).map(&:to_f)
      Network::Curve.new(range ? values[range] : values)
    end
  end

  def scaled_network_curve(scaling, range)
    Network::Curve.new(
      case scaling
        when :capacity_scaled then Paperclip::ScaledCurve.scale(network_curve(range), :max)
        when :demand_scaled   then Paperclip::ScaledCurve.scale(network_curve(range), :sum)
        else network_curve(range)
      end.to_a
    )
  end

  private

  def validate_curve_length
    return unless curve && curve.queued_for_write[:original]

    length = Network::Curve.load_file(
      curve.queued_for_write[:original].path
    ).length

    # 8760 is permitted in tests, but not *currently* officially supported in
    # the front-end.
    unless length == 8760 || length == 35040
      errors.add(
        :curve,
        "must have 35,040 values, but the uploaded file has #{ length }"
      )
    end
  end
end
