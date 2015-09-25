class BusinessCaseCalculatorJob
  def initialize(testing_ground, strategies = {})
    @testing_ground = testing_ground
    @strategies = strategies || {}
  end

  def before(job)
    business_case.update_attribute(:job_id, job.id)
  end

  def perform
    Finance::BusinessCaseCreator.new(@testing_ground, business_case, @strategies).calculate
  end

  def after(job)
    business_case.update_attribute(:job_finished_at, DateTime.now)
  end

  def error(job, exception)
    if %w(development test).include?(Rails.env)
      puts exception
    else
      Airbrake.notify(exception)
    end
  end

  private

  def business_case
    @testing_ground.business_case || BusinessCase.create!(testing_ground: @testing_ground)
  end
end
