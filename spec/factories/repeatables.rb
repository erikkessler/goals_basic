FactoryGirl.define do
  factory :repeatable do
    name "Practice Pitching"
    
    trait :repeat_every_day do
      repeated 510510
    end

    trait :repeat_mwf do
      repeated 273
    end

    trait :repeat_weekdays do
      repeated 15015
    end

    trait :repeat_weekends do
      repeated 34
    end

    trait :high_reward do
      reward 50
    end

    trait :low_reward do
      reward 5
    end

    trait :high_penalty do
      penalty 50
    end

    trait :low_penalty do
      penalty 5
    end
    

    factory :daily_repeatable, traits: [:repeat_every_day]
    factory :weekday_repeatable, traits: [:repeat_weekdays]
    factory :weekend_repeatable, traits:[:repeat_weekends]
    factory :mwf_repeatable, traits: [:repeat_mwf]

    factory :habit, class: Habit do
      name "Basic Habit"
      repeat_weekdays
      low_reward
    end
  end
end
