class StatisticService
  def self.reporting(recruitment_cycle:)
    {
      providers: ProviderReportingService.call(providers_scope: recruitment_cycle.providers),
      courses: CourseReportingService.call(courses_scope: recruitment_cycle.courses),
      publish: PublishReportingService.call(recruitment_cycle_scope: recruitment_cycle),
      allocations: AllocationReportingService.call(recruitment_cycle_scope: RecruitmentCycle.find_by(year: Settings.allocation_cycle_year)),
      rollover: RolloverReportingService.call,
    }
  end

  def self.save(recruitment_cycle: RecruitmentCycle.current_recruitment_cycle)
    Statistic.create!(json_data: reporting(recruitment_cycle:))
  end
end
