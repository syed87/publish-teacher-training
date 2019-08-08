require 'mcb_helper'

describe 'mcb courses audit' do
  let(:audit) { MCBCommand.new('courses', 'audit') }

  let(:admin_user) { create :user, :admin, email: 'h@i' }

  let(:recruitment_year1) { create :recruitment_cycle, :next }
  let(:recruitment_year2) { RecruitmentCycle.current_recruitment_cycle }

  let(:provider) { create :provider, updated_at: 1.day.ago, changed_at: 1.day.ago, recruitment_cycle: recruitment_year1 }
  let(:rolled_over_provider) do
    new_provider = provider.dup
    new_provider.update(recruitment_cycle: recruitment_year2)
    new_provider.save
    new_provider
  end

  let(:course) { create(:course, name: 'P', provider: provider) }
  let(:rolled_over_course) do
    new_course = course.dup
    new_course.update(provider: rolled_over_provider)
    new_course.update(start_date: course.start_date - 1.year)
    new_course.save
    new_course
  end

  before do
    Audited.store[:audited_user] = admin_user
  end

  context 'when the recruitment year is unspecified' do
    it 'shows the list of changes for a given course' do
      rolled_over_course.update(name: 'Y')
      course.update(name: 'B')

      output = audit.execute(
        arguments: [
          rolled_over_provider.provider_code,
          rolled_over_course.course_code
        ]
      )[:stdout]

      expect(output).to have_text_table_row(admin_user.id,
                                            'h@i',
                                            'update',
                                            '',
                                            '',
                                            '{"name"=>["P", "Y"],')

      expect(output).not_to have_text_table_row(admin_user.id,
                                                'h@i',
                                                'update',
                                                '',
                                                '',
                                                '{"name"=>["P", "B"],')
    end
  end

  context 'when the recruitment year is specified' do
    it 'shows the list of changes for a given course' do
      rolled_over_course.update(name: 'Y')
      course.update(name: 'B')

      output = audit.execute(
        arguments: [
          provider.provider_code,
          course.course_code,
          '-r',
          recruitment_year1.year
        ]
      )[:stdout]

      expect(output).to have_text_table_row(admin_user.id,
                                            'h@i',
                                            'update',
                                            '',
                                            '',
                                            '{"name"=>["P", "B"],')

      expect(output).not_to have_text_table_row(admin_user.id,
                                                'h@i',
                                                'update',
                                                '',
                                                '',
                                                '{"name"=>["P", "Y"],')
    end
  end
end
