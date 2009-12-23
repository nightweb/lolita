class Admin::Access < Cms::Base
  set_table_name :admin_accesses
  has_and_belongs_to_many :roles, :class_name=>"Admin::Role"
  # belongs_to :authorizable, :polymorphic => true

  def self.collect_all
    old_access_list=Admin::Access.find(:all)
    temp_access=Util::System.load_classes.collect{|table|
      Admin::Access.find_or_create_by_name(table[:name])
    }.compact
    remove_array=old_access_list-temp_access
    Admin::Access.delete(remove_array)
  end
  
  def can_all_with_role(role_name)
    if role_access=get_role_access(role_name.to_s)
      role_access.can_all
    end
  end

  def can_nothing_with_role(role_name)
    if role_access=get_role_access(role_name)
      role_access.can_nothing
    end
  end

  def can_with_role_do(role_name,permissions={})
    if role_access=get_role_access(role_name)
      role_access.can permissions
    end
  end

  def can_all? role_name
    if role_access=get_role_access(role_name)
      role_access.can_all?
    end
  end

  def can_nothing? role_name
    if role_access=get_role_access(role_name)
      role_access.can_nothing?
    end
  end

  def can? permission
    if role_access=get_role_access(role_name)
      role_access.can? permission
    end
  end

  def has_role?(role_name)
    self.roles.find_by_name(role_name) ? true : false
  end

  def has_role (role)
    if role.is_a?(Admin::Role)
      Admin::AccessesRoles.create(:role_id=>role.id,:access_id=>self.id)
    elsif role.is_a?(String) || role.is_a?(Symbol)
      role=Admin::Role.find_by_name(role.to_s) || Admin::Role.create!(:name=>role.to_s)
      Admin::AccessesRoles.create(:role_id=>role.id,:access_id=>self.id)
    end unless self.has_role?(role)
  end


  def has_no_role(role_name)
    role = get_role(role_name)
    if role
      self.roles.delete(role)
    end
  end

  def has_current_user? (user)
    access_roles=self.roles.find(:all)
    result=false
    access_roles.each do |role|
      if user.has_role? role.name
        result=true
        break;
      end
    end
    return result
  end


  private

  def get_role_access role_name
    role=get_role(role_name)
    Admin::AccessesRoles.find_by_role_and_access(role.id,self.id) if role
  end

  def get_role (role_name)
    Admin::Role.find( :first, :conditions => [ 'name = ?', role_name ] )
  end
end
