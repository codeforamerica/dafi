module AidApplications
  class EligibilitiesController < BaseController
    def edit
      @aid_application = current_aid_application
    end

    def update
      @aid_application = current_aid_application
      @aid_application.assign_attributes(aid_application_params)
      @aid_application.save(context: :eligibility)
      respond_with @aid_application, location: -> { edit_organization_aid_application_applicant_path(current_organization, @aid_application) }
    end

    private

    def aid_application_params
      params.require(:aid_application).permit(
          :no_cbo_association,
          :valid_work_authorization,
          :covid19_reduced_work_hours,
          :covid19_care_facility_closed,
          :covid19_experiencing_symptoms,
          :covid19_underlying_health_condition,
          :covid19_caregiver,
          :county_name
      )
    end
  end
end
