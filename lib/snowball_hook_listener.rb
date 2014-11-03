
#Ref: http://www.redmine.org/projects/redmine/wiki/Plugin_Tutorial#Hooks-in-views

class SnowballHookListener < Redmine::Hook::ViewListener
  def view_repositories_show_contextual(context = {})
    o=''

    if context[:repository] && context[:project]
      if(context[:repository].type=='Repository::Github')
        o << link_to(
            'Fork This Repo',
            {:controller => 'repositories', :action => 'fork', :id => context[:project], :repository_id => context[:repository].identifier},
            :id => 'repo_fork_btn',
            :style => 'margin-right:20px;',
            :class => 'icon icon-fav'
        )
        o << javascript_include_tag('snowball_repo_fork', :plugin => 'snowball')
      end

      if context[:repository] && !context[:repository][:fork_from].nil? && ''!=context[:repository][:fork_from]
        o << "<h3 id='fork_from_label' style='color:green;'>"
        o << "Fork From: <label style='text-decoration:underline;'>#{context[:repository][:fork_from]}</label>"
        o << "</h3>"
      end

    end

    return o.html_safe
  end
end

class SnowballVoteHeaderHooks < Redmine::Hook::ViewListener
  #Ref: http://www.redmine.org/projects/redmine/wiki/Plugin_Tutorial#Improving-the-plugin-views
  def view_layouts_base_html_head(context = {})
    o = stylesheet_link_tag('snowball_project_vote', :plugin => 'snowball')
    o << javascript_include_tag('snowball_project_vote', :plugin => 'snowball')

    return o
  end
end

class SnowballVoteLayoutBaseContentHooks < Redmine::Hook::ViewListener
  #Ref: http://www.redmine.org/projects/redmine/repository/entry/tags/2.0.0/app/views/layouts/base.html.erb
  #Ref: http://www.redmine.org/projects/redmine/repository/entry/tags/2.0.0/app/views/issues/show.html.erb

  #view_issues_show_details_bottom 这里不选用，因为需要在list的页面也引用模版页面
  render_on :view_layouts_base_content, :partial => 'snowball_project_vote/view_layouts_base_content'

end







