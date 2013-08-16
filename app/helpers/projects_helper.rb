########################################################################
# File::    projects_helper.rb
# (C)::     Hipposoft 2008
#
# Purpose:: Support functions for views related to Project objects. See
#           controllers/projects_controller.rb for more.
# ----------------------------------------------------------------------
#           04-Jan-2008 (ADH): Created.
########################################################################

module ProjectsHelper

  # Return a name of a given project's associated customer, for use
  # in list views.

  def projecthelp_customer( project )
    return '-'.html_safe() if ( project.customer.nil? )
    return apphelp_augmented_link( project.customer )
  end

  # Return list actions appropriate for the given project

  def projecthelp_actions( project )
    if ( @current_user.admin? or ( project.active and @current_user.manager? ) )
      actions = [ 'edit', 'delete' ]
    else
      actions = []
    end

    actions.push( 'show' )
    return actions
  end

end
