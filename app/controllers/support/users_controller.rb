module Support
  class UsersController < SupportController
    def index
      @users = filtered_users.page(params[:page] || 1)
    end

    def show
      @providers = providers.order(:provider_name).page(params[:page] || 1)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to support_users_path
      else
        render :new
      end
    end

    def destroy
      if user.discard
        redirect_to support_users_path, flash: { success: "User successfully deleted" }
      else
        redirect_to support_users_path, flash: { success: "This user has already been deleted" }
      end
    end

    def remove_from_provider
      if user.remove_access_to(provider)
        redirect_to support_user_path(user), flash: { success: "#{provider.provider_name} removed from user" }
      else
        redirect_to support_user_path(user), flash: { success: "Unable to remove #{provider.provider_name} from user" }
      end
    end

  private

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email).merge(state: "new")
    end

    def user
      @user ||= User.find(params[:id])
    end

    def providers
      RecruitmentCycle.current.providers.where(id: user.providers)
    end

    def filtered_users
      Support::Filter.call(model_data_scope: User.order(:last_name), filters: filters)
    end

    def filters
      @filters ||= ProviderFilter.new(params: filter_params).filters
    end

    def filter_params
      params.permit(:text_search, :page, :commit)
    end

    def provider
      @provider ||= Provider.find(params["provider_id"])
    end
  end
end
