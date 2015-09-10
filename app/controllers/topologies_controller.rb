class TopologiesController < ResourceController
  RESOURCE_ACTIONS = %i(show edit update destroy clone)

  respond_to :html
  respond_to :js, only: :clone
  respond_to :json, only: :show

  before_filter :fetch_topology, only: RESOURCE_ACTIONS
  before_filter :authorize_generic, except: RESOURCE_ACTIONS
  before_filter :fetch_testing_ground, only: :clone

  def index
    @topologies = policy_scope(Topology.named).in_name_order
  end

  # GET /topologies
  def show
  end

  # GET /topologies/new
  def new
    @topology = Topology.new
  end

  # POST /topologies
  def create
    respond_with(@topology = current_user.topologies.create(topology_params))
  end

  # GET /topologies/:id/edit
  def edit
  end

  # PATCH /topologies/:id
  def update
    @topology.update_attributes(topology_params)
    respond_with(@topology)
  end

  # POST /topologies/:id/clone
  def clone
    TestingGround::Cloner.new(@testing_ground, @topology, topology_params).clone
  end

  # DELETE /topologies/:id
  def destroy
    @topology.destroy
    redirect_to(topologies_url)
  end

  private

  def fetch_topology
    @topology = Topology.find(params[:id])
    authorize @topology
  end

  def topology_params
    params.require(:topology).permit(:name, :user_id, :graph, :public)
  end
end
