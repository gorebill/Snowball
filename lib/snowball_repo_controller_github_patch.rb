require 'snowball_github'

module SnowballRepoControllerGithubPatch

  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    puts "** including SnowballRepoControllerGithubPatch"

    base.class_eval do
      unloadable

      alias_method_chain :init_gitlab_token, :github
      alias_method_chain :scm_create_repository, :github

      def github_fetch_set_token(user,username,password)
        puts "** calling github_fetch_set_token in SnowballRepoControllerGithubPatch"

        # FIXME: 这里沿用os那边的code，要改
        request_url = ScmConfig['github']['url'].to_s + '/api/v3/session'
        params = {}
        params["login"] = username
        params["password"] = password
        uri = URI.parse(request_url)
        res = Net::HTTP.post_form(uri, params)
        case res
          when Net::HTTPSuccess, Net::HTTPRedirection
            private_token = (JSON.parse(res.body))['private_token']
            if user
              user.github_token = private_token
              user.save()
            end
            private_token
          when Net::HTTPUnauthorized
            "HTTPUnauthorized"
          else
            puts "error: #{res}"
            res.to_s
        end

      end

    end

    #base.send(:github_field_tags, nil, nil)

  end

  module ClassMethods
  end

  module InstanceMethods

    def init_gitlab_token_with_github(repository,user,username,password)
      puts "** calling init_gitlab_token_with_github in ScmRepositoriesControllerPatch repo.#{repository.type}"

      if repository.type != 'Repository::Gitlab' && repository.type != 'Repository::Github'
        return "not_gitlab";
      end

      if repository.type == 'Repository::Gitlab'
        fetch_set_token(user,username,password);
      else
        if repository.type == 'Repository::Github'

          # FIXME: 这里需要研究
          #github_fetch_set_token(user,username,password);
        end
      end

    end

    def scm_create_repository_with_github(repository, interface, url)
      puts "** calling scm_create_repository_with_add in SnowballRepoControllerGithubPatch interface.#{interface}"

      name = interface.repository_name(url)
      if name
        path = interface.default_path(name)
        if interface.repository_exists?(name)
          repository.errors.add(:url, :already_exists)
        else
          Rails.logger.info "Creating reporitory: #{path}"
          interface.execute(ScmConfig['pre_create'], path, @project) if ScmConfig['pre_create']
          if result = interface.create_repository(path, repository)
            path = result if result.is_a?(String)
            interface.execute(ScmConfig['post_create'], path, @project) if ScmConfig['post_create']
            repository.created_with_scm = true
          else
            repository.errors.add(:base, :scm_repository_creation_failed)
            Rails.logger.error "Repository creation failed"
          end
        end

        repository.root_url = interface.access_root_url(path, repository)
        repository.url      = interface.access_url(path, repository)

        if interface.local? && !interface.belongs_to_project?(name, @project.identifier)
          flash[:warning] = l(:text_cannot_be_used_redmine_auth)
        end
      else
        repository.errors.add(:url, :should_be_of_format_local, :repository_format => interface.repository_format)
      end

      # Otherwise input field will be disabled
      if repository.errors.any?
        repository.root_url = nil
        repository.url = nil
      end
    end


  end
end