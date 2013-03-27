########################################################################
# File::    customer.rb
# (C)::     Hipposoft 2008, 2009
#
# Purpose:: Describe the behaviour of Customer objects. See below for
#           more details.
# ----------------------------------------------------------------------
#           24-Dec-2007 (ADH): Created.
########################################################################

class Customer < TaskGroup

  acts_as_audited( :except => [
    :lock_version,
    :updated_at,
    :created_at,
    :id,
    :code,
    :description
  ] )

  # Customers are people for whom work is done. Customers are involved
  # with various projects, which in turn include various tasks.

  has_many( :projects, { :order => Project::DEFAULT_SORT_ORDER } )
  has_many( :tasks,    { :through => :projects, :uniq => true  } )
  has_many( :control_panels )

  # Unfortunately, Acts As Audited runs on this model (see above) and
  # uses attr_protected. Rails doesn't allow both, so I have to use
  # the less-secure attr_protected here too.

  attr_protected(
    :project_ids,
    :control_panel_ids
  )

  # Assign default conditions for a brand new object, used whether
  # or not the object ends up being saved in the database (so a
  # before_create filter is not sufficient). For user-specific
  # default values, pass a User object.
  #
  def assign_defaults( user )
    self.active = true
    self.code   = "CID%04d" % Customer.count

    # Presently, there are no user-specific default values for
    # Customer objects.
  end

  # Apply a default sort to the given array of customer objects. The array is
  # modified in place. Although this method is compatible with the default sort
  # mechanism in the YUI tree view component, it's not called by that because
  # the wider data set does not behave even remotely like acts_as_nested_set
  # style collections, so bespoke controller and view code is used to generate
  # arrays of objects.
  #
  def self.apply_default_sort_order( array )
    array.sort! { | x, y | x.title.downcase <=> y.title.downcase }
  end

  # Update an object with the given attributes. This is done by a
  # special model method because changes of the 'active' flag have
  # side effects for other associated objects. THE CALLER **MUST**
  # USE A TRANSACTION around a call to this method. There is no
  # need to call here unless the 'active' flag state is changing.
  # Pass in 'true' to update associated projects, else 'false' and
  # 'true' to update associated tasks via those projects, else
  # 'false'. Booleans default to 'true' if omitted.
  #
  def update_with_side_effects!( attrs, update_projects = true, update_tasks = true )
    active = self.active
    self.update_attributes!( attrs )

    # If the active flag has changed, deal with repercussions.

    if ( update_projects and attrs[ :active ] != active )
      self.projects.each do | project |
        project.update_with_side_effects!( { :active => attrs[ :active ] }, update_tasks )
      end
    end
  end

  # As update_with_side_effects!, but destroys things rather than
  # updating them. Pass 'true' to destroy associated projects, else
  # 'false'. If omitted, defaults to 'true'; pass also 'true' to
  # destroy tasks associated with those projects, else 'false',
  # with, again, the default being 'true'.
  #
  def destroy_with_side_effects( destroy_projects = true, destroy_tasks = true )
    if ( destroy_projects )
      self.projects.each do | project |
        project.destroy_with_side_effects( destroy_tasks )
      end
    end

    self.destroy()
  end
end
