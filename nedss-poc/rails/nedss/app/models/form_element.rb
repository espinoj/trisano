class FormElement < ActiveRecord::Base
  acts_as_nested_set :scope => :tree_id
  belongs_to :form
  
  def destroy_with_dependencies
    transaction do
      if (self.class.name == "QuestionElement")
        self.question.destroy
      end
      self.destroy
    end
  end
  
  def children_count_by_type(type_name)
    FormElement.calculate(:count, :type, :conditions => ["type = ? and tree_id = ?", type_name, self.tree_id])
  end
  
  def children_by_type(type_name)
    FormElement.find(:all, :conditions => ["type = ? and parent_id = ?", type_name, self.id], :order => :lft)
  end
  
  # DEBT! Should make publish and add_to_library the same code
  def add_to_library
    transaction do
      tree_id = FormElement.find_by_sql("SELECT nextval('tree_id_generator')").first.nextval.to_i
      copy_children(self, nil, nil, tree_id, true)
    end
  end

  def copy_from_library(lib_element_id)
    transaction do
      library_element = FormElement.find(lib_element_id)
      self.add_child(copy_children(library_element, nil, self.form_id, self.tree_id, false))
    end
  end

  # Returns root node of the copied tree
  def copy_children(node_to_copy, parent, form_id, tree_id, is_template)
      e = node_to_copy.class.new
      e.form_id = form_id
      e.tree_id = tree_id
      e.is_template = is_template
      e.name = node_to_copy.name
      e.description = node_to_copy.description
      e.question = node_to_copy.question.clone if node_to_copy.is_a? QuestionElement
      e.save!
      parent.add_child e unless parent.nil?
      node_to_copy.children.each do |child|
        copy_children(child, e, tree_id)
      end
      e
  end
  
end
