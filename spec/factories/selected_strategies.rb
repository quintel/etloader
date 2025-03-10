FactoryGirl.define do
  factory :selected_strategy do
    battery_storage false
    solar_power_to_heat false
    solar_power_to_gas false
    hp_capacity_constrained false
    postponing_base_load false
    saving_base_load false
    capping_solar_pv false
    capping_fraction 1
  end
end
