require 'octokit'

class SnowballRepoController < ApplicationController
  unloadable


  def index
  end

  def create_fork
    puts "** calling create_fork #{params}"

    # ref https://developer.github.com/v3/repos/forks/#create-a-fork
    # ref http://octokit.github.io/octokit.rb/Octokit/Client/Repositories.html#fork-instance_method

    # issue Github上Forking a Repository happens asynchronously.因此这里需要可能出现issue

    repo=params[:repository]

    #TODO: 目前这边的controller只针对Github

    fork_from=repo[:fork_from]
    fork_to=repo[:url]

    # 这里的from好像用不着, 因为github上api只支持fork当前用户有权限的repo, 因此from和to都将是用同一个credentials
    #client_from = Octokit::Client.new(:login => repo[:fork_from_login], :password => repo[:fork_from_password])
    #client_from.user

    client_to = Octokit::Client.new(:login => repo[:login], :password => repo[:password])
    client_to.user

    repo_src=Octokit::Repository.from_url(fork_from.sub(%r{\.git$},''));

    # response is a Sawyer::Resource
    response=client_to.fork(repo_src, {:organization => fork_to.to_s})#https://developer.github.com/v3/repos/forks/#create-a-fork

    # flag means success or not
    flag=response.is_a?(Sawyer::Resource) ? true : false

  end
end
