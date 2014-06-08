# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    email "MyString"
    password_hash "MyString"
    password_salt "MyString"
    remember_token "MyString"
    admin false
  end
end
