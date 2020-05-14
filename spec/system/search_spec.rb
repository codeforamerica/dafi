require 'rails_helper'

RSpec.describe 'Search in admin panel', type: :system do
  let!(:assister) { create :assister }
  let!(:aid_application) { create :aid_application, :submitted, organization: assister.organization }
  let!(:other_aid_application) { create :aid_application, :submitted, organization: assister.organization }

  before { AidApplicationSearch.refresh }

  it 'assisters can search for applications' do
    sign_in assister
    visit root_path

    within '.searchbar' do
      fill_in "term", with: aid_application.name
      click_on "search_submit"
    end

    expect(page).to have_content aid_application.application_number.to_s
    expect(page).not_to have_content other_aid_application.application_number.to_s
  end
end
