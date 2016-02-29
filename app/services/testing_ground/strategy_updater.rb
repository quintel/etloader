class TestingGround::StrategyUpdater
  def initialize(testing_ground, params)
    @testing_ground = testing_ground
    @params = params
  end

  def update
    @params[:strategies].empty? ||
    @testing_ground.selected_strategy.update_attributes(strategy_params)
  end

  private

  def strategy_params
    @params.require(:strategies).permit(
      :battery_storage,
      :ev_capacity_constrained,
      :ev_excess_constrained,
      :ev_storage,
      :solar_power_to_heat,
      :solar_power_to_gas,
      :hp_capacity_constrained,
      :postponing_base_load,
      :saving_base_load,
      :capping_solar_pv,
      :capping_fraction
    )
  end
end
