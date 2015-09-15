module Finance
  class BusinessCaseCreator
    def initialize(testing_ground, strategies = {})
      @testing_ground = testing_ground
      @business_case = @testing_ground.business_case
      @strategies = strategies
    end

    def calculate
      return unless existing_business_case?

      @business_case.update_attribute(:financials, financials)
    end

    private

    def existing_business_case?
      @business_case.present?
    end

    def financials
      ( Finance::BusinessCaseCalculator.new(@testing_ground, @strategies).rows +
        [existing_freeform] ).compact
    end

    def existing_freeform
      if financials = @business_case.financials
        financials.detect{|row| row['freeform'] }
      end
    end
  end
end