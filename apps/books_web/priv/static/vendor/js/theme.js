(function ($) {
  'use strict';

  // Counter
  $('.count').counterUp({
    delay: 10,
    time: 1000
  });

  //  Fixed header
  $(window).scroll(function () {
    var window_top = $(window).scrollTop() + 1;
    if (window_top > 50) {
      $('.site-header').addClass('menu_fixed header-white animated fadeInDown');
    } else {
      $('.site-header').removeClass('menu_fixed header-white animated fadeInDown');
    }
  });

  // Scroll to top
  $(window).on('scroll', function () {
    if ($(window).scrollTop() > 70) {
      $('.scroll-to-top').addClass('reveal');
    } else {
      $('.scroll-to-top').removeClass('reveal');
    }
  });

  $('a.smoth-scroll').on('click', function (e) {
    var anchor = $(this);
    $('html, body').stop().animate({
      scrollTop: $(anchor.attr('href')).offset().top - 100
    }, 1000);
    e.preventDefault();
  });

  $('.book-preview').each(function () {
    $(this).find('.popup-gallery').magnificPopup({
      type: 'image',
      gallery: {
        enabled: true
      }
    });
  });

  $(document).ready(function () {
    $('.popup-gallery').magnificPopup({ type: 'image' });
  });

  $('.home-slider-loop-false').owlCarousel({
    loop: true,
    autoplay: true,
    margin: 0,
    animateOut: 'fadeOut',
    animateIn: 'fadeIn',
    nav: false,
    dots: true,
    autoplayHoverPause: true,
    items: 1,
    responsive: {
      0: {
        items: 1,
        nav: false
      },
      600: {
        items: 1,
        nav: false
      },
      1000: {
        items: 1,
        nav: false
      }
    }
  });

  $('.testimonial-slider').owlCarousel({
    loop: true,
    // autoplay: true,
    autoplayTimeout: 4000,
    margin: 0,
    animateOut: 'fadeOut',
    animateIn: 'fadeIn',
    nav: true,
    navText: ["<i class='fa fa-angle-left'></i>", "<i class='fa fa-angle-right'></i>"],
    dots: false,
    center: false,
    autoplayHoverPause: true,
    items: 3,
    navContainer: '#reviewNavs',
    responsive: {
      0: {
        items: 1,
        dots: true,
        nav: false
      },
      600: {
        items: 1,
        dots: true,
        nav: false
      },
      1000: {
        items: 3,
        nav: false
      },
      1400: {
        items: 4,
      }
    }
  });

  $('.owl-book').owlCarousel({
    loop: true,
    autoplay: true,
    margin: 0,
    animateOut: 'fadeOut',
    animateIn: 'fadeIn',
    nav: false,
    dots: false,
    autoplayHoverPause: true,
    items: 1,
    responsive: {
      0: {
        items: 1,
        nav: false
      },
      600: {
        items: 1,
        nav: false
      },
      1000: {
        items: 1,
        nav: false
      }
    }
  });

  $('.testimonial-wrap').slick({
    slidesToShow: 2,
    slidesToScroll: 2,
    infinite: true,
    dots: false,
    arrows: false,
    autoplay: true,
    autoplaySpeed: 4000,
    responsive: [
      {
        breakpoint: 1024,
        settings: {
          slidesToShow: 2,
          slidesToScroll: 2,
          infinite: true,
          dots: true
        }
      },
      {
        breakpoint: 900,
        settings: {
          slidesToShow: 2,
          slidesToScroll: 2
        }
      }, {
        breakpoint: 600,
        settings: {
          slidesToShow: 1,
          slidesToScroll: 1
        }
      },
      {
        breakpoint: 480,
        settings: {
          slidesToShow: 1,
          slidesToScroll: 1
        }
      }

    ]
  });

  // Closes responsive menu when a scroll trigger link is clicked
  $('.smoth-scroll').on('click', function (event) {
    $('.navbar-collapse').collapse('hide');
  });

  function toggleIcon(e) {
    $(e.target)
      .prev('.panel-heading')
      .find(".more-less")
      .toggleClass('ti-minus');
  }
  $('.panel-group').on('hidden.bs.collapse', toggleIcon);
  $('.panel-group').on('shown.bs.collapse', toggleIcon);
})(jQuery);
