#require_dependency 'github'

module SnowballGithubCreatorPatch

  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    puts "** including SnowballGithub"

    base.class_eval do
      unloadable

      def self.enabled?
        puts "** asking enable? in SnowballGithubCreatorPatch"

        if options
          if options['path']
            if !options['github'] || File.executable?(options['github'])
              return true
            else
              Rails.logger.warn "'#{options['github']}' cannot be found/executed - ignoring '#{scm_id}"
            end
          else
            Rails.logger.warn "missing path for '#{scm_id}'"
          end
        end

        false
      end

      # path : /var/scm_repo/github/repo_demp
      # repository : github
      def self.create_repository(path, repository = nil)
        puts "** calling SnowballGithubCreatorPatch::create_repository"

        #create project on github
        if User.current.github.nil?
          raise "no github token found in user #{User.current.login}"
        end

        attrs = {}
        attrs['token'] = User.current.github_token;
        attrs['title'] = repository.identifier;
        attrs['description'] = 'this repository is created by zycode.';
        attrs['visibility'] = true;
        attrs['project_identifier'] = repository.project.identifier;
        github_create(attrs);


        # init git and do fetch

        # go to root path, eg: /var/scm_repo/github
        Dir.chdir(ScmConfig['github']['path']) do
          args = [ git_command, 'clone' ]
          append_options(args)

          #--------set username & password in url------------
          # TODO http or https or ssh
          tmp_url = repository.url.gsub("http://","")
          tmp_url = repository.login + ':' + repository.password + '@' + tmp_url

          args << ('http://' + tmp_url + ScmConfig['github']['append'].to_s)
          #--------------------


          if system(*args)
            if options['update_server_info']
              Dir.chdir(path) do
                args = [ git_command, 'fetch' ]
                args << '-q'
                args << '--all'
                args << '-p'
                system(*args)
              end
            end
            true
          else
            false
          end
        end


      end

      def self.access_root_url(path, repository)
        (repository.url.nil? || repository.url == "") ? (ScmConfig['github']['url'].to_s + '/' + (repository.project.identifier)) : repository.root_url
      end

      def self.access_url(path, repository)
        (repository.url.nil? || repository.url == "") ? (ScmConfig['github']['url'].to_s + '/' + (repository.project.identifier)) : repository.url
      end

      def self.repository_name(path)
        matches = %r{^(?:.*/)?([^/]+?)(\\.git)?/?$}.match(path)
        matches ? matches[1] : nil
      end


      private

      def self.git_command
        options['git'] || Redmine::Scm::Adapters::GitAdapter::GIT_BIN
      end



    end

    #base.send(:github_field_tags, nil, nil)

  end

  module ClassMethods
  end


  module InstanceMethods

  end

end




