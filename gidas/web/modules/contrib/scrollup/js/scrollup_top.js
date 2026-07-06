/**
 * @file
 * ScrollUp javascript file.
 */

(function (Drupal, drupalSettings, once) {

  Drupal.behaviors.scrollup = {

    attach: function () {
      let linkTitle = 'Scroll to the top of the page.';
      let linkContent = '';
      if (drupalSettings.scrollup_title !== '' && drupalSettings.scrollup_title !== null) {
        linkTitle = drupalSettings.scrollup_title;
        linkContent = drupalSettings.scrollup_title;
      }

      const bodyContainer = once('scrollup', document.querySelector('body'));

      if (bodyContainer.length === 0) {
        return;
      }

      const [body] = bodyContainer;
      body.insertAdjacentHTML("beforeend", `<a href="#" title="${linkTitle}" class="scrollup">Scroll<span class="scroll-title">${linkContent}</span></a>`);

      const scrollUpButton = document.querySelector('.scrollup');
      const position = drupalSettings.scrollup_position;
      const button_bg_color = drupalSettings.scrollup_button_bg_color;
      const hover_button_bg_color = drupalSettings.scrollup_button_hover_bg_color;
      const scroll_window_position = parseInt(drupalSettings.scrollup_window_position);
      const scroll_speed = parseInt(drupalSettings.scrollup_speed);

      if (position == 1) {
        document.dir === 'ltr' ? scrollUpButton.style.right = '0px' : scrollUpButton.style.left = '0px';
      }
      else {
        scrollUpButton.style.left = '0px';
      }
      scrollUpButton.style.backgroundColor = `${button_bg_color}`;

      scrollUpButton.addEventListener("mouseover", function (event) {
        event.preventDefault();
        scrollUpButton.style.backgroundColor = `${hover_button_bg_color}`;
      });

      scrollUpButton.addEventListener("mouseleave", function (event) {
        event.preventDefault();
        scrollUpButton.style.backgroundColor = `${button_bg_color}`;
      });

      window.addEventListener('scroll', function (event) {
        event.preventDefault();
        scrollUpButton.style.display = (window.pageYOffset > scroll_window_position) ? 'block' : 'none';
      });

      scrollUpButton.addEventListener('click', function (event) {
        event.preventDefault();
        document.querySelectorAll('html, body').forEach(node => node.scrollTo({
          top: 0,
          behavior: "smooth",
          duration: scroll_speed
        }))
      });
    }
  };
})(Drupal, drupalSettings, once);
