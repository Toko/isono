# -*- coding: utf-8 -*-

module Isono
  module Models
    class ResourceInstance < Sequel::Model
      include Logger
      plugin :schema
      plugin :hook_class_methods
      plugin :serialization

      set_schema {
        primary_key :id, :type => Integer, :auto_increment=>true, :unsigned=>true
        column :agent_id, :varchar, :size=>80, :null=>false
        column :uuid,   :varchar, :size=>50, :null=>false
        column :resource_type, :varchar, :size=>50, :null=>false
        column :instance_data, :text
        column :status, :varchar, :size=>10
        
        column :created_at, :datetime, :null=>false
        column :updated_at, :datetime, :null=>false
        index [:uuid], {:unique=>true}
      }

      serialize_attributes :yaml, :instance_data
      
      before_create(:set_created_at) do
        self.updated_at = self.created_at = Time.now
      end
      before_update(:set_updated_at) do
        self.updated_at = Time.now
      end

    end
  end
end
