// This adds new contributor fields to the edit form.
//
// Based loosely on https://github.com/aic-collections/aicdams-lakeshore/blob/0eda8f1407d89cb86fc7284ed6c235114407e020/app/assets/javascripts/add_annotation.js
//
// It clones the existing field, then updates the array indices This returns a new html string with the fields for the contributor.
// The hydra-editor gem takes care of the bulk of the actions such attaching the listeners to the "Add" button
// and inserting the new field into the html form.
//
// Once inserted, the resulting html form should produce a parameters hash that looks like:
//
// {
//   "contributors_attributes" => {
//     "0" => {"contributor_name"=>"Jane Doe", "_destroy"=>"0", "id"=>"37f13bdf-a664-4015-b590-4a66850a9ab6"},
//     "1" => {"contributor_name"=>"John Doe", "_destroy"=>"0", "id"=>""}
//   }
// }
//
// TODOs:
//   - select needs to pull values from the Contributor class
//   - QA needs to be involved to query existing contributors
//
//= require hydra-editor/hydra-editor

function ContributorsFieldManager(element, options) {
  HydraEditor.FieldManager.call(this, element, options); // call super constructor.
}

ContributorsFieldManager.prototype = Object.create(HydraEditor.FieldManager.prototype,
  {
    createNewField: { value: function($activeField) {
      var fieldName = $activeField.find('input').data('attribute');
      $newField = this.newFieldClone($activeField);
      this.addBehaviorsToInput($newField)
      return $newField
    }},

    /* This gives the index for the editor */
    maxIndex: { value: function() {
      return $(this.fieldWrapperClass, this.element).size();
    }},

    // Overridden because the input is not a direct child of activeField
    inputIsEmpty: { value: function(activeField) {
      return activeField.find('input.multi-text-field').val() === '';
    }},

    // Replaces newFieldTemplate.  Creates new elements by copying existing ones
    newFieldClone: { value: function(activeField) {
      var index = this.maxIndex();
      var newField = activeField.clone();
      var newChildren = newField.find('input, select');
      newChildren.removeProp('required');
      // Update numeric IDs in fieldnames to next index number
      newChildren.each(function(i, element) {
        name = $(element).attr('name');
        newname = name.replace(/\[[0-9]+\]/,"["+index+"]");
        $(element).attr('name',newname);
        $(element).attr('id',newname);
      });
      // Unselect any previously-selected options
      var newOptions = newField.find('option:selected');
      newOptions.removeAttr('selected');
      // Remove content from text attributes (not from all inputs, otherwise hidden ones and checkbox values are cleared too)
      var newFields = newField.find(':text');
      newFields.val('');
      // Update 'order' field if present
      var newOrderField = newField.find("input[name*='[order]']");
      newOrderField.val(index);

      newChildren.first().focus();
      this.element.trigger("managed_field:add", newChildren.first());
      return newField;
    }},

    addBehaviorsToInput: { value: function($newField) {
      $newInput = $('input.multi-text-field', $newField);
      $newInput.focus();
      // TODO: Hook-up QA to this
      //addAutocompleteToEditor($newInput);
      this.element.trigger("managed_field:add", $newInput);
    }},

    // Instead of removing the line, we override this method to add a
    // '_destroy' hidden parameter
    removeFromList: { value: function( event ) {
      event.preventDefault();
      var field = $(event.target).parents(this.fieldWrapperClass);
      field.find('[data-destroy]').val('1')
      // if this is a new contributor without an id, wipe the name and affiliation
      // fields as well since _destroy parameter won't work on new entries
      if(field.find("[name*='[id]']").length == 0){
        field.find("[name*='[contributor_name]']").val('');
        field.find("[name*='[affiliation]']").val('');
      }
      field.hide();
      this.element.trigger("managed_field:remove", field);
    }}
  }
);
ContributorsFieldManager.prototype.constructor = ContributorsFieldManager;

$.fn.manage_comment_fields = function(option) {
  return this.each(function() {
    var $this = $(this);
    var data  = $this.data('manage_fields');
    var options = $.extend({}, HydraEditor.FieldManager.DEFAULTS, $this.data(), typeof option == 'object' && option);

    if (!data) $this.data('manage_fields', (data = new ContributorsFieldManager(this, options)));
  })
}

Blacklight.onLoad(function() {
  $('.generic_file_contributors.form-group , .collection_contributors.form-group').manage_comment_fields();
});
