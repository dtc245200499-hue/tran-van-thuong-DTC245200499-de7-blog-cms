<?php
add_action('after_setup_theme', function () { add_theme_support('title-tag'); add_theme_support('html5', ['search-form']); });
add_action('wp_enqueue_scripts', function () { wp_enqueue_style('campus-journal', get_stylesheet_uri(), [], '1.0.0'); });
