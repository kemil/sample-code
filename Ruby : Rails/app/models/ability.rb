class Ability
  include CanCan::Ability

  def initialize(user)

    if user.has_role? :basic, user.agency
      can :read, Agency, :id => user.agency.id
      can :read, Lead, :agency_id => user.agency.id
      can :manage, Deal, :prospect => {:prospectable => user}
      can :manage, Note, :user_id => user.id
      #can :manage, User, :agency_id => user.agency.id
      can :manage, User, :id => user.id
      cannot :index, User
      can :manage, Prospect, :prospectable => user
      can :manage, Contact, :contactable => {:prospect => {:prospectable => user}}
    end

    if user.has_role? :admin, user.agency
      can :manage, Agency, :id => user.agency.id
      can :manage, Deal, :prospect => {:lead => {:agency_id => user.agency.id}}
      can :manage, Contact, :contactable => {:prospect => {:lead => {:agency_id => user.agency.id}}}
      can :manage, User, :agency_id => user.agency.id
      can :manage, Note, :user => {:agency => user.agency}
      can :manage, Group, :agency_id => user.agency.id
      can :manage, Pipe, :agency_id => user.agency.id
      can :manage, Lead, :agency_id => user.agency.id
      can :manage, Prospect, :lead => {:agency_id => user.agency.id}
      #can :manage, Note, :user_id => user.agency.users.pluck(:id)
    end

    if user.has_role? :super_admin
      can :manage, :all
    end

    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #     can :manage, :id => Forum.with_role(:moderator, user).pluck(:id)
    #   end
    #
    # The first argument to `can` is the action you are giving the user 
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. 
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
