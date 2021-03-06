FactoryBot.define do
  factory :new_aid_application, class: AidApplication do
    creator { build :assister }
    organization { creator.organization }
  end

  factory :eligible_aid_application, parent: :new_aid_application do
    county_name { organization&.county_names&.sample }
    no_cbo_association { true }
    covid19_reduced_work_hours { true }
    valid_work_authorization { false }
    attestation { true }
  end

  factory :aid_application, parent: :eligible_aid_application do
    transient do
      supervisor { organization.supervisors.sample || create(:supervisor, organization: organization) }
    end

    # Application
    name { Faker::Name.name }
    birthday { 'January 1, 1980' }

    street_address { Faker::Address.street_address }
    city { Faker::Address.city }
    zip_code { ZipCode.from_county(county_name)&.sample }

    allow_mailing_address { true }
    mailing_street_address { Faker::Address.street_address }
    mailing_city { Faker::Address.city }
    mailing_state { Faker::Address.state }
    mailing_zip_code { '03226' }

    unmet_housing { true }

    sms_consent { true }
    phone_number { "1234567890" }
    landline { false }

    email_consent { true }
    email { Faker::Internet.email(name: name, domain: 'example.com') }

    receives_calfresh_or_calworks { true }

    racial_ethnic_identity { [AidApplication::RACIAL_OR_ETHNIC_IDENTITY_OPTIONS.first] }

    card_receipt_method { AidApplication::CARD_RECEIPT_MAIL }

    trait :submitted do
      submitter { creator }
      submitted_at { Time.current }
      application_number { generate_application_number }
    end

    trait :partially_verified do
      submitted

      verified_photo_id { true }
    end

    trait :verified do
      submitted

      verified_photo_id { true }
      verified_proof_of_address { true }
      verified_covid_impact { true }

      verified_at { Time.current }
      verifier { supervisor }
    end

    trait :approved do
      submitted

      approver { supervisor }
      approved_at { Time.current }
    end

    trait :rejected do
      submitted

      rejecter { supervisor }
      rejected_at { Time.current }
    end

    trait :paused do
      submitted

      submitted_at { 14.days.ago }
      paused_at { submitted_at + AidApplication::PAUSE_INTERVAL }
    end

    trait :unpaused do
      paused

      paused_at { nil }
      unpaused_at { submitted_at + 8.days }
      unpauser { supervisor }
    end

    trait :disbursed do
      approved

      disburser { supervisor }
      disbursed_at { Time.current }

      payment_card { create(:payment_card, :disbursed, aid_application: nil) }
    end
  end
end
