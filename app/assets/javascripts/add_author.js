// This adds new author fields to the edit form.
//
// Based loosely on https://github.com/aic-collections/aicdams-lakeshore/blob/0eda8f1407d89cb86fc7284ed6c235114407e020/app/assets/javascripts/add_annotation.js
//
// It clones the existing field, then updates the array indices This returns a new html string with the fields for the author.
// The hydra-editor gem takes care of the bulk of the actions such attaching the listeners to the "Add" button
// and inserting the new field into the html form.
//
// Once inserted, the resulting html form should produce a parameters hash that looks like:
//
// {
//   "authors_attributes" => {
//     "0" => {"author_name"=>"Jane Doe", "_destroy"=>"0", "id"=>"37f13bdf-a664-4015-b590-4a66850a9ab6"},
//     "1" => {"author_name"=>"John Doe", "_destroy"=>"0", "id"=>""}
//   }
// }
//
// TODOs:
//   - select needs to pull values from the Author class
//   - QA needs to be involved to query existing authors
//
//= require hydra-editor/hydra-editor

function AuthorsFieldManager(element, options) {
  HydraEditor.FieldManager.call(this, element, options); // call super constructor.
}

AuthorsFieldManager.prototype = Object.create(HydraEditor.FieldManager.prototype,
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
      newChildren = newField.find('input, select');
      newChildren.val('').removeProp('required');
      newChildren.each(function(i, element) {
        console.log($(element).attr('name'));
        name = $(element).attr('name');
        newname = name.replace(/\[[0-9]+\]/,"["+index+"]");
        $(element).attr('name',newname);
        console.log($(element).attr('name'));
      });
      newOptions = newField.find('option:selected');
      newOptions.removeAttr('selected');
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
      field.hide();
      this.element.trigger("managed_field:remove", field);
    }}
  }
);
AuthorsFieldManager.prototype.constructor = AuthorsFieldManager;

$.fn.manage_comment_fields = function(option) {
  return this.each(function() {
    var $this = $(this);
    var data  = $this.data('manage_fields');
    var options = $.extend({}, HydraEditor.FieldManager.DEFAULTS, $this.data(), typeof option == 'object' && option);

    if (!data) $this.data('manage_fields', (data = new AuthorsFieldManager(this, options)));
  })
}

Blacklight.onLoad(function() {
  $('.generic_file_authors.form-group').manage_comment_fields();
});
