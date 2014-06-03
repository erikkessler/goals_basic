# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :type do
    name "MyString"
    description "MyText"
    type_group nil
  end
end
