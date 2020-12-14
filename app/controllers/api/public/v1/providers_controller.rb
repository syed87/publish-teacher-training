module API
  module Public
    module V1
      class ProvidersController < API::Public::V1::ApplicationController
        def index
          render jsonapi: paginated_records,
          include: params[:include], class: API::Public::V1::SerializerService.call, fields: fields
        end

        def show
          code = params.fetch(:code, params[:provider_code])
          provider = recruitment_cycle.providers
                                        .find_by!(
                                          provider_code: code.upcase,
                                        )

          render jsonapi: provider,
                 class: API::Public::V1::SerializerService.call,
                 include: params[:include],
                 fields: fields
        end

      private

        def pagy_scope
          @pagy_scope ||= if sort_by_provider_ascending?
                            recruitment_cycle.providers.by_name_ascending
                          else
                            recruitment_cycle.providers.by_name_descending
                          end
        end

        def recruitment_cycle
          @recruitment_cycle = RecruitmentCycle.find_by(
            year: params[:recruitment_cycle_year],
          ) || RecruitmentCycle.current_recruitment_cycle
        end

        def fields
          { providers: provider_fields } if provider_fields.present?
        end

        def sort_by_provider_ascending?
          sort_field.include?("name") || !sort_by_provider_descending?
        end

        def sort_by_provider_descending?
          sort_field.include?("-name")
        end

        def sort_field
          @sort_field ||= Set.new(params.dig(:sort)&.split(","))
        end

        def provider_fields
          params.dig(:fields, :providers)&.split(",")
        end
      end
    end
  end
end
