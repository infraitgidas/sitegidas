(function ($) {
  'use strict';

  Drupal.behaviors.awesome = {
    attach: function(context, settings) {

      $('[id^=edit-submit-proyectos]', context).once('awesome').addClass('btn-danger text-white').removeClass('btn-primary');
      $('.views-exposed-form .form--inline', context).once('awesome').addClass('d-flex align-items-end');
      
    }
  };

}(jQuery));