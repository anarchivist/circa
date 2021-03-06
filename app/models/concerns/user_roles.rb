require 'active_support/concern'

module UserRoles

  extend ActiveSupport::Concern

  included do


    @@roles = [ :admin, :staff, :assistant, :patron ]


    def self.roles
      @@roles
    end


    def roles
      if role
        role_index = @@roles.index(role.to_sym)
        @@roles.slice(role_index, @@roles.length)
      else
        [ @@roles.last ]
      end
    end


    def assign_role(new_role)
      update_attributes(role: new_role.to_s)
    end


    def is_admin
      roles.include?(:admin)
    end


    def is_staff
      roles.include?(:staff)
    end


    def has_role?(r)
      roles.include?(r.to_sym)
    end


    def assignable_roles
      if @@roles.index(role.to_sym) == 0
        @@roles
      else
        index = @@roles.index(role.to_sym) + 1
        @@roles.slice(index, @@roles.length)
      end
    end


    def can_assign_role?(role)
      assignable_roles.include?(role.to_sym)
    end

  end

end
