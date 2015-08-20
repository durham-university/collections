FactoryGirl.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    password 'password'
    sequence(:email) { |n| "user#{n}@example.com" }

    factory :registered_user_1 do
      username 'registered_user_1'
      email 'reg1@example.com'
    end

    factory :registered_user_2 do
      username 'registered_user_2'
      email 'reg2@example.com'
    end

    factory :admin_user do
      before(:create) do |u,evaluator|
        role=Role.where(name: 'admin').first || Role.create(name: 'admin')
        u.roles << role
      end
    end
  end
end
