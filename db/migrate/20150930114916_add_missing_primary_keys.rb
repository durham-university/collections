class AddMissingPrimaryKeys < ActiveRecord::Migration
  def up
    add_column(:domain_terms_local_authorities, :id, :primary_key) unless column_exists?(:domain_terms_local_authorities, :id)
    add_column(:roles_users, :id, :primary_key) unless column_exists?(:roles_users, :id)
    add_column(:schema_migrations, :id, :primary_key) unless column_exists?(:schema_migrations, :id)
  end
  def down
    remove_column(:domain_terms_local_authorities, :id)
    remove_column(:roles_users, :id)
    remove_column(:schema_migrations, :id)
  end
end
