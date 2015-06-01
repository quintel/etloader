class TestingGroundsController < ApplicationController
  respond_to :html, :json
  respond_to :csv, only: :technology_profile
  respond_to :js, only: :calculate_concurrency

  before_filter :find_testing_ground, only: [:edit, :update, :show,
    :technology_profile, :data, :destroy]
  before_filter :prepare_export, only: %i( export perform_export )
  before_filter :load_technologies, only: [:perform_import, :update, :create,
                                           :edit, :new, :calculate_concurrency]

  # GET /topologies
  def index
    respond_with(@testing_grounds = TestingGround.overview(current_user))
  end

  # GET /topologies/import
  def import
    @import = Import.new(params.slice(:scenario_id))
  end

  # POST /topologies/import
  def perform_import
    @import = Import.new(params[:import])

    if @import.valid?
      @testing_ground = @import.testing_ground
      render :new
    else
      render :import
    end
  end

  # GET /testing_grounds/:id/export
  def export
  end

  # POST /testing_grounds/:id/export
  def perform_export
    redirect_to("http://beta.pro.et-model.com/scenarios/" +
                "#{ @export.export['id'] }")
  end

  # GET /topologies/new
  def new
    respond_with(@testing_ground = TestingGround.new)
  end

  # POST /topologies
  def create
    respond_with(@testing_ground = current_user.testing_grounds
                                     .create(testing_ground_params))
  end

  # GET /topologies/:id
  def show
    PrivatePolicy.new(self, @testing_ground).authorize
  end

  def data
    begin
      if PrivatePolicy.new(self, @testing_ground).authorized?
        render json: @testing_ground.to_json(storage: params[:storage] == '1')
      else
        render json: {
                 message: I18n.t("testing_grounds.data.permission_denied")
               },
               status: 403
      end
    rescue StandardError => ex
      notify_airbrake(ex) if defined?(Airbrake)

      result = { error: I18n.t("testing_grounds.data.error") }

      if Rails.env.development? || Rails.env.test?
        result[:message]   = "#{ ex.class }: #{ ex.message }"
        result[:backtrace] = ex.backtrace
      end

      render json: result,
             status: 500
    end
  end

  # GET /topologies/:id/edit
  def edit
    PrivatePolicy.new(self, @testing_ground).authorize
  end

  # PATCH /topologies/:id
  def update
    if PrivatePolicy.new(self, @testing_ground).authorized?
      @testing_ground.update_attributes(testing_ground_params)

      respond_with(@testing_ground)
    else
      redirect_to testing_grounds_path
    end
  end

  # POST /topologies/calculate_concurrency
  def calculate_concurrency
    calculated_concurrency = TestingGround::ConcurrencyCalculator.new(
                                params[:profile],
                                params[:topology],
                                params[:profile_differentiation]).calculate

    @testing_ground_profile = TechnologyList.from_hash(calculated_concurrency)
  end

  # GET /testing_grounds/:id/technology_profile.csv
  def technology_profile
    if PrivatePolicy.new(self, @testing_ground).authorized?
      respond_with(@testing_ground.technology_profile)
    end
  end

  private

  # Internal: Returns the permitted parameters for creating a testing ground.
  def testing_ground_params
    tg_params = params
      .require(:testing_ground)
      .permit([:name, :technologies, :technology_profile, :public,
               :technology_profile_csv, :scenario_id, :topology_id])

    if tg_params[:technology_profile_csv]
      tg_params.delete(:technology_profile)
    elsif tg_params[:technology_profile]
      yamlize_attribute!(tg_params, :technology_profile)

      # Some attributes which should be considered "not present" are submitted by
      # the technology table as an empty string. Delete them.
      tg_params[:technology_profile].each do |_, techs|
        techs.each do |tech|
          tech.delete_if { |_attr, value| value.blank? }
        end
      end
    end

    tg_params
  end

  # Internal: Given a hash and an attribute key, assumes the value is a YAML
  # string and converts it to a Ruby hash.
  def yamlize_attribute!(hash, attr)
    hash[attr] = YAML.load(hash[attr]) if hash[attr]
  end

  def find_testing_ground
    @testing_ground = TestingGround.find(params[:id])
  end

  # Internal: Before filter which loads models required for export-to-ETEngine
  # eactions.
  def prepare_export
    @testing_ground = TestingGround.find(params[:id])
    @export         = Export.new(@testing_ground)
  end

  def load_technologies
    @technologies = Technology.all
  end
end # TestingGroundsController
