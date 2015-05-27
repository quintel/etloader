FactoryGirl.define do
  factory :technology do
    sequence(:key) { |n| "technology_#{ n }" }
    name           { key.titleize }
    # key  "MyString"
    # name "MyString"
  end

  factory :importable_technology, class: :technology do
    importable_attributes { build_list(:importable_attribute, 1) }
  end
end
