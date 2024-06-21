import './jquery-global'
import bulmaCarousel from 'bulma-carousel/dist/js/bulma-carousel'
import BulmaTagsInput from '@creativebulma/bulma-tagsinput/dist/js/bulma-tagsinput'
import EasyMDE from 'easymde/dist/easymde.min'
import Cookify from "cookify/src/index"
// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"

let Hooks = {}
Hooks.Focus = {
  mounted() {
    this.el.focus();
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, params: {_csrf_token: csrfToken}})

// connect if there are any LiveViews on the page
liveSocket.connect()

$(function($) {
    var cookify = new Cookify('cookie_consent', function () {
        $('#cookie-manage').addClass('d-none')
        $('#cookie-manage').removeClass('is-active')
    }, function (data) {
        console.log(data)
    }, false, false, 'necessary');

    (document.querySelectorAll('input[data-type="tags"], input[type="tags"], select[data-type="tags"], select[type="tags"]') || []).forEach(($taginput) => {
        var $source = $taginput.dataset['values'];
        new BulmaTagsInput($taginput, {
            source: $source ? $source.split(",") : undefined
        });
    });

    (document.querySelectorAll('.modal-background, .modal-close, .modal-card-head .delete, .modal-card-foot .button') || []).forEach(($close) => {
        const $target = $close.closest('.modal');

        $close.addEventListener('click', () => {
            $target.classList.remove('is-active')
        });
    });

    (document.querySelectorAll('.notification .delete') || []).forEach(($delete) => {
        const $notification = $delete.parentNode;

        $delete.addEventListener('click', () => {
            $notification.parentNode.removeChild($notification);
        });
    });

    (document.querySelectorAll('.easymde') || []).forEach(($editor) => {
        new EasyMDE({
            element: $editor,
            minHeight: $editor.dataset['height'] || "500px"
        });
    });

    // Get all "navbar-burger" elements
    const $navbarBurgers = Array.prototype.slice.call(document.querySelectorAll('.navbar-burger'), 0);

    // Check if there are any navbar burgers
    if ($navbarBurgers.length > 0) {
        // Add a click event on each of them
        $navbarBurgers.forEach( el => {
            el.addEventListener('click', () => {
                // Get the target from the "data-target" attribute
                const target = el.dataset.target;
                const $target = document.getElementById(target);

                // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
                el.classList.toggle('is-active');
                $target.classList.toggle('is-active');
            });
        });
    }

    if ($('#cookie-open').length > 0) {
        $('#cookie-open').on('click', function() {
            $('#cookie-manage').removeClass('d-none')
            $('#cookie-manage').addClass('is-active')
        })

        if (!cookify.getDataState(cookify.viewedName)) {
            $('#cookie-manage').removeClass('d-none')
            $('#cookie-manage').addClass('is-active')
        }
    }

    $('.tab-item').on('click', function(event) {
        event.preventDefault()
        $('.tab-item').removeClass('is-active')
        $(this).addClass('is-active')
        $('.tab-section').addClass('is-hidden')
        var name = $(this).data('id')
        $('#' + name).removeClass('is-hidden')
    })

    // options: https://bulma-carousel.onrender.com/#options
    if ($('#carousel-hero').length > 0) {
        bulmaCarousel.attach('#carousel-hero', {
            autoplay: true,
            autoplaySpeed: 5000,
            infinite: true,
            slidesToShow: 1,
            slidesToScroll: 1,
            initialSlide: 0
        });
    }
    if ($('#carousel-crossell').length > 0) {
        if ($('.carousel-items').length > 1) {
            bulmaCarousel.attach('#carousel-crossell', {
                autoplay: true,
                autoplaySpeed: 5000,
                infinite: true,
                slidesToShow: 1,
                slidesToScroll: 1,
                initialSlide: 0,
                pagination: false
            });
        }
    }
});
