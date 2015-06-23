// Adds endsWith to String prototype if it doesn't exist yet
if (typeof String.prototype.endsWith !== 'function') {
    String.prototype.endsWith = function(suffix) {
        return this.indexOf(suffix, this.length - suffix.length) !== -1;
    };
}

if (navigator.userAgent.indexOf("MSIE 10") > 0) {
    $('html').on('mousedown',".fileinput-button input",function(event) {
        $(this).trigger('click');
    });
}
