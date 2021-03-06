module RedmineGitHosting
  module Patches
    module UsersControllerPatch

      def self.included(base)
        base.class_eval do
          unloadable
          helper :gitolite_public_keys
        end

        # Edit adds new functionality, so don't silently fail!
        base.send(:alias_method_chain, :edit, :public_keys)
        begin
          base.send(:alias_method_chain, :create, :disable_update)
          base.send(:alias_method_chain, :update, :disable_update)
          base.send(:alias_method_chain, :edit_membership, :disable_update)
          base.send(:alias_method_chain, :destroy_membership, :disable_update)
          # Put this last, since Redmine 1.1 doesn't have it....
          base.send(:alias_method_chain, :destroy, :disable_update)
        rescue
        end
      end

      def create_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false);

        # Do actual update
        create_without_disable_update

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(true);
      end

      def update_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false);

        # Set public key values for view
        set_public_key_values

        # Do actual update
        update_without_disable_update

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(true);
      end

      def destroy_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false);

        # Do actual update
        destroy_without_disable_update

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(:delete);
      end

      def edit_membership_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false);

        # Do actual update
        edit_membership_without_disable_update

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(true);
      end

      def destroy_membership_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false);

        # Do actual update
        destroy_membership_without_disable_update

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(true);
      end

      # Add in values for viewing public keys:
      def edit_with_public_keys
        # Set public key values for view
        set_public_key_values

        # Previous routine
        edit_without_public_keys
      end

      # Add in values for viewing public keys:
      def set_public_key_values
        @gitolite_user_keys   = @user.gitolite_public_keys.active.user_key.find(:all,:order => 'title ASC, created_at ASC')
        @gitolite_deploy_keys = @user.gitolite_public_keys.active.deploy_key.find(:all,:order => 'title ASC, created_at ASC')
        @gitolite_public_keys = @gitolite_user_keys + @gitolite_deploy_keys
        @gitolite_public_key  = @gitolite_public_keys.detect{|x| x.id == params[:public_key_id].to_i}
        if @gitolite_public_key.nil?
          if params[:public_key_id]
            # public_key specified that doesn't belong to @user. Kill off public_key_id and try again
            redirect_to :public_key_id => nil, :tab => nil
            return
          else
            @gitolite_public_key = GitolitePublicKey.new
          end
        end
      end

    end
  end
end

unless UsersController.included_modules.include?(RedmineGitHosting::Patches::UsersControllerPatch)
  UsersController.send(:include, RedmineGitHosting::Patches::UsersControllerPatch)
end
