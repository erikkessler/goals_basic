# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :permission do
    user_id 1
    activity_id 1
    level 1
  end
end
