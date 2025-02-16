module Find
  class AgeGroupsForm
    include ActiveModel::Model

    attr_accessor :age_group

    def initialize(params: {})
      @params = params
      assign_attributes(params)
    end

    validates :age_group, presence: true
    validates :age_group, inclusion: { in: %w[primary secondary further_education] }
  end
end
