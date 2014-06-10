# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :feed_item do
    user_id 1
    message "MyString"
  end
end
